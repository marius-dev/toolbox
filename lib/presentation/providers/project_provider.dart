import 'package:flutter/foundation.dart';

import '../../domain/models/project.dart';
import '../../domain/models/tool.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/use_cases/project_use_cases.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectUseCases _useCases;

  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  String _searchQuery = '';
  SortOption _sortOption = SortOption.recent;
  bool _isLoading = false;
  String? _selectedWorkspaceId;

  ProjectProvider(this._useCases);

  factory ProjectProvider.create() {
    return ProjectProvider(ProjectUseCases(ProjectRepository.instance));
  }

  // Getters
  List<Project> get projects => _filteredProjects;
  SortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;
  bool get hasProjects => _filteredProjects.isNotEmpty;
  String get searchQuery => _searchQuery;
  String? get selectedWorkspaceId => _selectedWorkspaceId;

  // Methods
  Future<void> loadProjects({String? fallbackWorkspaceId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _projects = await _useCases.getAllProjects();
      await _assignMissingWorkspaces(
        fallbackWorkspaceId ?? _selectedWorkspaceId,
      );
      _applyFiltersAndSort();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setWorkspaceId(String? workspaceId) {
    if (_selectedWorkspaceId == workspaceId) return;
    _selectedWorkspaceId = workspaceId;
    _applyFiltersAndSort();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFiltersAndSort();
  }

  Future<void> addProject({
    required String name,
    required String path,
    ToolId? preferredToolId,
    String? workspaceId,
  }) async {
    final resolvedWorkspaceId = workspaceId ?? _selectedWorkspaceId;
    assert(
      resolvedWorkspaceId != null && resolvedWorkspaceId.isNotEmpty,
      'Workspace must be selected before adding a project.',
    );
    if (resolvedWorkspaceId == null || resolvedWorkspaceId.isEmpty) {
      return;
    }
    await _useCases.addProject(
      name: name,
      path: path,
      preferredToolId: preferredToolId,
      workspaceId: resolvedWorkspaceId,
    );
    await loadProjects(fallbackWorkspaceId: resolvedWorkspaceId);
  }

  Future<void> updateProject(Project project) async {
    await _useCases.updateProject(project);
    await loadProjects();
  }

  Future<void> deleteProject(String projectId) async {
    await _useCases.deleteProject(projectId);
    await loadProjects();
  }

  Future<void> toggleStar(Project project) async {
    await _useCases.toggleStar(project);
    await loadProjects();
  }

  Future<void> openProject(
    Project project, {
    ToolId? defaultToolId,
    List<Tool> installedTools = const [],
  }) async {
    await _useCases.openProject(
      project,
      defaultToolId: defaultToolId,
      installedTools: installedTools,
    );
    await loadProjects();
  }

  Future<void> showInFinder(String path) async {
    await _useCases.showInFinder(path);
  }

  Future<void> openInTerminal(Project project) async {
    if (!project.pathExists) return;
    await _useCases.openInTerminal(project.path);
  }

  Future<void> openWith(
    Project project,
    ToolId toolId, {
    ToolId? defaultToolId,
    List<Tool> installedTools = const [],
  }) async {
    await _useCases.openWith(
      project,
      toolId,
      defaultToolId: defaultToolId,
      installedTools: installedTools,
    );
    await loadProjects();
  }

  Future<void> reassignWorkspace({
    required String fromWorkspaceId,
    required String toWorkspaceId,
  }) async {
    if (fromWorkspaceId == toWorkspaceId) return;
    final updates = _projects
        .where((project) => project.workspaceId == fromWorkspaceId)
        .map((project) => project.copyWith(workspaceId: toWorkspaceId))
        .toList();
    for (final project in updates) {
      await _useCases.updateProject(project);
    }
    await loadProjects(fallbackWorkspaceId: toWorkspaceId);
  }

  void _applyFiltersAndSort() {
    var filtered = _projects;
    if (_selectedWorkspaceId != null && _selectedWorkspaceId!.isNotEmpty) {
      filtered = filtered
          .where((project) => project.workspaceId == _selectedWorkspaceId)
          .toList();
    }
    filtered = _useCases.filterProjects(filtered, _searchQuery);
    filtered = _useCases.sortProjects(filtered, _sortOption);
    _filteredProjects = filtered;
    notifyListeners();
  }

  Future<void> _assignMissingWorkspaces(String? workspaceId) async {
    if (workspaceId == null || workspaceId.isEmpty) return;
    final updates = _projects
        .where((project) =>
            project.workspaceId == null || project.workspaceId!.isEmpty)
        .map((project) => project.copyWith(workspaceId: workspaceId))
        .toList();
    for (final project in updates) {
      await _useCases.updateProject(project);
    }
    if (updates.isNotEmpty) {
      _projects = await _useCases.getAllProjects();
    }
  }
}
