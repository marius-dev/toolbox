part of 'project_item.dart';

String _revealActionLabel() {
  if (Platform.isMacOS) return 'Reveal in Finder';
  if (Platform.isWindows) return 'Show in Explorer';
  if (Platform.isLinux) return 'Show in Files';
  return 'Show in Files';
}

String _revealActionSemanticsLabel() {
  if (Platform.isMacOS) return 'Reveal project in Finder';
  if (Platform.isWindows) return 'Show project in Explorer';
  if (Platform.isLinux) return 'Show project in Files';
  return 'Show project in Files';
}

const double _kProjectMenuActionTileBaseHeight = 42.0;
const double _kProjectMenuIconBaseSize = 18.0;

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

  static const double _baseActionTileHeight = _kProjectMenuActionTileBaseHeight;
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
        const _MenuSectionHeader(label: 'Open with'),
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: openWithSectionHeight),
            child: _OpenWithSection(
              toolActions: toolActions,
              onAction: onAction,
            ),
          ),
        ),
        const _MenuDivider(),
        _MenuActionTile(
          action: _MenuAction(
            label: _revealActionLabel(),
            icon: Icons.folder_open,
            onSelected: onShowInFinder,
            semanticsLabel: _revealActionSemanticsLabel(),
          ),
          onPressed: () => onAction(
            _MenuAction(
              label: _revealActionLabel(),
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
        const _MenuDivider(),
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
