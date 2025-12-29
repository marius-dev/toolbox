import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../domain/models/project.dart';
import '../../domain/models/tool.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/string_utils.dart';
import '../../core/utils/compact_layout.dart';
import 'listing_item_container.dart';
import 'tool_icon.dart';

class ProjectItem extends StatefulWidget {
  final Project project;
  final List<Tool> installedTools;
  final ToolId? defaultToolId;
  final VoidCallback onTap;
  final VoidCallback onStarToggle;
  final VoidCallback onShowInFinder;
  final void Function(ToolId toolId) onOpenWith;
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
  State<ProjectItem> createState() => _ProjectItemState();
}

class _ProjectItemState extends State<ProjectItem> {
  late final _ProjectMenuController _menuController;

  Project get project => widget.project;
  List<Tool> get installedTools => widget.installedTools;
  ToolId? get defaultToolId => widget.defaultToolId;

  @override
  void initState() {
    super.initState();
    _menuController = _ProjectMenuController();
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !project.pathExists;
    final interactionActive = !isDisabled && (widget.isFocused || widget.isHovering);
    final isHighlighted = !isDisabled && (widget.isFocused || widget.isHovering);
    final borderRadius = BorderRadius.circular(14);

    return Container(
      margin: CompactLayout.only(context, bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: isDisabled ? null : _openContextMenu,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDisabled ? null : widget.onTap,
            borderRadius: borderRadius,
            child: ListingItemContainer(
              isActive: interactionActive,
              isDisabled: isDisabled,
              isHovering: widget.isHovering && !interactionActive,
              borderRadius: borderRadius,
              padding: EdgeInsets.symmetric(
                horizontal: CompactLayout.value(context, 8),
                vertical: CompactLayout.value(context, 6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ProjectAvatar(project: project, isDisabled: isDisabled),
                  SizedBox(width: CompactLayout.value(context, 10)),
                  Expanded(
                    child: _ProjectInfo(
                      project: project,
                      isDisabled: isDisabled,
                      preferredTool: _resolvePreferredTool(),
                    ),
                  ),
                  SizedBox(width: CompactLayout.value(context, 6)),
                  if (isHighlighted)
                    _StarButton(
                      isStarred: project.isStarred,
                      onPressed: widget.onStarToggle,
                    ),
                  _ProjectActions(
                    isDisabled: isDisabled,
                    installedTools: installedTools,
                    onShowInFinder: widget.onShowInFinder,
                    onOpenInTerminal: widget.onOpenInTerminal,
                    onOpenWith: widget.onOpenWith,
                    onDelete: widget.onDelete,
                    menuController: _menuController,
                  ),
                ],
              ),
            ),
          ),
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

  void _openContextMenu(TapDownDetails details) {
    final position = details.globalPosition;
    final anchorRect = Rect.fromLTWH(position.dx, position.dy, 0, 0);

    _menuController.showMenu(
      context: context,
      anchorRect: anchorRect,
      installedTools: installedTools,
      onShowInFinder: widget.onShowInFinder,
      onOpenInTerminal: widget.onOpenInTerminal,
      onOpenWith: widget.onOpenWith,
      onDelete: widget.onDelete,
    );
  }
}

// ==================== Sub-components ====================

class _ProjectAvatar extends StatelessWidget {
  final Project project;
  final bool isDisabled;

  const _ProjectAvatar({required this.project, required this.isDisabled});

  @override
  Widget build(BuildContext context) {
    final accentColor = ThemeProvider.instance.accentColor;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final avatarSize = CompactLayout.value(context, 38);

    return Container(
      width: avatarSize,
      height: avatarSize,
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
        borderRadius: BorderRadius.circular(CompactLayout.value(context, 10)),
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
            fontSize: CompactLayout.value(context, 13),
          ),
        ),
      ),
    );
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

class _ProjectInfo extends StatelessWidget {
  final Project project;
  final bool isDisabled;
  final Tool? preferredTool;

  const _ProjectInfo({
    required this.project,
    required this.isDisabled,
    required this.preferredTool,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoHeader(context),
        SizedBox(height: CompactLayout.value(context, 4)),
        _buildMetaRow(context),
        SizedBox(height: CompactLayout.value(context, 4)),
        _buildPathRow(context),
      ],
    );
  }

