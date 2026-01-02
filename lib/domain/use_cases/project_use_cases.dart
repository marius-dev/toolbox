import '../models/project.dart';
import '../models/tool.dart';
import '../repositories/project_repository.dart';
import '../services/project_launch_service.dart';
import '../services/project_metadata_sync_service.dart';

class ProjectUseCases {
  final ProjectRepository _repository;
  final ProjectMetadataSyncService _metadataSyncService;
  final ProjectLaunchService _launchService;

  ProjectUseCases(
    this._repository,
    this._metadataSyncService,
    this._launchService,
  );

  Future<List<Project>> getAllProjects() => _repository.loadProjects();

  Future<List<Project>> syncProjectMetadata(List<Project> projects) {
    return _metadataSyncService.syncMetadata(projects);
  }

  Future<void> addProject({
    required String name,
    required String path,
    required String workspaceId,
    ToolId? preferredToolId,
  }) async {
    final project = Project.create(
      name: name,
      path: path,
      workspaceId: workspaceId,
      preferredToolId: preferredToolId,
    );
    await _repository.addProject(project);
  }

  Future<void> addProjects(List<Project> projects) async {
    if (projects.isEmpty) return;
    await _repository.addProjects(projects);
  }

  Future<void> updateProject(Project project) async {
    await _repository.updateProject(project);
  }

  Future<void> deleteProject(String projectId) async {
    await _repository.deleteProject(projectId);
  }

  Future<void> toggleStar(Project project) async {
    final updated = project.copyWith(isStarred: !project.isStarred);
    await _repository.updateProject(updated);
  }

  Future<void> openProject(
    Project project, {
    ToolId? defaultToolId,
    List<Tool> installedTools = const [],
  }) {
    return _launchService.openProject(
      project,
      defaultToolId: defaultToolId,
      installedTools: installedTools,
    );
  }

  Future<void> showInFinder(String path) {
    return _launchService.showInFinder(path);
  }

  Future<void> openInTerminal(Project project) {
    if (!project.pathExists) {
      return Future.value();
    }
    return _launchService.openInTerminal(project.path);
  }

  Future<void> openWith(
    Project project,
    ToolId toolId, {
    ToolId? defaultToolId,
    List<Tool> installedTools = const [],
  }) {
    return _launchService.openWith(
      project,
      toolId,
      defaultToolId: defaultToolId,
      installedTools: installedTools,
    );
  }

  List<Project> sortProjects(List<Project> projects, SortOption sortOption) {
    final sorted = List<Project>.from(projects);

    sorted.sort((a, b) {
      // Starred projects always come first
      if (a.isStarred && !b.isStarred) return -1;
      if (!a.isStarred && b.isStarred) return 1;

      // Then sort by the selected option
      switch (sortOption) {
        case SortOption.recent:
          return b.lastOpened.compareTo(a.lastOpened);
        case SortOption.created:
          return b.createdAt.compareTo(a.createdAt);
        case SortOption.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    return sorted;
  }

  List<Project> filterProjects(List<Project> projects, String query) {
    if (query.isEmpty) return projects;

    final lowerQuery = query.toLowerCase();
    return projects.where((project) {
      return project.name.toLowerCase().contains(lowerQuery) ||
          project.path.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
