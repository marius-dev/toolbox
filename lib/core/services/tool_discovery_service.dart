import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/models/tool.dart';
import 'app_icon_resolver.dart';

class _JetBrainsProduct {
  final String name;
  final String description;
  final List<String> macAppNames;
  final List<String> windowsExecutableNames;
  final List<String> linuxLaunchers;
  final String command;
  final List<String> commandAliases;

  const _JetBrainsProduct({
    required this.name,
    required this.description,
    required this.macAppNames,
    required this.windowsExecutableNames,
    required this.linuxLaunchers,
    required this.command,
    this.commandAliases = const [],
  });

  List<String> get allCommands => [command, ...commandAliases];
}

const Map<ToolId, _JetBrainsProduct> _jetBrainsProducts = {
  ToolId.intellij: _JetBrainsProduct(
    name: 'IntelliJ IDEA',
    description: 'JetBrains IDE for polyglot projects',
    macAppNames: [
      'IntelliJ IDEA',
      'IntelliJ IDEA CE',
      'IntelliJ IDEA Ultimate',
    ],
    windowsExecutableNames: ['idea64.exe'],
    linuxLaunchers: ['idea.sh', 'idea'],
    command: 'idea',
  ),
  ToolId.webstorm: _JetBrainsProduct(
    name: 'WebStorm',
    description: 'JavaScript and TypeScript IDE',
    macAppNames: ['WebStorm'],
    windowsExecutableNames: ['webstorm64.exe'],
    linuxLaunchers: ['webstorm.sh', 'webstorm'],
    command: 'webstorm',
  ),
  ToolId.phpstorm: _JetBrainsProduct(
    name: 'PhpStorm',
    description: 'PHP and web development IDE',
    macAppNames: ['PhpStorm'],
    windowsExecutableNames: ['phpstorm64.exe'],
    linuxLaunchers: ['phpstorm.sh', 'phpstorm'],
    command: 'phpstorm',
    commandAliases: ['pstorm'],
  ),
  ToolId.pycharm: _JetBrainsProduct(
    name: 'PyCharm',
    description: 'Python IDE by JetBrains',
    macAppNames: ['PyCharm', 'PyCharm CE'],
    windowsExecutableNames: ['pycharm64.exe'],
    linuxLaunchers: ['pycharm.sh', 'pycharm', 'charm.sh', 'charm'],
    command: 'pycharm',
    commandAliases: ['charm'],
  ),
  ToolId.clion: _JetBrainsProduct(
    name: 'CLion',
    description: 'C and C++ IDE',
    macAppNames: ['CLion'],
    windowsExecutableNames: ['clion64.exe'],
    linuxLaunchers: ['clion.sh', 'clion'],
    command: 'clion',
  ),
  ToolId.goland: _JetBrainsProduct(
    name: 'GoLand',
    description: 'Go IDE by JetBrains',
    macAppNames: ['GoLand'],
    windowsExecutableNames: ['goland64.exe'],
    linuxLaunchers: ['goland.sh', 'goland'],
    command: 'goland',
  ),
  ToolId.datagrip: _JetBrainsProduct(
    name: 'DataGrip',
    description: 'Database IDE',
    macAppNames: ['DataGrip'],
    windowsExecutableNames: ['datagrip64.exe'],
    linuxLaunchers: ['datagrip.sh', 'datagrip'],
    command: 'datagrip',
  ),
  ToolId.rider: _JetBrainsProduct(
    name: 'Rider',
    description: '.NET IDE',
    macAppNames: ['Rider'],
    windowsExecutableNames: ['rider64.exe'],
    linuxLaunchers: ['rider.sh', 'rider'],
    command: 'rider',
  ),
  ToolId.rubymine: _JetBrainsProduct(
    name: 'RubyMine',
    description: 'Ruby and Rails IDE',
    macAppNames: ['RubyMine'],
    windowsExecutableNames: ['rubymine64.exe'],
    linuxLaunchers: ['rubymine.sh', 'rubymine'],
    command: 'rubymine',
  ),
  ToolId.appcode: _JetBrainsProduct(
    name: 'AppCode',
    description: 'JetBrains IDE for iOS/macOS development',
    macAppNames: ['AppCode'],
    windowsExecutableNames: ['appcode64.exe'],
    linuxLaunchers: ['appcode.sh', 'appcode'],
    command: 'appcode',
  ),
  ToolId.fleet: _JetBrainsProduct(
    name: 'Fleet',
    description: 'Lightweight JetBrains editor',
    macAppNames: ['Fleet'],
    windowsExecutableNames: ['fleet.exe'],
    linuxLaunchers: ['fleet.sh', 'fleet'],
    command: 'fleet',
  ),
};

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
    final iconPath = detectedPath != null
        ? await AppIconResolver.instance.resolve(detectedPath)
        : null;

    return Tool(
      id: id,
      name: _displayName(id),
      description: _description(id),
      path: detectedPath,
      isInstalled: detectedPath != null,
      iconPath: iconPath,
    );
  }

  Future<String?> _detectPath(ToolId id) async {
    final candidates = _candidatePaths(id);

    for (final path in candidates) {
      if (await File(path).exists() || await Directory(path).exists()) {
        return path;
      }
    }

    for (final command in _commandNames(id)) {
      final located = await _which(command);
      if (located != null) return located;
    }

    return null;
  }

  List<String> _candidatePaths(ToolId id) {
    if (_jetBrainsProducts.containsKey(id)) {
      return _jetBrainsPaths(_jetBrainsProducts[id]!);
    }

    switch (id) {
      case ToolId.vscode:
        return _vsCodePaths();
      default:
        return const [];
    }
  }

  List<String> _jetBrainsPaths(_JetBrainsProduct product) {
    if (Platform.isMacOS) {
      return _jetBrainsMacPaths(product);
    }

    if (Platform.isWindows) {
      return _jetBrainsWindowsPaths(product);
    }

    return _jetBrainsLinuxPaths(product);
  }

  List<String> _jetBrainsMacPaths(_JetBrainsProduct product) {
    final paths = <String>[];
    final home = Platform.environment['HOME'];

    for (final appName in product.macAppNames) {
      paths.add('/Applications/$appName.app');
      if (home != null) {
        paths.add('$home/Applications/$appName.app');
        paths.add('$home/Applications/JetBrains Toolbox/$appName.app');
      }
    }

    if (home != null) {
      paths.addAll(
        _searchToolboxInstalls(
          '$home/Library/Application Support/JetBrains/Toolbox/apps',
          targets: product.macAppNames.map((name) => '$name.app').toList(),
          matchDirectories: true,
        ),
      );
      for (final command in product.allCommands) {
        paths.add(
          '$home/Library/Application Support/JetBrains/Toolbox/scripts/$command',
        );
      }
    }

    for (final command in product.allCommands) {
      paths.addAll(_commandLauncherCandidates(command));
    }

    return paths;
  }

  List<String> _jetBrainsWindowsPaths(_JetBrainsProduct product) {
    final paths = <String>[];
    final programDirs = {
      Platform.environment['ProgramFiles'],
      Platform.environment['ProgramFiles(x86)'],
    }.whereType<String>();

    for (final base in programDirs) {
      final jetBrainsDir = Directory('$base/JetBrains');
      if (!jetBrainsDir.existsSync()) continue;

      for (final install in jetBrainsDir.listSync().whereType<Directory>()) {
        final dirName = install.path
            .split(Platform.pathSeparator)
            .last
            .toLowerCase();
        final matchesProduct = product.command.toLowerCase();

        if (dirName.contains(matchesProduct)) {
          for (final exeName in product.windowsExecutableNames) {
            paths.add('${install.path}/bin/$exeName');
          }
        }
      }
    }

    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      for (final command in product.allCommands) {
        paths.add('$localAppData/JetBrains/Toolbox/scripts/$command.bat');
      }
      for (final exeName in product.windowsExecutableNames) {
        paths.addAll(
          _searchToolboxInstalls(
            '$localAppData/JetBrains/Toolbox/apps',
            targets: [exeName],
          ),
        );
      }
    }

    return paths;
  }

  List<String> _jetBrainsLinuxPaths(_JetBrainsProduct product) {
    final paths = <String>[];
    final home = Platform.environment['HOME'];

    for (final launcher in product.linuxLaunchers) {
      paths.add('/opt/JetBrains/${product.command}/bin/$launcher');
    }

    final optDir = Directory('/opt');
    if (optDir.existsSync()) {
      for (final install in optDir.listSync().whereType<Directory>()) {
        final dirName = install.path
            .split(Platform.pathSeparator)
            .last
            .toLowerCase();
        if (dirName.contains(product.command.toLowerCase())) {
          for (final launcher in product.linuxLaunchers) {
            paths.add('${install.path}/bin/$launcher');
          }
        }
      }
    }

    for (final command in product.allCommands) {
      paths.addAll(_commandLauncherCandidates(command));
    }

    if (home != null) {
      for (final command in product.allCommands) {
        paths.add('$home/.local/share/JetBrains/Toolbox/scripts/$command');
      }

      paths.addAll(
        _searchToolboxInstalls(
          '$home/.local/share/JetBrains/Toolbox/apps',
          targets: product.linuxLaunchers,
        ),
      );
    }

    return paths;
  }

  List<String> _searchToolboxInstalls(
    String basePath, {
    required List<String> targets,
    bool matchDirectories = false,
  }) {
    final results = <String>[];
    final dir = Directory(basePath);

    if (!dir.existsSync()) return results;

    final lowerTargets = targets.map((t) => t.toLowerCase()).toList();

    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      final name = entity.path.split(Platform.pathSeparator).last.toLowerCase();
      final isMatch = lowerTargets.contains(name);

      if (isMatch) {
        if (matchDirectories && entity is Directory) {
          results.add(entity.path);
        } else if (!matchDirectories && entity is File) {
          results.add(entity.path);
        }
      }
    }

    return results;
  }

  List<String> _commandLauncherCandidates(String command) {
    if (Platform.isWindows) return const [];

    return [
      '/usr/local/bin/$command',
      '/opt/homebrew/bin/$command',
      '/usr/bin/$command',
      '/snap/bin/$command',
    ];
  }

  List<String> _commandNames(ToolId id) {
    if (_jetBrainsProducts.containsKey(id)) {
      return _jetBrainsProducts[id]!.allCommands;
    }

    switch (id) {
      case ToolId.vscode:
        return ['code'];
      default:
        return const [];
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

    return const ['/usr/bin/code', '/usr/local/bin/code', '/snap/bin/code'];
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
    if (_jetBrainsProducts.containsKey(id)) {
      return _jetBrainsProducts[id]!.name;
    }

    switch (id) {
      case ToolId.vscode:
        return 'VS Code';
      default:
        return id.name;
    }
  }

  String _description(ToolId id) {
    if (_jetBrainsProducts.containsKey(id)) {
      return _jetBrainsProducts[id]!.description;
    }

    switch (id) {
      case ToolId.vscode:
        return 'Lightweight editor tuned for code';
      default:
        return '';
    }
  }
}
