part of 'project_item.dart';

class _ProjectActionsMenu extends StatefulWidget {
  final List<Tool> installedTools;
  final List<Workspace> otherWorkspaces;
  final ProjectItemActions actions;
  final _ProjectMenuController menuController;

  const _ProjectActionsMenu({
    required this.installedTools,
    required this.otherWorkspaces,
    required this.actions,
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
    final accentColor = _softAccentColor(context.accentColor, context.isDark);

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
                  padding: EdgeInsets.all(context.compactValue(8)),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accentColor.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      context.compactValue(10),
                    ),
                  ),
                  child: Icon(
                    Icons.more_horiz,
                    size: context.compactValue(16),
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
      otherWorkspaces: widget.otherWorkspaces,
      actions: widget.actions,
    );
  }
}

class _RemoveProjectButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _RemoveProjectButton({required this.onPressed});

  @override
  State<_RemoveProjectButton> createState() => _RemoveProjectButtonState();
}

class _RemoveProjectButtonState extends State<_RemoveProjectButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;
    final accentColor = _softAccentColor(context.accentColor, context.isDark);

    return Semantics(
      label: 'Remove from workspace',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Tooltip(
            message: 'Remove from workspace',
            waitDuration: const Duration(milliseconds: 120),
            child: Container(
              padding: EdgeInsets.all(context.compactValue(8)),
              decoration: BoxDecoration(
                color: _isHovered
                    ? accentColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(context.compactValue(DesignTokens.radiusMd)),
              ),
              child: Icon(
                Icons.close_rounded,
                size: context.compactValue(16),
                color: _isHovered ? accentColor : iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
