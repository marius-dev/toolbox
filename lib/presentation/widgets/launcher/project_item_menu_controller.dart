part of 'project_item.dart';

class _ProjectMenuController {
  _ProjectMenuController() : isMenuOpen = ValueNotifier(false);

  final ValueNotifier<bool> isMenuOpen;
  OverlayEntry? _overlayEntry;

  void showMenu({
    required BuildContext context,
    required Rect anchorRect,
    required List<Tool> installedTools,
    required List<Workspace> otherWorkspaces,
    required ProjectItemActions actions,
  }) {
    hideMenu();

    final overlayState = Overlay.of(context);

    final overlayBox = overlayState.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final menuBuilder = _ProjectMenuBuilder(
      installedTools: installedTools,
      otherWorkspaces: otherWorkspaces,
      actions: actions,
    );

    final toolActions = menuBuilder.resolveToolActions(context);
    final menuWidth = menuBuilder.menuWidth(context);
    final desiredMenuHeight = menuBuilder.estimateMenuHeight(
      context,
      toolActions.length,
    );
    final availablePadding = context.compactValue(8);
    final availableHeight = math
        .max(0.0, overlayBox.size.height - (availablePadding * 2))
        .toDouble();
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

class _CustomMenuOverlay extends StatefulWidget {
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
  State<_CustomMenuOverlay> createState() => _CustomMenuOverlayState();
}

class _CustomMenuOverlayState extends State<_CustomMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _closeTimer;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onMouseEnter() {
    _closeTimer?.cancel();
    setState(() => _isHovering = true);
  }

  void _onMouseExit() {
    setState(() => _isHovering = false);
    // Debounced close - wait 250ms before closing
    _closeTimer = Timer(const Duration(milliseconds: 250), () {
      if (!_isHovering && mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (!widget.menuRect.contains(event.position)) {
            widget.onDismiss();
          }
        },
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: widget.menuRect,
              child: MouseRegion(
                onEnter: (_) => _onMouseEnter(),
                onExit: (_) => _onMouseExit(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: widget.menuWidth,
                      height: widget.menuHeight,
                      child: Material(
                        elevation: widget.menuBuilder.menuElevation(context),
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        color: widget.menuBuilder.menuColor(context),
                        shape: widget.menuBuilder.menuShape(context),
                        clipBehavior: Clip.antiAlias,
                        child: widget.menuBuilder.buildMenuContent(
                          context,
                          openWithSectionHeight: widget.openWithSectionHeight,
                          toolActions: widget.toolActions,
                          onAction: widget.onAction,
                        ),
                      ),
                    ),
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
