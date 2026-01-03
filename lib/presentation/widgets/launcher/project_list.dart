import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../domain/models/project.dart';
import '../../../domain/models/tool.dart';
import '../../../domain/models/workspace.dart';
import 'project_item.dart';
import 'project_list_scroll_behavior.dart';
import 'project_section_header.dart';
import 'project_sections.dart';

class ProjectList extends StatefulWidget {
  final List<Project> projects;
  final List<Tool> installedTools;
  final ToolId? defaultToolId;
  final List<Workspace> otherWorkspaces;
  final String searchQuery;
  final Future<void> Function(Project project) onProjectTap;
  final ValueChanged<Project> onStarToggle;
  final ValueChanged<Project> onShowInFinder;
  final ValueChanged<Project> onOpenInTerminal;
  final void Function(Project project, ToolId toolId) onOpenWith;
  final void Function(Project project, String workspaceId)? onMoveToWorkspace;
  final ValueChanged<Project> onDelete;
  final FocusNode focusNode;
  final VoidCallback onFocusSearch;

  const ProjectList({
    super.key,
    required this.projects,
    required this.installedTools,
    required this.defaultToolId,
    this.otherWorkspaces = const [],
    required this.searchQuery,
    required this.onProjectTap,
    required this.onStarToggle,
    required this.onShowInFinder,
    required this.onOpenInTerminal,
    required this.onOpenWith,
    this.onMoveToWorkspace,
    required this.onDelete,
    required this.focusNode,
    required this.onFocusSearch,
  });

  @override
  State<ProjectList> createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey<ProjectItemState>> _itemKeys = [];
  int _selectedIndex = 0;
  int? _highlightedIndex;
  String? _selectedProjectId;
  bool _isPointerHovering = false;
  bool _revealFullPath = false;
  String? _openingProjectId;
  int _openingDot = 0;
  Timer? _openingTimer;

