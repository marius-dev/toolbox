part of 'project_item.dart';

const double _kProjectMenuActionTileBaseHeight = 34.0; // More compact
const double _kProjectMenuIconBaseSize = 16.0;

class _ProjectMenuBuilder {
  const _ProjectMenuBuilder({
    required this.installedTools,
    required this.actions,
    required this.otherWorkspaces,
  });

  final List<Tool> installedTools;
  final ProjectItemActions actions;
  final List<Workspace> otherWorkspaces;

  static const double _baseActionTileHeight = _kProjectMenuActionTileBaseHeight;
  static const double _baseMenuWidth = 240.0; // Slightly narrower
  static const double _headerHeight = 22.0; // More compact header
  static const int _bottomActionCount = 3;

  List<_MenuAction> resolveToolActions(BuildContext context) =>
      _buildToolActions(context);

  double menuWidth(BuildContext context) =>
      context.compactValue(_baseMenuWidth);

  double estimateMenuHeight(BuildContext context, int toolCount) {
    final headerHeight = _headerSectionHeight(context);
    final dividerHeight = _dividerSectionHeight(context);
    final openWithHeight = _openWithSectionHeight(context, toolCount);
    final workspaceHeight = _workspaceSectionHeight(context);

    // Add small buffer to prevent sub-pixel overflow
    const buffer = 2.0;

    return headerHeight +
        openWithHeight +
        dividerHeight +
        _bottomActionsHeight(context) +
        (workspaceHeight > 0 ? dividerHeight + workspaceHeight : 0) +
        dividerHeight +
        buffer;
  }

  double _workspaceSectionHeight(BuildContext context) {
    if (otherWorkspaces.isEmpty) return 0;
    final headerHeight = _headerSectionHeight(context);
    final actionHeight = _actionTileHeight(context);
    // Show header + up to 3 workspaces, scrollable if more
    final itemCount = math.min(otherWorkspaces.length, 3);
    return headerHeight + (actionHeight * itemCount);
  }

  Widget buildMenuContent(
    BuildContext context, {
    required double openWithSectionHeight,
    required List<_MenuAction> toolActions,
    required void Function(_MenuAction) onAction,
  }) {
    // Create menu actions once to avoid duplication
    final revealAction = _MenuAction(
      label: PlatformStrings.revealInFileManager,
      icon: Icons.folder_open,
      onSelected: actions.onShowInFinder,
      semanticsLabel: PlatformStrings.revealProjectInFileManager(),
    );

    final terminalAction = _MenuAction(
      label: PlatformStrings.openInTerminal,
      icon: Icons.terminal,
      onSelected: actions.onOpenInTerminal,
      semanticsLabel: PlatformStrings.openProjectInTerminal(),
    );

    final deleteAction = _MenuAction(
      label: 'Hide project',
      icon: Icons.delete_outline,
      onSelected: actions.onDelete,
      isDestructive: true,
    );

    // Build workspace move actions
    final workspaceActions = otherWorkspaces
        .map(
          (ws) => _MenuAction(
            label: ws.name,
            icon: Icons.drive_file_move_outline,
            onSelected: () => actions.onMoveToWorkspace?.call(ws.id),
            semanticsLabel: 'Move to ${ws.name}',
          ),
        )
        .toList();

    // Calculate workspace section height (max 3 items visible)
    final workspaceSectionHeight = workspaceActions.isEmpty
        ? 0.0
        : math.min(workspaceActions.length, 3) * _actionTileHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MenuSectionHeader(label: 'Open with'),
        SizedBox(
          height: openWithSectionHeight,
          child: _ScrollableActionList(
            actions: toolActions,
            onAction: onAction,
            emptyMessage: 'No supported tools installed',
          ),
        ),
        const _MenuDivider(),
        _MenuActionTile(
          action: revealAction,
          onPressed: () => onAction(revealAction),
        ),
        _MenuActionTile(
          action: terminalAction,
          onPressed: () => onAction(terminalAction),
        ),
        if (workspaceActions.isNotEmpty) ...[
          const _MenuDivider(),
          const _MenuSectionHeader(label: 'Move to'),
          SizedBox(
            height: workspaceSectionHeight,
            child: _ScrollableActionList(
              actions: workspaceActions,
              onAction: onAction,
            ),
          ),
        ],
        const _MenuDivider(),
        _MenuActionTile(
          action: deleteAction,
          onPressed: () => onAction(deleteAction),
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
              size: context.compactValue(18),
              borderRadius: context.compactValue(4),
            ),
            onSelected: () => actions.onOpenWith(tool.id),
            semanticsLabel: 'Open project with ${tool.name}',
          ),
        )
        .toList();
  }

  double _openWithSectionHeight(BuildContext context, int toolCount) {
    final actionHeight = context.compactValue(_baseActionTileHeight);
    if (toolCount <= 0) return actionHeight;

    final baseHeight = toolCount * actionHeight;
    final maxHeight = math
        .max(actionHeight * 5, MediaQuery.of(context).size.height * 0.45)
        .toDouble();
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
    final available = math.max(
      minSectionHeight,
      menuHeight - _reservedHeight(context),
    );
    return math.min(maxSectionHeight, available).toDouble();
  }

  double _actionTileHeight(BuildContext context) =>
      context.compactValue(_baseActionTileHeight);

  double _headerSectionHeight(BuildContext context) =>
      context.compactValue(_headerHeight);

  double _dividerSectionHeight(BuildContext context) {
    final margin = context.compactValue(4);
    return context.compactValue(1) + (margin * 2);
  }

  double _bottomActionsHeight(BuildContext context) =>
      _actionTileHeight(context) * _bottomActionCount;

  double _reservedHeight(BuildContext context) =>
      _headerSectionHeight(context) +
      (_dividerSectionHeight(context) * 2) +
      _bottomActionsHeight(context);

  Color menuColor(BuildContext context) {
    return AppMenuStyle.of(context).backgroundColor;
  }

  ShapeBorder menuShape(BuildContext context) {
    return AppMenuStyle.of(context).shape;
  }

  double menuElevation(BuildContext context) {
    return AppMenuStyle.of(context).elevation;
  }
}
