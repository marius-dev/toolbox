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
    if (_highlightedIndex != null &&
        _highlightedIndex! >= widget.projects.length) {
      _highlightedIndex = widget.projects.isNotEmpty
          ? widget.projects.length - 1
          : null;
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
    if (_itemKeys.length == widget.projects.length) return;
    if (_itemKeys.length > widget.projects.length) {
      _itemKeys.removeRange(widget.projects.length, _itemKeys.length);
    } else {
      _itemKeys.addAll(
        List.generate(
          widget.projects.length - _itemKeys.length,
          (_) => GlobalKey(),
        ),
      );
    }
  }

  void _syncSelectionWithProjects() {
    if (widget.projects.isEmpty) {
      _selectedIndex = 0;
      _selectedProjectId = null;
      return;
    }

    if (_selectedProjectId != null) {
      final existingIndex = widget.projects.indexWhere(
        (project) => project.id == _selectedProjectId,
      );
      if (existingIndex != -1) {
        _selectedIndex = existingIndex;
        return;
      }
    }

    final fallbackIndex = math.min(
      widget.projects.length - 1,
      math.max(0, _selectedIndex),
    );
    _selectedIndex = fallbackIndex;
    _selectedProjectId = widget.projects[fallbackIndex].id;
  }

  void _setHoverHighlight(int index) {
    if (_highlightedIndex == index && _isPointerHovering) return;
    setState(() {
      _highlightedIndex = index;
      _isPointerHovering = true;
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
    if (widget.focusNode.hasFocus && widget.projects.isNotEmpty) {
      final nextIndex = math.min(
        widget.projects.length - 1,
        math.max(0, _selectedIndex),
      );
      setState(() {
        _selectedIndex = nextIndex;
        _selectedProjectId = widget.projects[nextIndex].id;
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
    if (event is! KeyDownEvent || widget.projects.isEmpty) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = math.min(
          widget.projects.length - 1,
          _selectedIndex + 1,
        );
        _selectedProjectId = widget.projects[_selectedIndex].id;
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
        _selectedProjectId = widget.projects[_selectedIndex].id;
        _highlightedIndex = _selectedIndex;
      });
      _scrollToSelected();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      widget.onProjectTap(widget.projects[_selectedIndex]);
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
    if (widget.projects.isEmpty) return null;
    return _selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: _handleKeyEvent,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: widget.projects.length,
        itemBuilder: (context, index) {
          final project = widget.projects[index];
          final isHovering = _isPointerHovering && _highlightedIndex == index;
          final isFocused =
              widget.focusNode.hasFocus && index == _selectedIndex;
          return MouseRegion(
            cursor: project.pathExists
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: (_) => _setHoverHighlight(index),
            onExit: (_) => _clearHoverHighlight(),
            child: Container(
              key: _itemKeys[index],
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
        },
      ),
    );
  }
}
