import 'dart:math' as math;

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
  final VoidCallback onOpenInTerminal;

  const ProjectItem({
    super.key,
    required this.project,
    required this.installedTools,
    required this.defaultToolId,
    required this.onTap,
    required this.onStarToggle,
    required this.onShowInFinder,
    required this.onOpenWith,
    required this.onOpenInTerminal,
    required this.onDelete,
    this.isFocused = false,
    this.isHovering = false,
  });
  @override
  Widget build(BuildContext context) {
    final isDisabled = !project.pathExists;
    final interactionActive = !isDisabled && (isFocused || isHovering);
    final isHighlighted = !isDisabled && (isFocused || isHovering);
    final borderRadius = BorderRadius.circular(14);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: isDisabled
            ? null
            : (details) => _showContextMenu(context, details),
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
    final displayPath = StringUtils.replaceHomeWithTilde(project.path);

    return Row(
      children: [
        _buildPathAppIcon(mutedText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            StringUtils.ellipsisStart(displayPath, maxLength: 55),
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

    return _ProjectActionsMenu(
      installedTools: installedTools,
      onShowInFinder: onShowInFinder,
      onOpenInTerminal: onOpenInTerminal,
      onOpenWith: onOpenWith,
      onDelete: onDelete,
    );
  }

  Future<void> _showContextMenu(
    BuildContext context,
    TapDownDetails details,
  ) async {
    final menuBuilder = _ProjectMenuBuilder(
      installedTools: installedTools,
      onShowInFinder: onShowInFinder,
      onOpenInTerminal: onOpenInTerminal,
      onOpenWith: onOpenWith,
      onDelete: onDelete,
    );

    final action = await showMenu<_MenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: menuBuilder.buildMenuEntries(context),
      shape: menuBuilder.menuShape(context),
      color: menuBuilder.menuColor(Theme.of(context)),
      elevation: 12,
    );

    action?.onSelected();
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

class _ProjectActionsMenu extends StatefulWidget {
  final List<Tool> installedTools;
  final VoidCallback onShowInFinder;
  final VoidCallback onOpenInTerminal;
  final void Function(OpenWithApp app) onOpenWith;
  final VoidCallback onDelete;

  const _ProjectActionsMenu({
    Key? key,
    required this.installedTools,
    required this.onShowInFinder,
    required this.onOpenInTerminal,
    required this.onOpenWith,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<_ProjectActionsMenu> createState() => _ProjectActionsMenuState();
}

class _ProjectActionsMenuState extends State<_ProjectActionsMenu> {
  bool _isHovered = false;
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;
    final accentColor = ThemeProvider.instance.accentColor;
    final menuBuilder = _ProjectMenuBuilder(
      installedTools: widget.installedTools,
      onShowInFinder: widget.onShowInFinder,
      onOpenInTerminal: widget.onOpenInTerminal,
      onOpenWith: widget.onOpenWith,
      onDelete: widget.onDelete,
    );

    return Semantics(
      label: 'Project options menu',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: PopupMenuButton<_MenuAction>(
          tooltip: 'Project options',
          onOpened: () => setState(() => _isMenuOpen = true),
          onCanceled: () => setState(() => _isMenuOpen = false),
          onSelected: (action) {
            setState(() => _isMenuOpen = false);
            action.onSelected();
          },
          elevation: 12,
          offset: const Offset(-6, 10),
          shape: menuBuilder.menuShape(context),
          color: menuBuilder.menuColor(Theme.of(context)),
          itemBuilder: (context) => menuBuilder.buildMenuEntries(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (_isHovered || _isMenuOpen)
                  ? accentColor.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.more_horiz,
              size: 18,
              color: (_isHovered || _isMenuOpen) ? accentColor : iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectMenuBuilder {
  const _ProjectMenuBuilder({
    required this.installedTools,
    required this.onShowInFinder,
    required this.onOpenInTerminal,
    required this.onOpenWith,
    required this.onDelete,
  });

  final List<Tool> installedTools;
  final VoidCallback onShowInFinder;
  final VoidCallback onOpenInTerminal;
  final void Function(OpenWithApp app) onOpenWith;
  final VoidCallback onDelete;

  static const double _actionTileExtent = 52.0;
  static const double _menuWidth = 260.0;

  List<PopupMenuEntry<_MenuAction>> buildMenuEntries(BuildContext context) {
    final toolActions = _toolActions();

    return <PopupMenuEntry<_MenuAction>>[
      ..._buildOpenWithSection(context, toolActions),
      const PopupMenuDivider(height: 8),
      _buildActionItem(
        _MenuAction(
          label: 'Reveal in Finder',
          icon: Icons.folder_open,
          onSelected: onShowInFinder,
          semanticsLabel: 'Reveal project in Finder',
        ),
      ),
      _buildActionItem(
        _MenuAction(
          label: 'Open in Terminal',
          icon: Icons.terminal,
          onSelected: onOpenInTerminal,
          semanticsLabel: 'Open project in terminal',
        ),
      ),
      const PopupMenuDivider(height: 8),
      _buildActionItem(
        _MenuAction(
          label: 'Hide project',
          icon: Icons.delete_outline,
          onSelected: onDelete,
          isDestructive: true,
        ),
      ),
    ];
  }

  PopupMenuEntry<_MenuAction> _buildHeader(BuildContext context, String label) {
    final theme = Theme.of(context);
    final baseHeaderStyle =
        theme.textTheme.labelSmall ?? theme.textTheme.bodySmall;
    final headerStyle = baseHeaderStyle?.copyWith(
      color:
          (theme.textTheme.bodySmall?.color ??
                  theme.textTheme.bodyMedium?.color ??
                  Colors.white)
              .withOpacity(0.7),
      letterSpacing: 0.8,
      fontWeight: FontWeight.w700,
    );

    return PopupMenuItem<_MenuAction>(
      enabled: false,
      height: 32,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(label.toUpperCase(), style: headerStyle),
    );
  }

  PopupMenuItem<_MenuAction> _buildActionItem(
    _MenuAction action, {
    bool isMuted = false,
  }) {
    return PopupMenuItem<_MenuAction>(
      value: action,
      enabled: action.enabled,
      padding: EdgeInsets.zero,
      child: _MenuActionTile(action: action, isMuted: isMuted),
    );
  }

  List<PopupMenuEntry<_MenuAction>> _buildOpenWithSection(
    BuildContext context,
    List<_MenuAction> toolActions,
  ) {
    if (toolActions.isEmpty) {
      return [
        _buildHeader(context, 'Open with'),
        _buildActionItem(
          const _MenuAction(
            label: 'No supported tools installed',
            icon: Icons.block,
            onSelected: _noop,
            enabled: false,
          ),
          isMuted: true,
        ),
      ];
    }

    final sectionHeight = _openWithSectionHeight(context, toolActions.length);

    return [
      _buildHeader(context, 'Open with'),
      PopupMenuItem<_MenuAction>(
        enabled: false,
        padding: EdgeInsets.zero,
        height: sectionHeight,
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(
            width: _menuWidth,
            height: sectionHeight,
          ),
          child: Scrollbar(
            radius: const Radius.circular(6),
            thickness: 4,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: toolActions.length,
              itemBuilder: (context, index) {
                final action = toolActions[index];
                return _MenuActionTile(
                  action: action,
                  onPressed: () => Navigator.of(context).pop(action),
                );
              },
            ),
          ),
        ),
      ),
    ];
  }

  List<_MenuAction> _toolActions() {
    return installedTools
        .map((tool) {
          final appTarget = _mapToOpenWithApp(tool.id);
          if (appTarget == null) return null;

          return _MenuAction(
            label: '${tool.name}',
            icon: Icons.launch,
            leading: ToolIcon(tool: tool, size: 18, borderRadius: 4),
            onSelected: () => onOpenWith(appTarget),
            semanticsLabel: 'Open project with ${tool.name}',
          );
        })
        .whereType<_MenuAction>()
        .toList(growable: false);
  }

  double _openWithSectionHeight(BuildContext context, int toolCount) {
    if (toolCount <= 0) return _actionTileExtent;

    final baseHeight = toolCount * _actionTileExtent;
    final maxHeight = math.max(
      _actionTileExtent * 5,
      MediaQuery.of(context).size.height * 0.45,
    );
    return math.min(baseHeight, maxHeight);
  }

  Color menuColor(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return Colors.grey.shade900.withOpacity(0.95);
    }
    return theme.cardColor;
  }

  ShapeBorder menuShape(BuildContext context) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
    );
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
    }
    return null;
  }
}

class _MenuAction {
  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool enabled;
  final bool isDestructive;
  final String semanticsLabel;
  final Widget? leading;

  const _MenuAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.enabled = true,
    this.isDestructive = false,
    String? semanticsLabel,
    this.leading,
  }) : semanticsLabel = semanticsLabel ?? label;
}

class _MenuActionTile extends StatefulWidget {
  final _MenuAction action;
  final bool isMuted;
  final VoidCallback? onPressed;

  const _MenuActionTile({
    required this.action,
    this.isMuted = false,
    this.onPressed,
  });

  @override
  State<_MenuActionTile> createState() => _MenuActionTileState();
}

class _MenuActionTileState extends State<_MenuActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ThemeProvider.instance.accentColor;
    final baseColor = widget.action.isDestructive
        ? Colors.redAccent
        : theme.textTheme.bodyMedium?.color ??
              theme.textTheme.bodyLarge?.color ??
              Colors.white;
    final textColor = widget.isMuted
        ? baseColor.withOpacity(0.6)
        : widget.action.enabled
        ? baseColor
        : baseColor.withOpacity(0.5);

    return Semantics(
      label: widget.action.semanticsLabel,
      enabled: widget.action.enabled,
      button: true,
      child: MouseRegion(
        cursor: widget.action.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: (widget.onPressed != null && widget.action.enabled)
              ? widget.onPressed
              : null,
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.action.enabled && _hovered
                  ? accent.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                if (widget.action.leading != null) ...[
                  widget.action.leading!,
                ] else ...[
                  Icon(widget.action.icon, size: 18, color: textColor),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.action.label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _noop() {}
