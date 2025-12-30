part of 'project_item.dart';

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

    final overlayBox = overlayState.context.findRenderObject() as RenderBox?;
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
                  elevation: menuBuilder.menuElevation(context),
                  color: menuBuilder.menuColor(context),
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
