import 'dart:io';
import '../../presentation/widgets/project_item.dart';
import '../models/project.dart';
import '../repositories/project_repository.dart';

class ProjectUseCases {
  final ProjectRepository _repository;

  ProjectUseCases(this._repository);

  Future<List<Project>> getAllProjects() => _repository.loadProjects();

  Future<void> addProject({
    required String name,
    required String path,
    required ProjectType type,
  }) async {
    final project = Project.create(name: name, path: path, type: type);
    await _repository.addProject(project);
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

  Future<void> openProject(Project project) async {
    if (project.pathExists) {
      final updated = project.copyWith(lastOpened: DateTime.now());
      await _repository.updateProject(updated);
      // TODO: Add actual project opening logic
      print('Opening project: ${project.path}');
    }
  }

  Future<void> showInFinder(String path) async {
    try {
      // macOS
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      }
      // Windows
      else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      }
      // Linux
      else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (e) {
      print('Error showing in finder: $e');
    }
  }

  Future<void> openWith(String path, OpenWithApp app) async {
    try {
      String command;
      List<String> args = [];

      switch (app) {
        case OpenWithApp.vscode:
          command = 'code';
          args = [path];
          break;
        case OpenWithApp.intellij:
          command = 'idea';
          args = [path];
          break;
        case OpenWithApp.preview:
          if (Platform.isMacOS) {
            command = 'open';
            args = ['-a', 'Preview', path];
          } else if (Platform.isWindows) {
            command = 'cmd';
            args = ['/c', 'start', ''];
            args.add(path);
          } else {
            command = 'xdg-open';
            args = [path];
          }
          break;
      }

      await Process.run(command, args);
    } catch (e) {
      print('Error opening with $app: $e');
    }
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
        case SortOption.type:
          return a.type.name.compareTo(b.type.name);
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
