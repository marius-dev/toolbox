import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/string_utils.dart';
import '../../../domain/models/project.dart';
import '../../../domain/models/tool.dart';
import '../app_menu.dart';
import '../tool_icon.dart';

part 'project_item_details.dart';
part 'project_item_menu_button.dart';
part 'project_item_menu_controller.dart';
part 'project_item_menu_builder.dart';
part 'project_item_menu_components.dart';
part 'project_item_menu_positioner.dart';

@immutable
class ProjectItemActions {
  final VoidCallback onTap;
  final VoidCallback onStarToggle;
  final VoidCallback onShowInFinder;
  final VoidCallback onOpenInTerminal;
  final void Function(ToolId toolId) onOpenWith;
  final VoidCallback onDelete;

  const ProjectItemActions({
    required this.onTap,
    required this.onStarToggle,
    required this.onShowInFinder,
    required this.onOpenInTerminal,
    required this.onOpenWith,
    required this.onDelete,
  });
}

@immutable
class ProjectItemStatus {
  final bool isFocused;
  final bool isHovering;
  final String searchQuery;
  final bool showDivider;
  final bool revealFullPath;
  final bool isOpening;
  final int openingDots;

  const ProjectItemStatus({
    this.isFocused = false,
    this.isHovering = false,
    this.searchQuery = '',
    this.showDivider = true,
    this.revealFullPath = false,
    this.isOpening = false,
    this.openingDots = 0,
  });
}

class ProjectItem extends StatefulWidget {
  final Project project;
  final List<Tool> installedTools;
  final ToolId? defaultToolId;
  final ProjectItemActions actions;
  final ProjectItemStatus status;

  const ProjectItem({
    super.key,
    required this.project,
    required this.installedTools,
    required this.defaultToolId,
    required this.actions,
    this.status = const ProjectItemStatus(),
  });

  @override
  State<ProjectItem> createState() => ProjectItemState();
}

class ProjectItemState extends State<ProjectItem> {
  late final _ProjectMenuController _menuController;
  ProjectItemActions get actions => widget.actions;
  ProjectItemStatus get status => widget.status;

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

  void openContextMenuFromSelection() {
    if (!project.pathExists) return;
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final rect = offset & renderBox.size;
    _menuController.showMenu(
      context: context,
      anchorRect: rect,
      installedTools: installedTools,
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = !project.pathExists;
    final accent = _softAccentColor(context.accentColor, context.isDark);
    final isHighlighted =
        status.isFocused || status.isHovering || status.isOpening;
    final highlightColor = theme.dividerColor.withOpacity(
      context.isDark ? 0.12 : 0.08,
    );
    final background = isHighlighted ? highlightColor : Colors.transparent;
    const borderColor = Colors.transparent;

    final row = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isDisabled ? null : _handleTap,
      onSecondaryTapDown: isDisabled ? null : _openContextMenu,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(bottom: context.compactValue(6)),
        padding: EdgeInsets.symmetric(horizontal: context.compactValue(12)),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: SizedBox(
          height: context.compactValue(56),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LeftAccent(isVisible: _isRecent, color: accent),
              SizedBox(width: context.compactValue(8)),
              _ProjectAvatar(project: project, isDisabled: isDisabled),
              SizedBox(width: context.compactValue(12)),
              Expanded(
                child: _ProjectDetails(
                  project: project,
                  preferredTool: _resolvePreferredTool(),
                  searchQuery: status.searchQuery,
                  revealFullPath: status.revealFullPath,
                  isOpening: status.isOpening,
                  openingDots: status.openingDots,
                  isDisabled: isDisabled,
                  accentColor: accent,
                ),
              ),
              SizedBox(width: context.compactValue(12)),
              if (isHighlighted && !isDisabled) ...[
                _StarButton(
                  isStarred: project.isStarred,
                  onPressed: widget.actions.onStarToggle,
                  accentColor: accent,
                ),
                SizedBox(width: context.compactValue(6)),
              ],
              if (isDisabled)
                _RemoveProjectButton(onPressed: widget.actions.onDelete)
              else
                _ProjectActionsMenu(
                  installedTools: installedTools,
                  actions: widget.actions,
                  menuController: _menuController,
                ),
            ],
          ),
        ),
      ),
    );

    return row;
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
      actions: actions,
    );
  }

  void _handleTap() {
    Focus.maybeOf(context)?.requestFocus();
    widget.actions.onTap();
  }

  bool get _isRecent {
    final now = DateTime.now();
    return now.difference(project.lastOpened) <= const Duration(days: 2);
  }
}
