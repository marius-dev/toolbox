import 'package:flutter/foundation.dart';
import '../../domain/models/project.dart';
import '../../domain/models/tool.dart';
import '../../domain/use_cases/project_use_cases.dart';
import '../../domain/repositories/project_repository.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectUseCases _useCases;

  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  String _searchQuery = '';
  SortOption _sortOption = SortOption.recent;
  bool _isLoading = false;

  ProjectProvider(this._useCases);

  factory ProjectProvider.create() {
    return ProjectProvider(ProjectUseCases(ProjectRepository.instance));
  }

  // Getters
  List<Project> get projects => _filteredProjects;
  SortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;
  bool get hasProjects => _filteredProjects.isNotEmpty;

  // Methods
  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _projects = await _useCases.getAllProjects();
      _applyFiltersAndSort();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    required ProjectType type,
    ToolId? preferredToolId,
  }) async {
    await _useCases.addProject(
      name: name,
      path: path,
      type: type,
      preferredToolId: preferredToolId,
    );
    await loadProjects();
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

  void _applyFiltersAndSort() {
    var filtered = _useCases.filterProjects(_projects, _searchQuery);
    filtered = _useCases.sortProjects(filtered, _sortOption);
    _filteredProjects = filtered;
    notifyListeners();
  }
}
