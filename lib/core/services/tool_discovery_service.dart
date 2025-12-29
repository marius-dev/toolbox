import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/models/tool.dart';
import 'app_icon_resolver.dart';

class _JetBrainsProduct {
  final String name;
  final List<String> macAppNames;
  final List<String> windowsExecutableNames;
  final List<String> linuxLaunchers;
  final String command;
  final List<String> commandAliases;

  const _JetBrainsProduct({
    required this.name,
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
    macAppNames: ['WebStorm'],
    windowsExecutableNames: ['webstorm64.exe'],
    linuxLaunchers: ['webstorm.sh', 'webstorm'],
    command: 'webstorm',
  ),
  ToolId.phpstorm: _JetBrainsProduct(
    name: 'PhpStorm',
    macAppNames: ['PhpStorm'],
    windowsExecutableNames: ['phpstorm64.exe'],
    linuxLaunchers: ['phpstorm.sh', 'phpstorm'],
    command: 'phpstorm',
    commandAliases: ['pstorm'],
  ),
  ToolId.pycharm: _JetBrainsProduct(
    name: 'PyCharm',
    macAppNames: ['PyCharm', 'PyCharm CE'],
    windowsExecutableNames: ['pycharm64.exe'],
    linuxLaunchers: ['pycharm.sh', 'pycharm', 'charm.sh', 'charm'],
    command: 'pycharm',
    commandAliases: ['charm'],
  ),
  ToolId.clion: _JetBrainsProduct(
    name: 'CLion',
    macAppNames: ['CLion'],
    windowsExecutableNames: ['clion64.exe'],
    linuxLaunchers: ['clion.sh', 'clion'],
    command: 'clion',
  ),
  ToolId.goland: _JetBrainsProduct(
    name: 'GoLand',
    macAppNames: ['GoLand'],
    windowsExecutableNames: ['goland64.exe'],
    linuxLaunchers: ['goland.sh', 'goland'],
    command: 'goland',
  ),
  ToolId.datagrip: _JetBrainsProduct(
    name: 'DataGrip',
    macAppNames: ['DataGrip'],
    windowsExecutableNames: ['datagrip64.exe'],
    linuxLaunchers: ['datagrip.sh', 'datagrip'],
    command: 'datagrip',
  ),
  ToolId.rider: _JetBrainsProduct(
    name: 'Rider',
    macAppNames: ['Rider'],
    windowsExecutableNames: ['rider64.exe'],
    linuxLaunchers: ['rider.sh', 'rider'],
    command: 'rider',
  ),
  ToolId.rubymine: _JetBrainsProduct(
    name: 'RubyMine',
    macAppNames: ['RubyMine'],
    windowsExecutableNames: ['rubymine64.exe'],
    linuxLaunchers: ['rubymine.sh', 'rubymine'],
    command: 'rubymine',
  ),
  ToolId.appcode: _JetBrainsProduct(
    name: 'AppCode',
    macAppNames: ['AppCode'],
    windowsExecutableNames: ['appcode64.exe'],
    linuxLaunchers: ['appcode.sh', 'appcode'],
    command: 'appcode',
  ),
  ToolId.fleet: _JetBrainsProduct(
    name: 'Fleet',
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
      case ToolId.antigravity:
        return _vscodeForkPaths(
          macAppNames: const ['Antigravity'],
          windowsRelativeExePaths: const ['Antigravity Antigravity.exe'],
          linuxAbsolutePaths: const [
            '/opt/antigravity-idea/antigravity',
            '/usr/local/bin/antigravity',
          ],
          linuxHomeRelativePaths: const [
            '.local/share/antigravity-idea/antigravity',
          ],
          macSearchKeywords: const ['antigravity'],
          windowsSearchKeywords: const ['antigravity'],
        );
      case ToolId.cursor:
        return _vscodeForkPaths(
          macAppNames: const ['Cursor', 'Cursor Beta'],
          windowsRelativeExePaths: const [
            'Cursor/Cursor.exe',
            'Cursor Beta/Cursor Beta.exe',
          ],
          linuxAbsolutePaths: const [
            '/opt/cursor/cursor',
            '/usr/local/bin/cursor',
            '/snap/bin/cursor',
          ],
          linuxHomeRelativePaths: const [
            '.local/share/cursor/cursor',
            '.local/share/Cursor/cursor',
          ],
          macSearchKeywords: const ['cursor'],
          windowsSearchKeywords: const ['cursor'],
        );
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
      case ToolId.antigravity:
        return ['antigravity', 'antigravity'];
      case ToolId.cursor:
        return ['cursor'];
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

  List<String> _vscodeForkPaths({
    required List<String> macAppNames,
    required List<String> windowsRelativeExePaths,
    List<String> linuxAbsolutePaths = const [],
    List<String> linuxHomeRelativePaths = const [],
    List<String> macSearchKeywords = const [],
    List<String> windowsSearchKeywords = const [],
  }) {
    final paths = LinkedHashSet<String>();
    final home = Platform.environment['HOME'];

    for (final appName in macAppNames) {
      final normalized = appName.toLowerCase().endsWith('.app')
          ? appName
          : '$appName.app';
      paths.add('/Applications/$normalized');
      if (home != null) {
        paths.add('$home/Applications/$normalized');
      }
    }

    if (macSearchKeywords.isNotEmpty) {
      paths.addAll(_searchMacApplicationsByKeyword(macSearchKeywords));
    }

    final programDirs = {
      Platform.environment['ProgramFiles'],
      Platform.environment['ProgramFiles(x86)'],
    }.whereType<String>();
    final localAppData = Platform.environment['LOCALAPPDATA'];
    final userProfile = Platform.environment['USERPROFILE'];

    final windowsBases = [
      ...programDirs,
      if (localAppData != null) '$localAppData/Programs',
      if (userProfile != null) '$userProfile/AppData/Local/Programs',
    ];

    for (final base in windowsBases) {
      for (final relative in windowsRelativeExePaths) {
        paths.add('$base/$relative');
      }
    }

    if (windowsSearchKeywords.isNotEmpty) {
      paths.addAll(
        _searchWindowsExecutablesByKeyword(windowsBases, windowsSearchKeywords),
      );
    }

    paths.addAll(linuxAbsolutePaths);
    if (home != null) {
      for (final relative in linuxHomeRelativePaths) {
        paths.add('$home/$relative');
      }
    }

    return paths.toList();
  }

  List<String> _searchMacApplicationsByKeyword(List<String> keywords) {
    if (keywords.isEmpty) return const [];
    final results = LinkedHashSet<String>();
    final home = Platform.environment['HOME'];
    final roots = ['/Applications', if (home != null) '$home/Applications'];
    final lowerKeywords = keywords
        .map((keyword) => keyword.toLowerCase())
        .toList();

    for (final root in roots) {
      if (root.isEmpty) continue;
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is! Directory) continue;
        final name = entity.uri.pathSegments.last.toLowerCase();
        if (!name.endsWith('.app')) continue;
        final normalized = name.substring(0, name.length - 4);
        if (lowerKeywords.any((keyword) => normalized.contains(keyword))) {
          results.add(entity.path);
        }
      }
    }

    return results.toList();
  }

