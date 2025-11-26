import 'package:flutter/material.dart';
import '../../domain/models/project.dart';
import '../../domain/models/tool.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/string_utils.dart';
import 'listing_item_container.dart';
import 'tool_icon.dart';

enum OpenWithApp {
  vscode,
  intellij,
  webstorm,
  phpstorm,
  pycharm,
  clion,
  goland,
  datagrip,
  rider,
  rubymine,
  appcode,
  fleet,
  preview,
}

class ProjectItem extends StatelessWidget {
  final Project project;
  final List<Tool> installedTools;
  final ToolId? defaultToolId;
  final VoidCallback onTap;
  final VoidCallback onStarToggle;
  final VoidCallback onShowInFinder;
  final void Function(OpenWithApp app) onOpenWith;
  final VoidCallback onDelete;
  final bool isFocused;
  final bool isHovering;

  const ProjectItem({
    super.key,
    required this.project,
    required this.installedTools,
    required this.defaultToolId,
    required this.onTap,
    required this.onStarToggle,
    required this.onShowInFinder,
    required this.onOpenWith,
    required this.onDelete,
    this.isFocused = false,
    this.isHovering = false,
  });
  @override
  Widget build(BuildContext context) {
    final isDisabled = !project.pathExists;
    final interactionActive = !isDisabled && isFocused;
    final isHighlighted = !isDisabled && (isFocused || isHovering);
    final borderRadius = BorderRadius.circular(14);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: borderRadius,
          child: ListingItemContainer(
            isActive: interactionActive,
            isDisabled: isDisabled,
            isHovering: isHovering && !interactionActive,
            borderRadius: borderRadius,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(context, isDisabled),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoHeader(context, isDisabled),
                      const SizedBox(height: 6),
                      _buildMetaRow(context, isDisabled),
                      const SizedBox(height: 6),
                      _buildPathRow(context, isDisabled),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStarButton(context, isHighlighted),
                _buildActions(context, isDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isDisabled) {
    final accentColor = ThemeProvider.instance.accentColor;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? LinearGradient(
                colors: [Colors.grey.shade800, Colors.grey.shade700],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_lighten(accentColor, 0.2), accentColor],
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(
              color: accentColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Center(
        child: Text(
          project.name.substring(0, 2).toUpperCase(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoHeader(BuildContext context, bool isDisabled) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge!.color!;
    final mutedText = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.45)
        : Colors.black45;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            project.name,
            style: TextStyle(
              color: isDisabled ? mutedText : textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        if (isDisabled) _buildNotFoundBadge(),
      ],
    );
  }

  Widget _buildMetaRow(BuildContext context, bool isDisabled) {
    final accentColor = ThemeProvider.instance.accentColor;
    final mutedText = Theme.of(context).textTheme.bodyMedium!.color!;
    final tool = _resolvePreferredTool();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // _buildTag(
        //   label: project.type.displayName,
        //   color: accentColor.withOpacity(isDisabled ? 0.15 : 0.2),
        //   textColor: Colors.white,
        // ),
        // if (tool != null)
        //   _buildTag(
        //     label: tool.name,
        //     color: Theme.of(context).brightness == Brightness.dark
        //         ? Colors.white.withOpacity(0.08)
        //         : Colors.black.withOpacity(0.04),
        //     textColor: isDisabled ? mutedText.withOpacity(0.7) : mutedText,
        //     leading: ToolIcon(tool: tool, size: 16, borderRadius: 4),
        //   ),
      ],
    );
  }

  Widget _buildPathRow(BuildContext context, bool isDisabled) {
    final mutedText = Theme.of(context).textTheme.bodyMedium!.color!;

    return Row(
      children: [
        _buildPathAppIcon(mutedText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            StringUtils.ellipsisStart(project.path, maxLength: 55),
            style: TextStyle(
              color: isDisabled ? mutedText.withOpacity(0.6) : mutedText,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNotFoundBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Not Found',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Tool? _resolvePreferredTool() {
    Tool? tool;

    if (project.lastUsedToolId != null) {
      try {
        tool = installedTools.firstWhere((t) => t.id == project.lastUsedToolId);
      } catch (_) {}
    }

    if (tool == null && defaultToolId != null) {
      try {
        tool = installedTools.firstWhere((t) => t.id == defaultToolId);
      } catch (_) {}
    }

    tool ??= installedTools.isNotEmpty ? installedTools.first : null;

    return tool;
  }

  Widget _buildPathAppIcon(Color mutedText) {
    final tool = _resolvePreferredTool();
    if (tool == null) {
      return Icon(Icons.insert_drive_file_outlined, size: 12, color: mutedText);
    }

    return Tooltip(
      message: 'Last opened with ${tool.name}',
      child: ToolIcon(tool: tool, size: 16, borderRadius: 4),
    );
  }

  Widget _buildStarButton(BuildContext context, bool isHighlighted) {
    if (!isHighlighted) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: Icon(
        project.isStarred ? Icons.star : Icons.star_border,
        color: project.isStarred
            ? Colors.amber
            : Theme.of(context).iconTheme.color,
        size: 18,
      ),
      onPressed: onStarToggle,
    );
  }

  Widget _buildActions(BuildContext context, bool isDisabled) {
    if (isDisabled) {
      return IconButton(
        icon: const Icon(Icons.close, color: Colors.red, size: 18),
        onPressed: onDelete,
        tooltip: 'Remove',
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.black.withOpacity(0.7)
        : colorScheme.surface;
    final borderColor = colorScheme.onSurface.withOpacity(isDark ? 0.08 : 0.06);
    final textColor = theme.textTheme.bodyLarge!.color!;
    final openWithItems = _buildOpenWithItems(textColor);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).iconTheme.color,
        size: 18,
      ),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'show_finder',
          child: Row(
            children: [
              const Icon(Icons.folder_open, size: 18),
              const SizedBox(width: 8),
              Text('Show in Finder', style: TextStyle(color: textColor)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Hide from the toolbox (delete)',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Section header: Open with
        const PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'Open with',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        ...openWithItems,
      ],
      onSelected: _handleMenuSelection,
    );
  }

  List<PopupMenuEntry<String>> _buildOpenWithItems(Color textColor) {
    if (installedTools.isEmpty) {
      return [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'No installed tools found',
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
          ),
        ),
      ];
    }

    return installedTools
        .map((tool) {
          return PopupMenuItem<String>(
            value: 'open_${tool.id.name}',
            child: Row(
              children: [
                ToolIcon(tool: tool, size: 22, borderRadius: 6),
                const SizedBox(width: 8),
                Text(tool.name, style: TextStyle(color: textColor)),
              ],
            ),
          );
        })
        .toList(growable: false);
  }

  Widget _buildTag({
    required String label,
    required Color color,
    required Color textColor,
    Widget? leading,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    if (value == 'show_finder') {
      onShowInFinder();
      return;
    }

    if (value == 'delete') {
      onDelete();
      return;
    }

    final toolId = _toolIdFromValue(value);
    if (toolId == null) return;

    final app = _mapToOpenWithApp(toolId);
    if (app != null) {
      onOpenWith(app);
    }
  }

  ToolId? _toolIdFromValue(String value) {
    const prefix = 'open_';
    if (!value.startsWith(prefix)) return null;

    final idName = value.substring(prefix.length);
    try {
      return ToolId.values.firstWhere((id) => id.name == idName);
    } catch (_) {
      return null;
    }
  }

  OpenWithApp? _mapToOpenWithApp(ToolId id) {
    switch (id) {
      case ToolId.vscode:
        return OpenWithApp.vscode;
      case ToolId.intellij:
        return OpenWithApp.intellij;
      case ToolId.webstorm:
        return OpenWithApp.webstorm;
      case ToolId.phpstorm:
        return OpenWithApp.phpstorm;
      case ToolId.pycharm:
        return OpenWithApp.pycharm;
      case ToolId.clion:
        return OpenWithApp.clion;
      case ToolId.goland:
        return OpenWithApp.goland;
      case ToolId.datagrip:
        return OpenWithApp.datagrip;
      case ToolId.rider:
        return OpenWithApp.rider;
      case ToolId.rubymine:
        return OpenWithApp.rubymine;
      case ToolId.appcode:
        return OpenWithApp.appcode;
      case ToolId.fleet:
        return OpenWithApp.fleet;
      case ToolId.preview:
        return OpenWithApp.preview;
    }
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
