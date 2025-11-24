import 'dart:io';
import '../../core/services/tool_discovery_service.dart';
import '../../presentation/widgets/project_item.dart';
import '../models/project.dart';
import '../models/tool.dart';
import '../repositories/project_repository.dart';

class ProjectUseCases {
  final ProjectRepository _repository;

  ProjectUseCases(this._repository);

  Future<List<Project>> getAllProjects() => _repository.loadProjects();

  Future<void> addProject({
    required String name,
    required String path,
    required ProjectType type,
    ToolId? preferredToolId,
  }) async {
    final project = Project.create(
      name: name,
      path: path,
      type: type,
      preferredToolId: preferredToolId,
    );
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

  Future<void> openProject(
    Project project, {
    ToolId? defaultToolId,
    List<Tool> installedTools = const [],
  }) async {
    if (!project.pathExists) return;

    final discovery = ToolDiscoveryService.instance;
    final resolved = await _pickToolForProject(
      project,
      defaultToolId: defaultToolId,
      installedTools: installedTools,
    );

    if (resolved != null) {
      await discovery.launchTool(resolved.tool, targetPath: project.path);
      final updated = project.copyWith(
        lastOpened: DateTime.now(),
        lastUsedToolId: resolved.tool.id,
      );
      await _repository.updateProject(updated);
      return;
    }

    await _fallbackOpen(project.path, null);
    final updated = project.copyWith(lastOpened: DateTime.now());
    await _repository.updateProject(updated);
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

  Future<void> openWith(
    Project project,
    OpenWithApp app, {
    ToolId? defaultToolId,
    List<Tool> installedTools = const [],
  }) async {
    try {
      final toolId = _mapToToolId(app);
      final discovery = ToolDiscoveryService.instance;
      Tool? tool;
      try {
        tool = installedTools.firstWhere((t) => t.id == toolId);
      } catch (_) {
        tool = await discovery.discoverTool(toolId);
      }

      if (tool.isInstalled && tool.path != null) {
        await discovery.launchTool(tool, targetPath: project.path);
        final updated = project.copyWith(
          lastOpened: DateTime.now(),
          lastUsedToolId: tool.id,
        );
        await _repository.updateProject(updated);
        return;
      }

      await _fallbackOpen(project.path, app);
      final updated = project.copyWith(
        lastOpened: DateTime.now(),
        lastUsedToolId: toolId,
      );
      await _repository.updateProject(updated);
    } catch (e) {
      print('Error opening with $app: $e');
    }
  }

  ToolId _mapToToolId(OpenWithApp app) {
    switch (app) {
      case OpenWithApp.vscode:
        return ToolId.vscode;
      case OpenWithApp.intellij:
        return ToolId.intellij;
      case OpenWithApp.webstorm:
        return ToolId.webstorm;
      case OpenWithApp.phpstorm:
        return ToolId.phpstorm;
      case OpenWithApp.pycharm:
        return ToolId.pycharm;
      case OpenWithApp.clion:
        return ToolId.clion;
      case OpenWithApp.goland:
        return ToolId.goland;
      case OpenWithApp.datagrip:
        return ToolId.datagrip;
      case OpenWithApp.rider:
        return ToolId.rider;
      case OpenWithApp.rubymine:
        return ToolId.rubymine;
      case OpenWithApp.appcode:
        return ToolId.appcode;
      case OpenWithApp.fleet:
        return ToolId.fleet;
      case OpenWithApp.preview:
        return ToolId.preview;
    }
  }

  Future<_ResolvedTool?> _pickToolForProject(
    Project project, {
    ToolId? defaultToolId,
    List<Tool> installedTools = const [],
  }) async {
    final discovery = ToolDiscoveryService.instance;

    Tool? candidate;

    if (project.lastUsedToolId != null) {
      try {
        candidate = installedTools.firstWhere(
          (t) => t.id == project.lastUsedToolId,
        );
      } catch (_) {
        candidate = await discovery.discoverTool(project.lastUsedToolId!);
      }

      if ((!candidate.isInstalled || candidate.path == null)) {
        candidate = null;
      }
    }

    if (candidate == null && defaultToolId != null) {
      final fallback = await discovery.discoverTool(defaultToolId);
      if (fallback.isInstalled && fallback.path != null) {
        candidate = fallback;
      }
    }

    if (candidate == null && installedTools.isNotEmpty) {
      candidate = installedTools.first;
    }

    if (candidate != null && candidate.path != null) {
      return _ResolvedTool(candidate);
    }

    return null;
  }

  Future<void> _fallbackOpen(String path, OpenWithApp? app) async {
    String command = app?.name ?? 'open';
    List<String> args = [path];

    switch (app) {
      case OpenWithApp.vscode:
        command = 'code';
        break;
      case OpenWithApp.intellij:
        command = 'idea';
        break;
      case OpenWithApp.webstorm:
      case OpenWithApp.phpstorm:
      case OpenWithApp.pycharm:
      case OpenWithApp.clion:
      case OpenWithApp.goland:
      case OpenWithApp.datagrip:
      case OpenWithApp.rider:
      case OpenWithApp.rubymine:
      case OpenWithApp.appcode:
      case OpenWithApp.fleet:
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
      case null:
        if (Platform.isMacOS) {
          command = 'open';
          args = [path];
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

class _ResolvedTool {
  final Tool tool;

  _ResolvedTool(this.tool);
}