  List<String> _searchWindowsExecutablesByKeyword(
    Iterable<String> directories,
    List<String> keywords,
  ) {
    if (keywords.isEmpty) return const [];
    final results = LinkedHashSet<String>();
    final lowerKeywords = keywords
        .map((keyword) => keyword.toLowerCase())
        .toList();

    for (final base in directories) {
      if (base.isEmpty) continue;
      final dir = Directory(base);
      if (!dir.existsSync()) continue;

      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is File) {
          final lowerPath = entity.path.toLowerCase();
          if (lowerPath.endsWith('.exe') &&
              lowerKeywords.any((keyword) => lowerPath.contains(keyword))) {
            results.add(entity.path);
          }
          continue;
        }
        if (entity is! Directory) continue;
        final name = entity.uri.pathSegments.last.toLowerCase();
        if (!lowerKeywords.any((keyword) => name.contains(keyword))) continue;
        results.addAll(_collectWindowsExecutables(entity));
        final binDir = Directory('${entity.path}${Platform.pathSeparator}bin');
        if (binDir.existsSync()) {
          results.addAll(_collectWindowsExecutables(binDir));
        }
      }
    }

    return results.toList();
  }

  List<String> _collectWindowsExecutables(Directory directory) {
    if (!directory.existsSync()) return const [];
    final executables = LinkedHashSet<String>();
    for (final entry in directory.listSync(followLinks: false)) {
      if (entry is File && entry.path.toLowerCase().endsWith('.exe')) {
        executables.add(entry.path);
      }
    }
    return executables.toList();
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
      case ToolId.antigravity:
        return 'Antigravity';
      case ToolId.cursor:
        return 'Cursor';
      case ToolId.vscode:
        return 'VS Code';
      default:
        return id.name;
    }
  }
}
