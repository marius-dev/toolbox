import 'package:flutter/material.dart';
import '../../domain/models/project.dart';
import '../../domain/models/tool.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/string_utils.dart';
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

  const ProjectItem({
    Key? key,
    required this.project,
    required this.installedTools,
    required this.defaultToolId,
    required this.onTap,
    required this.onStarToggle,
    required this.onShowInFinder,
    required this.onOpenWith,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = !project.pathExists;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? Colors.black.withOpacity(0.2)
        : Colors.white.withOpacity(0.9);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: panelColor.withOpacity(isDisabled ? 0.7 : 1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
            children: [
              _buildAvatar(context, isDisabled),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo(context, isDisabled)),
              const SizedBox(width: 8),
              _buildStarButton(context),
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? LinearGradient(
                colors: [Colors.grey.shade800, Colors.grey.shade700],
              )
            : LinearGradient(colors: [_lighten(accentColor, 0.1), accentColor]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          project.name.substring(0, 2).toUpperCase(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, bool isDisabled) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge!.color!;
    final mutedText = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.4)
        : Colors.black45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                style: TextStyle(
                  color: isDisabled ? mutedText : textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (isDisabled) _buildNotFoundBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildPathAppIcon(mutedText),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                StringUtils.ellipsisStart(project.path, maxLength: 45),
                style: TextStyle(color: mutedText, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
      child: ToolIcon(
        tool: tool,
        size: 16,
        borderRadius: 4,
      ),
    );
  }

  Widget _buildStarButton(BuildContext context) {
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2A1F3D) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
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
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ),
      ];
    }

    return installedTools.map((tool) {
      return PopupMenuItem<String>(
        value: 'open_${tool.id.name}',
        child: Row(
          children: [
            ToolIcon(
              tool: tool,
              size: 22,
              borderRadius: 6,
            ),
            const SizedBox(width: 8),
            Text(tool.name, style: TextStyle(color: textColor)),
          ],
        ),
      );
    }).toList(growable: false);
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