  @override
  void initState() {
    super.initState();
    _syncKeys();
    _syncSelectionWithProjects();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant ProjectList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
    }
    _syncKeys();
    _syncSelectionWithProjects();
    final ordered = _orderedProjects();
    if (_highlightedIndex != null && _highlightedIndex! >= ordered.length) {
      _highlightedIndex = ordered.isNotEmpty ? ordered.length - 1 : null;
    }
    if (widget.focusNode.hasFocus && widget.projects.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
    if (_openingProjectId != null &&
        ordered.every((p) => p.id != _openingProjectId)) {
      _stopOpening(_openingProjectId!);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _scrollController.dispose();
    _openingTimer?.cancel();
    super.dispose();
  }

  void _syncKeys() {
    final ordered = _orderedProjects();
    if (_itemKeys.length == ordered.length) return;
    if (_itemKeys.length > ordered.length) {
      _itemKeys.removeRange(ordered.length, _itemKeys.length);
    } else {
      _itemKeys.addAll(
        List.generate(
          ordered.length - _itemKeys.length,
          (_) => GlobalKey<ProjectItemState>(),
        ),
      );
    }
  }

  void _syncSelectionWithProjects() {
    final ordered = _orderedProjects();
    if (ordered.isEmpty) {
      _selectedIndex = 0;
      _selectedProjectId = null;
      return;
    }

    if (_selectedProjectId != null) {
      final existingIndex = ordered.indexWhere(
        (project) => project.id == _selectedProjectId,
      );
      if (existingIndex != -1) {
        _selectedIndex = existingIndex;
        return;
      }
    }

    final fallbackIndex = math.min(
      ordered.length - 1,
      math.max(0, _selectedIndex),
    );
    _selectedIndex = fallbackIndex;
    _selectedProjectId = ordered[fallbackIndex].id;
  }

  void _setHoverHighlight(int index) {
    final ordered = _orderedProjects();
    if (index < 0 || index >= ordered.length) return;

    if (_highlightedIndex == index && _isPointerHovering) return;
    setState(() {
      _highlightedIndex = index;
      _isPointerHovering = true;
      _selectedIndex = index;
      _selectedProjectId = ordered[index].id;
    });
  }

  void _clearHoverHighlight() {
    if (!_isPointerHovering) return;
    setState(() {
      _isPointerHovering = false;
      _highlightedIndex = widget.focusNode.hasFocus ? _selectedIndex : null;
    });
  }

  void _handleFocusChange() {
    if (!mounted) return;
    final ordered = _orderedProjects();
    if (widget.focusNode.hasFocus && ordered.isNotEmpty) {
      final nextIndex = math.min(
        ordered.length - 1,
        math.max(0, _selectedIndex),
      );
      setState(() {
        _selectedIndex = nextIndex;
        _selectedProjectId = ordered[nextIndex].id;
        _highlightedIndex = nextIndex;
        _isPointerHovering = false;
        _revealFullPath = false;
      });
      _scrollToSelected();
    } else {
      setState(() {
        _highlightedIndex = null;
        _isPointerHovering = false;
        _revealFullPath = false;
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      if (event is KeyDownEvent && !_revealFullPath) {
        setState(() => _revealFullPath = true);
      } else if (event is KeyUpEvent && _revealFullPath) {
        setState(() => _revealFullPath = false);
      }
      return KeyEventResult.handled;
    }

    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final ordered = _orderedProjects();
    if (ordered.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = math.min(ordered.length - 1, _selectedIndex + 1);
        _selectedProjectId = ordered[_selectedIndex].id;
        _highlightedIndex = _selectedIndex;
      });
      _scrollToSelected();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_selectedIndex == 0) {
        widget.focusNode.unfocus();
        widget.onFocusSearch();
        setState(() {
          _highlightedIndex = null;
        });
        return KeyEventResult.handled;
      }
      setState(() {
        _selectedIndex = math.max(0, _selectedIndex - 1);
        _selectedProjectId = ordered[_selectedIndex].id;
        _highlightedIndex = _selectedIndex;
      });
      _scrollToSelected();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final project = ordered[_selectedIndex];
      unawaited(_handleProjectTap(project, _selectedIndex));
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToSelected() {
    if (_selectedIndex < 0 || _selectedIndex >= _itemKeys.length) return;
    final context = _itemKeys[_selectedIndex].currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 200),
      alignment: 0.3,
    );
  }

  Future<void> _handleProjectTap(Project project, int globalIndex) async {
    final ordered = _orderedProjects();
    if (globalIndex < 0 || globalIndex >= ordered.length) return;

    setState(() {
      _selectedIndex = globalIndex;
      _selectedProjectId = project.id;
      _highlightedIndex = globalIndex;
      _isPointerHovering = false;
    });

    widget.focusNode.requestFocus();
    _scrollToSelected();

    if (!project.pathExists) {
      return;
    }

    await _runOpeningAction(project, () => widget.onProjectTap(project));
  }

