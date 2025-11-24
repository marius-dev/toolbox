import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/models/tool.dart';

class ToolDiscoveryService {
  ToolDiscoveryService._internal();

  static final ToolDiscoveryService instance = ToolDiscoveryService._internal();

  final Map<ToolId, Tool> _cache = {};

  Future<List<Tool>> discoverTools({bool forceRefresh = false}) async {
    if (_cache.isNotEmpty && !forceRefresh) {
      return _cache.values.toList();
    }

    _cache.clear();
    for (final id in ToolId.values) {
      final tool = await _probeTool(id);
      _cache[id] = tool;
    }
    return _cache.values.toList();
  }

  Future<Tool> discoverTool(ToolId id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.containsKey(id)) {
      return _cache[id]!;
    }

    final tool = await _probeTool(id);
    _cache[id] = tool;
    return tool;
  }

  Future<void> launchTool(Tool tool, {String? targetPath}) async {
    if (!tool.isInstalled || tool.path == null) return;

    try {
      String command = tool.path!;
      final args = <String>[];

      if (Platform.isMacOS && command.endsWith('.app')) {
        command = 'open';
        args.addAll(['-a', tool.path!]);
        if (targetPath != null) {
          args.add(targetPath);
        }
      } else {
        if (targetPath != null) {
          args.add(targetPath);
        }
      }

      await Process.run(command, args);
    } catch (e) {
      debugPrint('Error launching tool ${tool.name}: $e');
    }
  }

  Future<Tool> _probeTool(ToolId id) async {
    final detectedPath = await _detectPath(id);

    return Tool(
      id: id,
      name: _displayName(id),
      description: _description(id),
      path: detectedPath,
      isInstalled: detectedPath != null,
    );
  }

  Future<String?> _detectPath(ToolId id) async {
    for (final path in _candidatePaths(id)) {
      if (await File(path).exists() || await Directory(path).exists()) {
        return path;
      }
    }

    final fallbackCommand = _commandName(id);
    if (fallbackCommand != null) {
      final located = await _which(fallbackCommand);
      if (located != null) return located;
    }

    return null;
  }

  List<String> _candidatePaths(ToolId id) {
    switch (id) {
      case ToolId.vscode:
        return _vsCodePaths();
      case ToolId.intellij:
        return _intellijPaths();
      case ToolId.preview:
        return _previewPaths();
    }
  }

  List<String> _vsCodePaths() {
    if (Platform.isMacOS) {
      return const [
        '/Applications/Visual Studio Code.app',
        '/Applications/Visual Studio Code - Insiders.app',
        '/usr/local/bin/code',
        '/opt/homebrew/bin/code',
      ];
    }

    if (Platform.isWindows) {
      final programFiles =
          Platform.environment['ProgramFiles'] ?? 'C:\\Program Files';
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users';
      return [
        '$programFiles/Microsoft VS Code/Code.exe',
        '$userProfile/AppData/Local/Programs/Microsoft VS Code/Code.exe',
      ];
    }

    return const [
      '/usr/bin/code',
      '/usr/local/bin/code',
      '/snap/bin/code',
    ];
  }

  List<String> _intellijPaths() {
    if (Platform.isMacOS) {
      return const [
        '/Applications/IntelliJ IDEA.app',
        '/Applications/IntelliJ IDEA CE.app',
        '/Applications/IntelliJ IDEA Ultimate.app',
        '/usr/local/bin/idea',
        '/opt/homebrew/bin/idea',
      ];
    }

    if (Platform.isWindows) {
      final programFiles =
          Platform.environment['ProgramFiles'] ?? 'C:\\Program Files';
      return [
        '$programFiles/JetBrains/IntelliJ IDEA Community Edition/bin/idea64.exe',
        '$programFiles/JetBrains/IntelliJ IDEA Ultimate/bin/idea64.exe',
      ];
    }

    return const [
      '/usr/bin/idea',
      '/usr/local/bin/idea',
      '/snap/bin/intellij-idea-community',
    ];
  }

  List<String> _previewPaths() {
    if (Platform.isMacOS) {
      return const [
        '/System/Applications/Preview.app',
        '/Applications/Preview.app',
      ];
    }

    return const [];
  }

  String? _commandName(ToolId id) {
    switch (id) {
      case ToolId.vscode:
        return 'code';
      case ToolId.intellij:
        return 'idea';
      case ToolId.preview:
        return null;
    }
  }

  Future<String?> _which(String command) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        Platform.isWindows ? [command] : command.split(' '),
      );

      if (result.exitCode == 0) {
        final output = result.stdout?.toString().trim() ?? '';
        if (output.isNotEmpty) {
          return output.split('\n').first.trim();
        }
      }
    } catch (e) {
      debugPrint('Error running which for $command: $e');
    }
    return null;
  }

  String _displayName(ToolId id) {
    switch (id) {
      case ToolId.vscode:
        return 'VS Code';
      case ToolId.intellij:
        return 'IntelliJ IDEA';
      case ToolId.preview:
        return 'Preview';
    }
  }

  String _description(ToolId id) {
    switch (id) {
      case ToolId.vscode:
        return 'Lightweight editor tuned for code';
      case ToolId.intellij:
        return 'JetBrains IDE for polyglot projects';
      case ToolId.preview:
        return 'macOS document and image viewer';
    }
  }
}