  Widget _buildInfoHeader(BuildContext context) {
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
              fontWeight: FontWeight.w500,
              fontSize: CompactLayout.value(context, 13),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isDisabled) _NotFoundBadge(),
      ],
    );
  }

  Widget _buildMetaRow(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildPathRow(BuildContext context) {
    final mutedText = Theme.of(context).textTheme.bodyMedium!.color!;
    final displayPath = StringUtils.replaceHomeWithTilde(project.path);

    return Row(
      children: [
        _buildPathAppIcon(mutedText),
        SizedBox(width: CompactLayout.value(context, 4)),
        Expanded(
          child: Text(
            StringUtils.ellipsisStart(displayPath, maxLength: 55),
            style: TextStyle(
              color: isDisabled ? mutedText.withOpacity(0.6) : mutedText,
              fontSize: CompactLayout.value(context, 11),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPathAppIcon(Color mutedText) {
    if (preferredTool == null) {
      return Icon(Icons.insert_drive_file_outlined, size: 12, color: mutedText);
    }

    return Tooltip(
      message: 'Last opened with ${preferredTool!.name}',
      child: ToolIcon(tool: preferredTool!, size: 16, borderRadius: 4),
    );
  }
}

class _NotFoundBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: CompactLayout.value(context, 6),
        vertical: CompactLayout.value(context, 2),
      ),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(CompactLayout.value(context, 4)),
      ),
      child: Text(
        'Not Found',
        style: TextStyle(
          color: Colors.red,
          fontSize: CompactLayout.value(context, 10),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StarButton extends StatelessWidget {
  final bool isStarred;
  final VoidCallback onPressed;

  const _StarButton({required this.isStarred, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isStarred ? Icons.star : Icons.star_border,
        color: isStarred ? Colors.amber : Theme.of(context).iconTheme.color,
        size: CompactLayout.value(context, 16),
      ),
      onPressed: onPressed,
      padding: EdgeInsets.all(CompactLayout.value(context, 8)),
      constraints: const BoxConstraints(),
    );
  }
}

class _ProjectActions extends StatelessWidget {
  final bool isDisabled;
  final List<Tool> installedTools;
  final VoidCallback onShowInFinder;
  final VoidCallback onOpenInTerminal;
  final void Function(ToolId toolId) onOpenWith;
  final VoidCallback onDelete;
  final _ProjectMenuController menuController;

  const _ProjectActions({
    required this.isDisabled,
    required this.installedTools,
    required this.onShowInFinder,
    required this.onOpenInTerminal,
    required this.onOpenWith,
    required this.onDelete,
    required this.menuController,
  });

  @override
  Widget build(BuildContext context) {
    if (isDisabled) {
      return IconButton(
        icon: const Icon(Icons.close, color: Colors.red, size: 18),
        onPressed: onDelete,
        tooltip: 'Remove',
        padding: EdgeInsets.all(CompactLayout.value(context, 8)),
        constraints: const BoxConstraints(),
      );
    }

    return _ProjectActionsMenu(
      installedTools: installedTools,
      onShowInFinder: onShowInFinder,
      onOpenInTerminal: onOpenInTerminal,
      onOpenWith: onOpenWith,
      onDelete: onDelete,
      menuController: menuController,
    );
  }
}

// ==================== Actions Menu ====================

class _ProjectActionsMenu extends StatefulWidget {
  final List<Tool> installedTools;
  final VoidCallback onShowInFinder;
  final VoidCallback onOpenInTerminal;
  final void Function(ToolId toolId) onOpenWith;
  final VoidCallback onDelete;
  final _ProjectMenuController menuController;

  const _ProjectActionsMenu({
    required this.installedTools,
    required this.onShowInFinder,
    required this.onOpenInTerminal,
    required this.onOpenWith,
    required this.onDelete,
    required this.menuController,
  });

  @override
  State<_ProjectActionsMenu> createState() => _ProjectActionsMenuState();
}

class _ProjectActionsMenuState extends State<_ProjectActionsMenu> {
  bool _isHovered = false;
  final GlobalKey _menuButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;
    final accentColor = ThemeProvider.instance.accentColor;

    return Semantics(
      label: 'Project options menu',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openMenu,
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.menuController.isMenuOpen,
            builder: (context, isMenuOpen, _) {
              final isActive = _isHovered || isMenuOpen;

              return Tooltip(
                message: 'Project options',
                child: Container(
                  key: _menuButtonKey,
                  padding: EdgeInsets.all(CompactLayout.value(context, 8)),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accentColor.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      CompactLayout.value(context, 10),
                    ),
                  ),
                  child: Icon(
                    Icons.more_horiz,
                    size: CompactLayout.value(context, 16),
                    color: isActive ? accentColor : iconColor,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openMenu() {
    final buttonContext = _menuButtonKey.currentContext;
    if (buttonContext == null) return;

    final renderBox = buttonContext.findRenderObject();
    if (renderBox == null || renderBox is! RenderBox) return;

    final buttonRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    widget.menuController.showMenu(
      context: context,
      anchorRect: buttonRect,
      installedTools: widget.installedTools,
      onShowInFinder: widget.onShowInFinder,
      onOpenInTerminal: widget.onOpenInTerminal,
      onOpenWith: widget.onOpenWith,
      onDelete: widget.onDelete,
    );
  }
}

// ==================== Menu Controller ====================

class _ProjectMenuController {
  _ProjectMenuController() : isMenuOpen = ValueNotifier(false);

  final ValueNotifier<bool> isMenuOpen;
  OverlayEntry? _overlayEntry;

  void showMenu({
    required BuildContext context,
    required Rect anchorRect,
    required List<Tool> installedTools,
    required VoidCallback onShowInFinder,
    required VoidCallback onOpenInTerminal,
    required void Function(ToolId) onOpenWith,
    required VoidCallback onDelete,
  }) {
    hideMenu();

    final overlayState = Overlay.of(context);
    if (overlayState == null) return;

    final overlayBox =
        overlayState.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final menuBuilder = _ProjectMenuBuilder(
      installedTools: installedTools,
      onShowInFinder: onShowInFinder,
      onOpenInTerminal: onOpenInTerminal,
      onOpenWith: onOpenWith,
      onDelete: onDelete,
    );

    final toolActions = menuBuilder.resolveToolActions(context);
    final menuWidth = menuBuilder.menuWidth(context);
    final desiredMenuHeight = menuBuilder.estimateMenuHeight(
      context,
      toolActions.length,
    );
    final availablePadding = CompactLayout.value(context, 8);
    final availableHeight = math.max(
      0.0,
      overlayBox.size.height - (availablePadding * 2),
    ).toDouble();
    final minMenuHeight = menuBuilder.minimumMenuHeight(context);
    var menuHeight = math.min(desiredMenuHeight, availableHeight).toDouble();
    if (menuHeight < minMenuHeight && availableHeight >= minMenuHeight) {
      menuHeight = minMenuHeight;
    }
    final openWithHeight = menuBuilder.constrainedOpenWithHeight(
      context,
      toolActions.length,
      menuHeight,
    );

    final menuRect = _MenuPositioner.calculateMenuRect(
      context: context,
      anchorRect: anchorRect,
      overlaySize: overlayBox.size,
      menuWidth: menuWidth,
      menuHeight: menuHeight,
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => _CustomMenuOverlay(
        menuRect: menuRect,
        menuWidth: menuWidth,
        menuHeight: menuHeight,
        menuBuilder: menuBuilder,
        onDismiss: hideMenu,
        onAction: _handleAction,
        toolActions: toolActions,
        openWithSectionHeight: openWithHeight,
      ),
    );

    overlayState.insert(_overlayEntry!);
    isMenuOpen.value = true;
  }

  void hideMenu() {
    if (_overlayEntry == null) {
      isMenuOpen.value = false;
      return;
    }

    _overlayEntry!.remove();
    _overlayEntry = null;
    isMenuOpen.value = false;
  }

  void _handleAction(_MenuAction action) {
    hideMenu();
    action.onSelected();
  }

  void dispose() {
    hideMenu();
    isMenuOpen.dispose();
  }
}

class _CustomMenuOverlay extends StatelessWidget {
  final Rect menuRect;
  final double menuWidth;
  final double menuHeight;
  final _ProjectMenuBuilder menuBuilder;
  final VoidCallback onDismiss;
  final void Function(_MenuAction) onAction;
  final List<_MenuAction> toolActions;
  final double openWithSectionHeight;

  const _CustomMenuOverlay({
    required this.menuRect,
    required this.menuWidth,
    required this.menuHeight,
    required this.menuBuilder,
    required this.onDismiss,
    required this.onAction,
    required this.toolActions,
    required this.openWithSectionHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (!menuRect.contains(event.position)) {
            onDismiss();
          }
        },
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: menuRect,
              child: SizedBox(
                width: menuWidth,
                height: menuHeight,
                child: Material(
                  elevation: 12,
                  color: menuBuilder.menuColor(Theme.of(context)),
                  shape: menuBuilder.menuShape(context),
                  clipBehavior: Clip.antiAlias,
                  child: menuBuilder.buildMenuContent(
                    context,
                    openWithSectionHeight: openWithSectionHeight,
                    toolActions: toolActions,
                    onAction: onAction,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Menu Builder ====================

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
  final void Function(ToolId toolId) onOpenWith;
  final VoidCallback onDelete;

  static const double _baseActionTileHeight = 38.0;
  static const double _baseMenuWidth = 260.0;
  static const double _headerHeight = 30.0;
  static const int _bottomActionCount = 3;

  List<_MenuAction> resolveToolActions(BuildContext context) =>
      _buildToolActions(context);

  double menuWidth(BuildContext context) =>
      CompactLayout.value(context, _baseMenuWidth);

  double estimateMenuHeight(BuildContext context, int toolCount) {
    final headerHeight = _headerSectionHeight(context);
    final dividerHeight = _dividerSectionHeight(context);
    final openWithHeight = _openWithSectionHeight(context, toolCount);

    return headerHeight +
        openWithHeight +
        dividerHeight +
        _bottomActionsHeight(context) +
        dividerHeight;
  }

  Widget buildMenuContent(
    BuildContext context, {
    required double openWithSectionHeight,
    required List<_MenuAction> toolActions,
    required void Function(_MenuAction) onAction,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MenuSectionHeader(label: 'Open with'),
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: openWithSectionHeight,
            ),
            child: _OpenWithSection(
              toolActions: toolActions,
              onAction: onAction,
            ),
          ),
        ),
        _MenuDivider(),
        _MenuActionTile(
          action: _MenuAction(
            label: 'Reveal in Finder',
            icon: Icons.folder_open,
            onSelected: onShowInFinder,
            semanticsLabel: 'Reveal project in Finder',
          ),
          onPressed: () => onAction(
            _MenuAction(
              label: 'Reveal in Finder',
              icon: Icons.folder_open,
              onSelected: onShowInFinder,
            ),
          ),
        ),
        _MenuActionTile(
          action: _MenuAction(
            label: 'Open in Terminal',
            icon: Icons.terminal,
            onSelected: onOpenInTerminal,
            semanticsLabel: 'Open project in terminal',
          ),
          onPressed: () => onAction(
            _MenuAction(
              label: 'Open in Terminal',
              icon: Icons.terminal,
              onSelected: onOpenInTerminal,
            ),
          ),
        ),
        _MenuDivider(),
        _MenuActionTile(
          action: _MenuAction(
            label: 'Hide project',
            icon: Icons.delete_outline,
            onSelected: onDelete,
            isDestructive: true,
          ),
          onPressed: () => onAction(
            _MenuAction(
              label: 'Hide project',
              icon: Icons.delete_outline,
              onSelected: onDelete,
              isDestructive: true,
            ),
          ),
        ),
      ],
    );
  }

  List<_MenuAction> _buildToolActions(BuildContext context) {
    return installedTools
        .map(
          (tool) => _MenuAction(
            label: tool.name,
            icon: Icons.launch,
            leading: ToolIcon(
              tool: tool,
              size: CompactLayout.value(context, 18),
              borderRadius: CompactLayout.value(context, 4),
            ),
            onSelected: () => onOpenWith(tool.id),
            semanticsLabel: 'Open project with ${tool.name}',
          ),
        )
        .toList();
  }

  double _openWithSectionHeight(BuildContext context, int toolCount) {
    final actionHeight = CompactLayout.value(context, _baseActionTileHeight);
    if (toolCount <= 0) return actionHeight;

    final baseHeight = toolCount * actionHeight;
    final maxHeight = math.max(
      actionHeight * 5,
      MediaQuery.of(context).size.height * 0.45,
    ).toDouble();
    return math.min(baseHeight, maxHeight).toDouble();
  }

  double minimumMenuHeight(BuildContext context) =>
      _reservedHeight(context) + _actionTileHeight(context);

  double constrainedOpenWithHeight(
    BuildContext context,
    int toolCount,
    double menuHeight,
  ) {
    final maxSectionHeight = _openWithSectionHeight(context, toolCount);
    final minSectionHeight = _actionTileHeight(context);
    final available = math.max(minSectionHeight, menuHeight - _reservedHeight(context));
    return math.min(maxSectionHeight, available).toDouble();
  }

  double _actionTileHeight(BuildContext context) =>
      CompactLayout.value(context, _baseActionTileHeight);

  double _headerSectionHeight(BuildContext context) =>
      CompactLayout.value(context, _headerHeight);

  double _dividerSectionHeight(BuildContext context) {
    final margin = CompactLayout.value(context, 4);
    return CompactLayout.value(context, 1) + (margin * 2);
  }

  double _bottomActionsHeight(BuildContext context) =>
      _actionTileHeight(context) * _bottomActionCount;

  double _reservedHeight(BuildContext context) =>
      _headerSectionHeight(context) +
      (_dividerSectionHeight(context) * 2) +
      _bottomActionsHeight(context);

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
}

// ==================== Menu Components ====================

class _MenuSectionHeader extends StatelessWidget {
  final String label;

  const _MenuSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.labelSmall ?? theme.textTheme.bodySmall;
    final headerStyle = baseStyle?.copyWith(
      color:
          (theme.textTheme.bodySmall?.color ??
                  theme.textTheme.bodyMedium?.color ??
                  Colors.white)
              .withOpacity(0.7),
      letterSpacing: 0.8,
      fontWeight: FontWeight.w700,
    );

    return SizedBox(
      height: CompactLayout.value(context, 30),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          CompactLayout.value(context, 12),
          CompactLayout.value(context, 6),
          CompactLayout.value(context, 12),
          CompactLayout.value(context, 4),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label.toUpperCase(), style: headerStyle),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(vertical: CompactLayout.value(context, 4)),
      color: Theme.of(context).dividerColor.withOpacity(0.35),
    );
  }
}

class _OpenWithSection extends StatelessWidget {
  final List<_MenuAction> toolActions;
  final void Function(_MenuAction) onAction;

  const _OpenWithSection({
    required this.toolActions,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (toolActions.isEmpty) {
      return _MenuActionTile(
        action: const _MenuAction(
          label: 'No supported tools installed',
          icon: Icons.block,
          onSelected: _noop,
          enabled: false,
        ),
        isMuted: true,
      );
    }

    return Scrollbar(
      radius: Radius.circular(CompactLayout.value(context, 5)),
      thickness: 4,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        itemCount: toolActions.length,
        itemBuilder: (context, index) => _MenuActionTile(
          action: toolActions[index],
          onPressed: () => onAction(toolActions[index]),
        ),
      ),
    );
  }
}

// ==================== Menu Action ====================

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
          child: Container(
            height: CompactLayout.value(context, 38),
            padding: EdgeInsets.symmetric(
              horizontal: CompactLayout.value(context, 12),
            ),
            decoration: BoxDecoration(
              color: widget.action.enabled && _hovered
                  ? accent.withOpacity(0.08)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                if (widget.action.leading != null) ...[
                  widget.action.leading!,
                ] else ...[
                  Icon(
                    widget.action.icon,
                    size: CompactLayout.value(context, 16),
                    color: textColor,
                  ),
                ],
                SizedBox(width: CompactLayout.value(context, 10)),
                Expanded(
                  child: Text(
                    widget.action.label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: CompactLayout.value(context, 12),
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

// ==================== Menu Positioning ====================

class _MenuPositioner {
  static Rect calculateMenuRect({
    required BuildContext context,
    required Rect anchorRect,
    required Size overlaySize,
    required double menuWidth,
    required double menuHeight,
  }) {
    final horizontalPadding = CompactLayout.value(context, 8);
    final horizontalOffset = -CompactLayout.value(context, 6);
    final verticalOffset = CompactLayout.value(context, 10);

    final desiredLeft = anchorRect.left + horizontalOffset;
    final left = math.min(
      overlaySize.width - menuWidth - horizontalPadding,
      math.max(horizontalPadding, desiredLeft),
    );

    final spaceBelow = overlaySize.height - anchorRect.bottom;
    final shouldShowAbove =
        menuHeight + verticalOffset > spaceBelow && anchorRect.top > menuHeight;

    final top = shouldShowAbove
        ? math.max(
            horizontalPadding,
            anchorRect.top - menuHeight - verticalOffset,
          )
        : math.min(
            overlaySize.height - menuHeight - horizontalPadding,
            anchorRect.bottom + verticalOffset,
          );

    return Rect.fromLTWH(left, top, menuWidth, menuHeight);
  }
}

void _noop() {}