  void _startOpening(String projectId) {
    _openingTimer?.cancel();
    setState(() {
      _openingProjectId = projectId;
      _openingDot = 0;
    });

    _openingTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (!mounted) return;
      setState(() {
        _openingDot = (_openingDot + 1) % 3;
      });
    });
  }

  void _stopOpening(String projectId) {
    if (_openingProjectId != projectId) return;
    _openingTimer?.cancel();
    _openingTimer = null;
    setState(() {
      _openingProjectId = null;
      _openingDot = 0;
    });
  }

  Future<void> _runOpeningAction(
    Project project,
    Future<void> Function() action,
  ) async {
    final openingId = project.id;
    _startOpening(openingId);

    await Future.delayed(const Duration(seconds: 1));
    if (_openingProjectId != openingId) return;

    try {
      await action();
    } finally {
      _stopOpening(openingId);
    }
  }

  Future<void> _handleOpenInTerminal(Project project) {
    return _runOpeningAction(
      project,
      () => Future.sync(() => widget.onOpenInTerminal(project)),
    );
  }

  Future<void> _handleShowInFinder(Project project) {
    return _runOpeningAction(
      project,
      () => Future.sync(() => widget.onShowInFinder(project)),
    );
  }

  Future<void> _handleOpenWith(Project project, ToolId toolId) {
    return _runOpeningAction(
      project,
      () => Future.sync(() => widget.onOpenWith(project, toolId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _projectSections();
    final favorites = sections.favorites;
    final others = sections.others;
    final headerPadding = context.compactPaddingOnly(top: 6, bottom: 4);
    final theme = Theme.of(context);
    final background = theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.5)
        : Colors.white.withOpacity(0.9);
    final borderColor = theme.dividerColor.withOpacity(0.16);

    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        margin: context.compactPaddingOnly(left: 10, right: 10, bottom: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ScrollConfiguration(
            behavior: const ProjectListScrollBehavior(),
            child: Scrollbar(
              controller: _scrollController,
              radius: const Radius.circular(6),
              thickness: 4,
              child: Padding(
                padding: context.compactPadding(horizontal: 12),
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    if (favorites.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: headerPadding,
                          child: const ProjectSectionHeader(label: 'Favorites'),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildProjectEntry(favorites[index], index),
                          childCount: favorites.length,
                        ),
                      ),
                      if (others.isNotEmpty)
                        const SliverToBoxAdapter(child: SizedBox(height: 6)),
                    ],
                    if (others.isNotEmpty) ...[
                      if (favorites.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: headerPadding,
                            child: const ProjectSectionHeader(
                              label: 'Projects',
                            ),
                          ),
                        ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProjectEntry(
                            others[index],
                            favorites.length + index,
                          ),
                          childCount: others.length,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectEntry(Project project, int globalIndex) {
    final isHovering = _isPointerHovering && _highlightedIndex == globalIndex;
    final isFocused =
        widget.focusNode.hasFocus && globalIndex == _selectedIndex;
    final isOpening = _openingProjectId == project.id;
    final topPadding = globalIndex == 0 ? context.compactValue(10) : 0.0;

    final key = _itemKeys[globalIndex];

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: MouseRegion(
        cursor: project.pathExists
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => _setHoverHighlight(globalIndex),
        onExit: (_) => _clearHoverHighlight(),
        child: ProjectItem(
          key: key,
          project: project,
          installedTools: widget.installedTools,
          defaultToolId: widget.defaultToolId,
          otherWorkspaces: widget.otherWorkspaces,
          actions: ProjectItemActions(
            onTap: () => _handleProjectTap(project, globalIndex),
            onStarToggle: () => widget.onStarToggle(project),
            onShowInFinder: () => _handleShowInFinder(project),
            onOpenInTerminal: () => _handleOpenInTerminal(project),
            onOpenWith: (toolId) => _handleOpenWith(project, toolId),
            onMoveToWorkspace: widget.onMoveToWorkspace != null
                ? (workspaceId) => widget.onMoveToWorkspace!(project, workspaceId)
                : null,
            onDelete: () => widget.onDelete(project),
          ),
          status: ProjectItemStatus(
            isFocused: isFocused,
            isHovering: isHovering,
            searchQuery: widget.searchQuery,
            showDivider: globalIndex < _itemKeys.length - 1,
            revealFullPath: _revealFullPath,
            isOpening: isOpening,
            openingDots: _openingDot,
          ),
        ),
      ),
    );
  }

  List<Project> _orderedProjects() => _projectSections().ordered;

  ProjectSections _projectSections() {
    final favorites = <Project>[];
    final others = <Project>[];
    for (final project in widget.projects) {
      if (project.isStarred) {
        favorites.add(project);
      } else {
        others.add(project);
      }
    }
    return ProjectSections(favorites: favorites, others: others);
  }
}
