import 'dart:io';

import '../../core/services/tool_discovery_service.dart';
import '../models/project.dart';
import '../models/tool.dart';
import '../repositories/project_repository.dart';

/// Service responsible for launching projects and related external actions.
class ProjectLaunchService {
  ProjectLaunchService(
    this._repository,
    this._discoveryService,
  );

  final ProjectRepository _repository;
  final ToolDiscoveryService _discoveryService;

  /// Opens the project using a preferred tool if available or falls back to the OS.
  Future<void> openProject(
    Project project, {
    ToolId? defaultToolId,
    List<Tool> installedTools = const [],
  }) async {
    if (!project.pathExists) return;

    final resolved = await _pickToolForProject(
      project,
      defaultToolId: defaultToolId,
      installedTools: installedTools,
    );

    if (resolved != null) {
      await _discoveryService.launchTool(resolved.tool, targetPath: project.path);
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

  /// Shows the directory containing [path] in the OS file browser.
  Future<void> showInFinder(String path) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (e) {
      print('Error showing in finder: $e');
    }
  }

  /// Attempts to open the [path] in a new terminal window.
  Future<void> openInTerminal(String path) async {
    if (!Directory(path).existsSync()) return;

    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-a', 'Terminal', path]);
      } else if (Platform.isWindows) {
        final sanitized = path.replaceAll('"', r'\"');
        await Process.run('cmd', [
          '/c',
          'start',
          'cmd',
          '/k',
          'cd',
          '/d',
          '"$sanitized"',
        ]);
      } else if (Platform.isLinux) {
        final terminal = await _findLinuxTerminal();
        if (terminal != null) {
          final args = _linuxTerminalArguments(terminal, path);
          await Process.start(terminal, args);
        } else {
          await _fallbackOpen(path, null);
        }
      } else {
        await _fallbackOpen(path, null);
      }
    } catch (e) {
      print('Error opening terminal: $e');
    }
  }

  /// Opens the project using a specific [toolId], falling back when needed.
  Future<void> openWith(
    Project project,
    ToolId toolId, {
    ToolId? defaultToolId,
    List<Tool> installedTools = const [],
  }) async {
    try {
      Tool? tool;
      try {
        tool = installedTools.firstWhere((t) => t.id == toolId);
      } catch (_) {
        tool = await _discoveryService.discoverTool(toolId);
      }

      if (tool.isInstalled && tool.path != null) {
        await _discoveryService.launchTool(tool, targetPath: project.path);
        final updated = project.copyWith(
          lastOpened: DateTime.now(),
          lastUsedToolId: tool.id,
        );
        await _repository.updateProject(updated);
        return;
      }

      await _fallbackOpen(project.path, toolId);
      final updated = project.copyWith(
        lastOpened: DateTime.now(),
        lastUsedToolId: toolId,
      );
      await _repository.updateProject(updated);
    } catch (e) {
      print('Error opening with $toolId: $e');
    }
  }

  Future<_ResolvedTool?> _pickToolForProject(
    Project project, {
    ToolId? defaultToolId,
    List<Tool> installedTools = const [],
  }) async {
    Tool? candidate;

    if (project.lastUsedToolId != null) {
      try {
        candidate = installedTools.firstWhere(
          (t) => t.id == project.lastUsedToolId,
        );
      } catch (_) {
        candidate = await _discoveryService.discoverTool(project.lastUsedToolId!);
      }

      if ((!candidate.isInstalled || candidate.path == null)) {
        candidate = null;
      }
    }

    if (candidate == null && defaultToolId != null) {
      final fallback = await _discoveryService.discoverTool(defaultToolId);
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

  Future<void> _fallbackOpen(String path, ToolId? toolId) async {
    String command = toolId?.name ?? 'open';
    List<String> args = [path];

    switch (toolId) {
      case ToolId.vscode:
        command = 'code';
        break;
      case ToolId.antigravity:
        command = 'antigravity';
        break;
      case ToolId.cursor:
        command = 'cursor';
        break;
      case ToolId.intellij:
        command = 'idea';
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
      default:
        break;
    }

    await Process.run(command, args);
  }

  Future<String?> _findLinuxTerminal() async {
    final envTerminal = Platform.environment['TERMINAL'];
    if (envTerminal != null && await _isCommandAvailable(envTerminal)) {
      return envTerminal;
    }

    for (final candidate in _linuxTerminalCandidates) {
      if (await _isCommandAvailable(candidate)) {
        return candidate;
      }
    }

    return null;
  }

  List<String> _linuxTerminalArguments(String terminal, String path) {
    final escapedPath = path.replaceAll('"', r'\"');
    switch (terminal) {
      case 'konsole':
        return ['--workdir', path];
      case 'kitty':
        return ['--directory', path];
      case 'xterm':
      case 'urxvt':
        return ['-e', 'bash', '-lc', 'cd "$escapedPath" && exec bash'];
      default:
        return ['--working-directory', path];
    }
  }

  Future<bool> _isCommandAvailable(String command) async {
    try {
      final result = await Process.run('which', [command]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

class _ResolvedTool {
  final Tool tool;

  _ResolvedTool(this.tool);
}

const _linuxTerminalCandidates = [
  'gnome-terminal',
  'konsole',
  'xfce4-terminal',
  'tilix',
  'lxterminal',
  'terminator',
  'alacritty',
  'kitty',
  'xterm',
  'urxvt',
];
