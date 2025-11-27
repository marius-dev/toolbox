import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/project.dart';
import '../../domain/models/tool.dart';
import 'project_item.dart';

class ProjectList extends StatefulWidget {
  final List<Project> projects;
  final List<Tool> installedTools;
  final ToolId? defaultToolId;
  final ValueChanged<Project> onProjectTap;
  final ValueChanged<Project> onStarToggle;
  final ValueChanged<Project> onShowInFinder;
  final void Function(Project project, OpenWithApp app) onOpenWith;
  final ValueChanged<Project> onDelete;
  final FocusNode focusNode;
  final VoidCallback onFocusSearch;

  const ProjectList({
    super.key,
    required this.projects,
    required this.installedTools,
    required this.defaultToolId,
    required this.onProjectTap,
    required this.onStarToggle,
    required this.onShowInFinder,
    required this.onOpenWith,
    required this.onDelete,
    required this.focusNode,
    required this.onFocusSearch,
  });

  @override
  State<ProjectList> createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];
  int _selectedIndex = 0;
  int? _highlightedIndex;
  String? _selectedProjectId;
  bool _isPointerHovering = false;

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
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _scrollController.dispose();
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
          (_) => GlobalKey(),
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
      });
      _scrollToSelected();
    } else {
      setState(() {
        _highlightedIndex = null;
        _isPointerHovering = false;
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final ordered = _orderedProjects();
    if (ordered.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = math.min(
          ordered.length - 1,
          _selectedIndex + 1,
        );
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
      widget.onProjectTap(ordered[_selectedIndex]);
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

  int? get _currentHighlightedIndex {
    if (_highlightedIndex != null) return _highlightedIndex;
    if (!widget.focusNode.hasFocus) return null;
    final ordered = _orderedProjects();
    if (ordered.isEmpty) return null;
    return _selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _projectSections();
    final favorites = sections.favorites;
    final others = sections.others;

    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (favorites.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(context, 'Favorites'),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildProjectEntry(
                    favorites[index],
                    index,
                  ),
                  childCount: favorites.length,
                ),
              ),
              if (others.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
            if (others.isNotEmpty) ...[
              if (favorites.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSectionHeader(context, 'Projects'),
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
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    final theme = Theme.of(context);
    final baseColor =
        theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface;
    final headerStyle = (theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium)
        ?.copyWith(
          color: baseColor.withOpacity(0.75),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        label,
        style: headerStyle,
      ),
    );
  }

  Widget _buildProjectEntry(
    Project project,
    int globalIndex,
  ) {
    final isHovering = _isPointerHovering && _highlightedIndex == globalIndex;
    final isFocused = widget.focusNode.hasFocus && globalIndex == _selectedIndex;

    return MouseRegion(
      cursor: project.pathExists
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _setHoverHighlight(globalIndex),
      onExit: (_) => _clearHoverHighlight(),
      child: Container(
        key: _itemKeys[globalIndex],
        child: ProjectItem(
          project: project,
          installedTools: widget.installedTools,
          defaultToolId: widget.defaultToolId,
          isFocused: isFocused,
          isHovering: isHovering,
          onTap: () => widget.onProjectTap(project),
          onStarToggle: () => widget.onStarToggle(project),
          onShowInFinder: () => widget.onShowInFinder(project),
          onOpenWith: (app) => widget.onOpenWith(project, app),
          onDelete: () => widget.onDelete(project),
        ),
      ),
    );
  }

  List<Project> _orderedProjects() => _projectSections().ordered;

  _ProjectSections _projectSections() {
    final favorites = <Project>[];
    final others = <Project>[];
    for (final project in widget.projects) {
      if (project.isStarred) {
        favorites.add(project);
      } else {
        others.add(project);
      }
    }
    return _ProjectSections(favorites: favorites, others: others);
  }
}

class _ProjectSections {
  final List<Project> favorites;
  final List<Project> others;
  final List<Project> ordered;

  _ProjectSections({
    required this.favorites,
    required this.others,
  }) : ordered = [...favorites, ...others];
}
