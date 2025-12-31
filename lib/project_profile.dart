// project_profile.dart
//
// Usage:
//   dart run project_profile.dart /path/to/project > profile.json
//
// Optional flags:
//   --max-depth=25           Limit directory traversal depth (default 25)
//   --pretty                Pretty-print JSON
//   --no-git                Skip git interrogation
//   --follow-links          Follow symlinks (default false)
//   --respect-gitignore     Apply a lightweight .gitignore matcher (default false)
//
// Notes:
// - This is a pragmatic “project fingerprint” scanner: file inventory + markers + process/docs + git.
// - .gitignore support here is intentionally lightweight (common patterns + simple globs), not a full spec.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty || args.first.startsWith('-')) {
    stderr.writeln(
      'Usage: dart run project_profile.dart <path> [--pretty] [--no-git] '
      '[--max-depth=N] [--follow-links] [--respect-gitignore]',
    );
    exit(2);
  }

  final targetPath = args.first;
  final opts = _parseArgs(args.skip(1).toList());

  final root = Directory(targetPath);
  if (!await root.exists()) {
    stderr.writeln('Path does not exist: $targetPath');
    exit(2);
  }

  final scanner = ProjectScanner(
    maxDepth: opts.maxDepth,
    followLinks: opts.followLinks,
    noGit: opts.noGit,
    pretty: opts.pretty,
    respectGitignore: opts.respectGitignore,
  );

  final profile = await scanner.scan(root);
  final jsonStr = opts.pretty
      ? const JsonEncoder.withIndent('  ').convert(profile)
      : jsonEncode(profile);

  stdout.writeln(jsonStr);
}

class ScanOptions {
  final int maxDepth;
  final bool pretty;
  final bool noGit;
  final bool followLinks;
  final bool respectGitignore;

  ScanOptions({
    required this.maxDepth,
    required this.pretty,
    required this.noGit,
    required this.followLinks,
    required this.respectGitignore,
  });
}

ScanOptions _parseArgs(List<String> args) {
  var maxDepth = 25;
  var pretty = false;
  var noGit = false;
  var followLinks = false;
  var respectGitignore = false;

  for (final a in args) {
    if (a == '--pretty')
      pretty = true;
    else if (a == '--no-git')
      noGit = true;
    else if (a == '--follow-links')
      followLinks = true;
    else if (a == '--respect-gitignore')
      respectGitignore = true;
    else if (a.startsWith('--max-depth=')) {
      maxDepth = int.tryParse(a.split('=').last) ?? maxDepth;
    }
  }

  return ScanOptions(
    maxDepth: maxDepth,
    pretty: pretty,
    noGit: noGit,
    followLinks: followLinks,
    respectGitignore: respectGitignore,
  );
}

class ProjectScanner {
  final int maxDepth;
  final bool followLinks;
  final bool noGit;
  final bool pretty;
  final bool respectGitignore;

  ProjectScanner({
    required this.maxDepth,
    required this.followLinks,
    required this.noGit,
    required this.pretty,
    required this.respectGitignore,
  });

  static final _defaultSkipDirNames = <String>{
    '.git',
    'node_modules',
    'vendor',
    'dist',
    'build',
    '.idea',
    '.vscode',
    '.dart_tool',
    '.gradle',
    '.mvn',
    'target',
    'out',
    '.terraform',
    '.next',
    '.nuxt',
    '.cache',
    '.pytest_cache',
    '__pycache__',
    '.venv',
    'Pods',
    'DerivedData',
  };

  static final _secretsRiskMatchers = <RegExp>[
    RegExp(r'\.env(\..+)?$'),
    RegExp(r'id_rsa$'),
    RegExp(r'\.pem$'),
    RegExp(r'\.p12$'),
    RegExp(r'credentials\.json$'),
    RegExp(r'secrets?(\..+)?$'),
  ];

  static final _lockfileNames = <String>[
    'package-lock.json',
    'pnpm-lock.yaml',
    'yarn.lock',
    'composer.lock',
    'Pipfile.lock',
    'poetry.lock',
    'uv.lock',
    'Gemfile.lock',
    'Cargo.lock',
    'go.sum',
  ];

  static final _ciMarkers = <String>[
    '.github/workflows', // dir
    '.gitlab-ci.yml',
    'azure-pipelines.yml',
    'Jenkinsfile',
    '.circleci', // dir
    'buildkite.yml',
    '.drone.yml',
  ];

  static final _testMarkers = <String>[
    'test',
    'tests',
    '__tests__',
    'spec',
    'specs',
    'cypress',
    'playwright',
  ];

  static final _lintMarkers = <String>[
    '.eslintrc',
    '.eslintrc.json',
    '.eslintrc.js',
    '.eslintrc.cjs',
    '.prettierrc',
    '.prettierrc.json',
    '.prettierrc.js',
    'phpstan.neon',
    'phpstan.neon.dist',
    'psalm.xml',
    '.golangci.yml',
    'ruff.toml',
    '.ruff.toml',
    'pyproject.toml',
    'pylintrc',
    '.editorconfig',
  ];

  static final _docNames = <String>[
    'README',
    'README.md',
    'README.rst',
    'CHANGELOG',
    'CHANGELOG.md',
    'CONTRIBUTING',
    'CONTRIBUTING.md',
    'LICENSE',
    'LICENSE.md',
    'ARCHITECTURE.md',
    'adr', // dir often
    'docs', // dir often
  ];

  Future<Map<String, dynamic>> scan(Directory rootDir) async {
    final rootPath = rootDir.absolute.path;
    final basename = rootPath
        .split(Platform.pathSeparator)
        .where((s) => s.isNotEmpty)
        .last;

    final nowIso = DateTime.now().toUtc().toIso8601String();

    // Depth: count separators (rough but useful)
    final depth = rootPath
        .split(Platform.pathSeparator)
        .where((p) => p.isNotEmpty)
        .length;

    final identity = <String, dynamic>{
      'path': {
        'absolute': rootPath,
        'basename': basename,
        'depth': depth,
        'derived_name': _slugify(basename),
      },
      'timestamps': {'modified_at': await _modifiedAtIso(rootDir)},
    };

    final gitignore = respectGitignore
        ? await _loadGitignore(rootDir)
        : const _Gitignore.empty();

    // Inventory collectors
    var totalFiles = 0;
    var totalDirs = 0;
    var totalSizeBytes = 0;
    final extCounts = <String, int>{};
    final topLevelEntries = <String>[];
    final largeFiles = <_SizedPath>[];
    var hiddenEntriesCount = 0;

    final dependencyDirsPresent = <String>{};
    final secretsRiskMarkers = <String>{};
    final lockfilesPresent = <String>{};

    // Marker detection / fingerprints
    final docs = _DocsState();
    final process = _ProcessState();
    final stack = _StackState();

    List<FileSystemEntity> rootList = const [];
    try {
      rootList = await rootDir.list(followLinks: followLinks).toList();
    } catch (_) {}
    for (final e in rootList) {
      final name = _nameOf(e.path);
      topLevelEntries.add(name);
    }

    Future<void> walk(Directory dir, int depthLeft) async {
      if (depthLeft < 0) return;

      Stream<FileSystemEntity> entries;
      try {
        entries = dir.list(followLinks: followLinks);
      } catch (_) {
        return;
      }

      try {
        await for (final entity in entries) {
          try {
            final rel = _relPath(rootPath, entity.path);
            final name = _nameOf(entity.path);

            // Count hidden entries
            if (name.startsWith('.')) hiddenEntriesCount++;

            // Skip common heavy dirs
            if (entity is Directory && _defaultSkipDirNames.contains(name)) {
              // still record that they exist (hygiene)
              dependencyDirsPresent.add(name);
              continue;
            }

            // Respect gitignore (lightweight)
            if (respectGitignore &&
                gitignore.isIgnored(rel, isDir: entity is Directory)) {
              continue;
            }

            if (entity is Directory) {
              totalDirs++;
              // Marker dirs
              _updateMarkersForDir(name, docs, process, stack);

              await walk(entity, depthLeft - 1);
            } else if (entity is File) {
              totalFiles++;
              FileStat? stat;
              try {
                stat = await entity.stat();
                totalSizeBytes += stat.size;
              } catch (_) {}

              // Extension histogram
              final ext = _extOf(name);
              extCounts[ext] = (extCounts[ext] ?? 0) + 1;

              // Top large files (keep top 15)
              if (stat != null) {
                _trackLargeFile(largeFiles, _SizedPath(rel, stat.size), keep: 15);
              }

              // Hygiene markers
              if (_lockfileNames.contains(name)) lockfilesPresent.add(name);
              if (name == '.gitignore') {
                // captured later too
              }
              for (final r in _secretsRiskMatchers) {
                if (r.hasMatch(name)) {
                  secretsRiskMarkers.add(rel);
                  break;
                }
              }

              // Marker files (docs/process/stack)
              _updateMarkersForFile(name, rel, docs, process, stack);
            } else {
              // Link, socket, etc. ignore for now
            }
          } catch (_) {
            continue;
          }
        }
      } catch (_) {}
    }

    await walk(rootDir, maxDepth);

    // Post-process stack inference
    stack.inferFromInventory(extCounts);

    final inventory = <String, dynamic>{
      'total_files': totalFiles,
      'total_dirs': totalDirs,
      'total_size_bytes': totalSizeBytes,
      'file_extensions': _sortedMapByValueDesc(extCounts),
      'top_level_entries': topLevelEntries..sort(),
      'large_files': largeFiles
          .map((e) => {'path': e.path, 'size_bytes': e.sizeBytes})
          .toList(),
      'hidden_entries_count': hiddenEntriesCount,
      'ignored_by_default_candidates': dependencyDirsPresent.toList()..sort(),
    };

    final docsJson = docs.toJson();
    final processJson = process.toJson();
    final stackJson = stack.toJson();

    var gitignorePresent = topLevelEntries.contains('.gitignore');
    if (!gitignorePresent) {
      try {
        gitignorePresent = await File(
          '${rootPath}${Platform.pathSeparator}.gitignore',
        ).exists();
      } catch (_) {
        gitignorePresent = false;
      }
    }

    final hygiene = <String, dynamic>{
      'gitignore_present': gitignorePresent,
      'lockfiles_present': lockfilesPresent.toList()..sort(),
      'dependency_dirs_present': dependencyDirsPresent.toList()..sort(),
      'secrets_risk_markers': secretsRiskMarkers.toList()..sort(),
    };

    final gitJson = noGit ? _emptyGit() : await _scanGit(rootDir);

    final classification = _classify(
      rootBasename: basename,
      topLevelEntries: topLevelEntries,
      stack: stack,
      docs: docs,
      process: process,
      inventory: inventory,
    );

    return <String, dynamic>{
      'identity': identity,
      'inventory': inventory,
      'stack': stackJson,
      'docs': docsJson,
      'process': processJson,
      'git': gitJson,
      'hygiene': hygiene,
      'class': classification,
      'collection': {'scanned_at': nowIso, 'scanner_version': '1.0.0'},
    };
  }

  Future<Map<String, dynamic>> _scanGit(Directory rootDir) async {
    try {
      final rootPath = rootDir.absolute.path;

      // Fast check: does "git -C path rev-parse --is-inside-work-tree" succeed?
      final inside = await _runGit(rootPath, [
        'rev-parse',
        '--is-inside-work-tree',
      ]);
      final insideOut = inside.stdout.toString().trim();
      if (inside.exitCode != 0 || insideOut != 'true') {
        return _emptyGit(isRepo: false);
      }

      final repoRoot = await _runGit(rootPath, ['rev-parse', '--show-toplevel']);
      final headCommit = await _runGit(rootPath, ['rev-parse', 'HEAD']);
      final branch = await _runGit(rootPath, [
        'rev-parse',
        '--abbrev-ref',
        'HEAD',
      ]);
      final repoRootOut = repoRoot.stdout.toString().trim();
      final headCommitOut = headCommit.stdout.toString().trim();
      final branchOut = branch.stdout.toString().trim();

      // Remotes
      final remotesRes = await _runGit(rootPath, ['remote', '-v']);
      final remotes = <String, String>{};
      if (remotesRes.exitCode == 0) {
        // Parse lines like: origin  https://... (fetch)
        final remotesOut = remotesRes.stdout.toString();
        final lines = remotesOut
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty);
        for (final line in lines) {
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final name = parts[0];
            final url = parts[1];
            remotes.putIfAbsent(name, () => url);
          }
        }
      }

      // Last commit details (compact, script-friendly)
      final lastCommit = await _runGit(rootPath, [
        'log',
        '-1',
        '--pretty=format:%H%n%an%n%ae%n%ad%n%s',
        '--date=iso-strict',
      ]);

      Map<String, dynamic>? lastCommitJson;
      if (lastCommit.exitCode == 0) {
        final lastCommitOut = lastCommit.stdout.toString();
        final lines = lastCommitOut.split('\n');
        if (lines.length >= 5) {
          lastCommitJson = {
            'hash': lines[0].trim(),
            'author_name': lines[1].trim(),
            'author_email': lines[2].trim(),
            'date': lines[3].trim(),
            'subject': lines.sublist(4).join('\n').trim(),
          };
        }
      }

      // Status (cheap-ish)
      final status = await _runGit(rootPath, ['status', '--porcelain']);
      int? modified = 0;
      int? untracked = 0;
      bool? dirty = false;

      if (status.exitCode == 0) {
        final statusOut = status.stdout.toString();
        final lines = statusOut
            .split('\n')
            .map((l) => l.trimRight())
            .where((l) => l.isNotEmpty);
        for (final l in lines) {
          if (l.startsWith('??'))
            untracked = (untracked ?? 0) + 1;
          else
            modified = (modified ?? 0) + 1;
        }
        dirty = (modified ?? 0) + (untracked ?? 0) > 0;
      } else {
        modified = null;
        untracked = null;
        dirty = null;
      }

      // Submodules
      final submodules = <Map<String, dynamic>>[];
      if (repoRoot.exitCode == 0 && repoRootOut.isNotEmpty) {
        final gm = File('${repoRootOut}${Platform.pathSeparator}.gitmodules');
        try {
          if (await gm.exists()) {
            final text = await gm.readAsString();
            // crude parse: [submodule "name"] then path = ..., url = ...
            final blocks = text.split(RegExp(r'\[submodule "'));
            for (final b in blocks.skip(1)) {
              final nameEnd = b.indexOf('"');
              if (nameEnd <= 0) continue;
              final name = b.substring(0, nameEnd);
              final pathMatch = RegExp(r'path\s*=\s*(.+)').firstMatch(b);
              final urlMatch = RegExp(r'url\s*=\s*(.+)').firstMatch(b);
              submodules.add({
                'name': name.trim(),
                'path': pathMatch?.group(1)?.trim(),
                'url': urlMatch?.group(1)?.trim(),
              });
            }
          }
        } catch (_) {}
      }

      final defaultRemote = remotes.containsKey('origin')
          ? 'origin'
          : (remotes.keys.isNotEmpty ? remotes.keys.first : null);

      return {
        'is_repo': true,
        'repo_root': repoRoot.exitCode == 0 ? repoRootOut : null,
        'head': {
          'branch': (branch.exitCode == 0 && branchOut != 'HEAD')
              ? branchOut
              : null,
          'commit': headCommit.exitCode == 0 ? headCommitOut : null,
          'detached': (branch.exitCode == 0 && branchOut == 'HEAD'),
        },
        'remotes': remotes,
        'default_remote': defaultRemote,
        'last_commit': lastCommitJson,
        'status': {
          'is_dirty': dirty,
          'modified_count': modified,
          'untracked_count': untracked,
        },
        'submodules': submodules,
      };
    } catch (_) {
      return _emptyGit();
    }
  }

  Future<ProcessResult> _runGit(String cwd, List<String> args) async {
    try {
      return await Process.run(
        'git',
        ['-C', cwd, ...args],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
    } catch (_) {
      return ProcessResult(0, 127, '', 'git not available');
    }
  }

  Map<String, dynamic> _emptyGit({bool isRepo = false}) => {
    'is_repo': isRepo,
    'repo_root': null,
    'head': {'branch': null, 'commit': null, 'detached': null},
    'remotes': <String, String>{},
    'default_remote': null,
    'last_commit': null,
    'status': {
      'is_dirty': null,
      'modified_count': null,
      'untracked_count': null,
    },
    'submodules': <Map<String, dynamic>>[],
  };

  Future<String?> _modifiedAtIso(Directory dir) async {
    try {
      final s = await dir.stat();
      return s.modified.toUtc().toIso8601String();
    } catch (_) {
      return null;
    }
  }

  void _updateMarkersForDir(
    String name,
    _DocsState docs,
    _ProcessState process,
    _StackState stack,
  ) {
    // Docs / ADR / CI dirs
    if (name.toLowerCase() == 'docs') docs.hasArchitectureDocs = true;
    if (name.toLowerCase() == 'adr') docs.hasArchitectureDocs = true;
    if (name == '.github')
      process.ciSystems.add('github_actions?'); // refined by workflows dir
    if (name == '.circleci') {
      process.hasCi = true;
      process.ciSystems.add('circleci');
    }
    if (name == '.github') {
      // no-op; the workflows dir marker handles it
    }

    // IaC dirs
    if (name.toLowerCase() == 'helm' || name.toLowerCase() == 'charts')
      stack.kubernetesHelm = true;
    if (name.toLowerCase() == 'kustomize') stack.kubernetesKustomize = true;
    if (name.toLowerCase() == 'manifests' || name.toLowerCase() == 'k8s')
      stack.kubernetesManifests = true;
  }

  void _updateMarkersForFile(
    String name,
    String rel,
    _DocsState docs,
    _ProcessState process,
    _StackState stack,
  ) {
    final lower = name.toLowerCase();

    // Docs
    if (name == 'README' || lower.startsWith('readme')) {
      docs.hasReadme = true;
      docs.readmePaths.add(rel);
    }
    if (lower.startsWith('changelog')) docs.hasChangelog = true;
    if (lower.startsWith('contributing')) docs.hasContributing = true;
    if (lower.startsWith('license')) docs.hasLicense = true;
    if (lower == 'architecture.md') docs.hasArchitectureDocs = true;

    // CI
    if (name == '.gitlab-ci.yml') {
      process.hasCi = true;
      process.ciSystems.add('gitlab_ci');
    }
    if (name == 'azure-pipelines.yml') {
      process.hasCi = true;
      process.ciSystems.add('azure_pipelines');
    }
    if (name == 'Jenkinsfile') {
      process.hasCi = true;
      process.ciSystems.add('jenkins');
    }
    if (lower.endsWith('.yml') || lower.endsWith('.yaml')) {
      // detect GH Actions workflows by path segment
      if (rel.contains('.github/workflows/')) {
        process.hasCi = true;
        process.ciSystems.add('github_actions');
      }
    }

    // Tests (markers by common folder names are handled by inventory; here handle config files)
    if (lower == 'phpunit.xml' || lower == 'phpunit.xml.dist') {
      process.hasTests = true;
      process.testMarkers.add(name);
      stack.languages.add('php');
    }
    if (lower == 'jest.config.js' || lower == 'jest.config.ts') {
      process.hasTests = true;
      process.testMarkers.add(name);
    }
    if (lower == 'playwright.config.ts' ||
        lower == 'cypress.config.js' ||
        lower == 'cypress.config.ts') {
      process.hasTests = true;
      process.testMarkers.add(name);
    }

    // Linting / formatting
    if (_lintMarkers.contains(name)) {
      process.hasLinting = true;
      process.lintMarkers.add(name);
    }

    // Stack markers
    switch (name) {
      case 'composer.json':
        stack.packageManagers.add('composer');
        stack.runtime.add('php');
        stack.languages.add('php');
        break;
      case 'package.json':
        stack.packageManagers.add('npm');
        stack.runtime.add('node');
        stack.languages.add('javascript');
        break;
      case 'pnpm-lock.yaml':
        stack.packageManagers.add('pnpm');
        stack.runtime.add('node');
        break;
      case 'yarn.lock':
        stack.packageManagers.add('yarn');
        stack.runtime.add('node');
        break;
      case 'go.mod':
        stack.runtime.add('go');
        stack.languages.add('go');
        break;
      case 'pyproject.toml':
      case 'requirements.txt':
        stack.runtime.add('python');
        stack.languages.add('python');
        break;
      case 'pom.xml':
        stack.runtime.add('java');
        stack.languages.add('java');
        stack.buildTools.add('maven');
        break;
      case 'build.gradle':
      case 'build.gradle.kts':
        stack.runtime.add('java');
        stack.languages.add('java');
        stack.buildTools.add('gradle');
        break;
      case 'Dockerfile':
        stack.containerDockerfile = true;
        break;
      case 'docker-compose.yml':
      case 'compose.yml':
        stack.containerCompose = true;
        break;
      case 'Chart.yaml':
        stack.kubernetesHelm = true;
        break;
      case 'kustomization.yaml':
      case 'kustomization.yml':
        stack.kubernetesKustomize = true;
        break;
      default:
        break;
    }

    // Framework hints (cheap heuristics from common files)
    if (name == 'symfony.lock') stack.frameworks.add('symfony');
    if (lower == 'artisan') stack.frameworks.add('laravel');
    if (name == 'angular.json') stack.frameworks.add('angular');
    if (name == 'next.config.js' || name == 'next.config.mjs')
      stack.frameworks.add('nextjs');
    if (name == 'vite.config.js' || name == 'vite.config.ts')
      stack.buildTools.add('vite');
    if (name == 'webpack.config.js') stack.buildTools.add('webpack');
    if (name == 'tsconfig.json') {
      stack.languages.add('typescript');
      stack.buildTools.add('tsc');
    }
  }

  Map<String, dynamic> _classify({
    required String rootBasename,
    required List<String> topLevelEntries,
    required _StackState stack,
    required _DocsState docs,
    required _ProcessState process,
    required Map<String, dynamic> inventory,
  }) {
    // Type heuristics
    final hasSrc = topLevelEntries.any(
      (e) => e == 'src' || e == 'app' || e == 'lib',
    );
    final hasInfra = topLevelEntries.any(
      (e) =>
          e.toLowerCase() == 'infra' ||
          e.toLowerCase() == 'terraform' ||
          e.toLowerCase() == 'helm' ||
          e.toLowerCase() == 'charts' ||
          e.toLowerCase() == 'k8s',
    );
    final hasHelm = stack.kubernetesHelm;
    final hasDocker = stack.containerDockerfile || stack.containerCompose;

    String type = 'unknown';
    if (hasInfra || hasHelm)
      type = 'infra';
    else if (hasSrc)
      type = 'app';
    else if (topLevelEntries.contains('packages') ||
        topLevelEntries.contains('services'))
      type = 'monorepo';
    else if (topLevelEntries.contains('lib'))
      type = 'library';

    // Monorepo heuristic: many package manifests
    final extCounts = (inventory['file_extensions'] as Map)
        .cast<String, dynamic>();
    // Rough: if multiple package.json exist (we didn’t count by name), approximate:
    // if lots of JS/TS and top-level has packages/services, likely monorepo.
    final jsCount = (extCounts['.js'] ?? 0) as int;
    final tsCount = (extCounts['.ts'] ?? 0) as int;
    final isMonorepoLikely =
        topLevelEntries.contains('packages') ||
        topLevelEntries.contains('services') ||
        ((jsCount + tsCount) > 500 && topLevelEntries.contains('apps'));

    // Maturity score (simple heuristic, 0..100)
    int score = 0;
    if (docs.hasReadme) score += 20;
    if (docs.hasLicense) score += 5;
    if (docs.hasContributing) score += 5;
    if (process.hasCi) score += 20;
    if (process.hasTests) score += 20;
    if (process.hasLinting) score += 10;
    if (hasDocker) score += 10;
    if (stack.kubernetesHelm ||
        stack.kubernetesManifests ||
        stack.kubernetesKustomize)
      score += 10;
    if (score > 100) score = 100;

    final domainGuess = _domainGuessFromName(rootBasename);

    return {
      'type': type,
      'is_monorepo_likely': isMonorepoLikely,
      'maturity_score': score,
      'primary_language': stack.primaryLanguage ?? '',
      'guesses': {'domain_guess': domainGuess},
    };
  }

  String? _domainGuessFromName(String name) {
    final n = name.toLowerCase();
    const domains = [
      'auth',
      'payment',
      'billing',
      'user',
      'account',
      'search',
      'catalog',
      'order',
      'inventory',
      'shipping',
      'notification',
      'email',
      'analytics',
      'report',
      'admin',
      'gateway',
      'proxy',
      'upload',
      'media',
    ];
    for (final d in domains) {
      if (n.contains(d)) return d;
    }
    return null;
  }
}

/* ----------------------------- State structs ----------------------------- */

class _DocsState {
  bool hasReadme = false;
  final List<String> readmePaths = [];
  bool hasChangelog = false;
  bool hasContributing = false;
  bool hasLicense = false;
  bool hasArchitectureDocs = false;

  Map<String, dynamic> toJson() => {
    'has_readme': hasReadme,
    'readme_paths': readmePaths..sort(),
    'has_changelog': hasChangelog,
    'has_contributing': hasContributing,
    'has_license': hasLicense,
    'has_architecture_docs': hasArchitectureDocs,
  };
}

class _ProcessState {
  bool hasCi = false;
  final Set<String> ciSystems = {};
  bool hasTests = false;
  final Set<String> testMarkers = {};
  bool hasLinting = false;
  final Set<String> lintMarkers = {};

  Map<String, dynamic> toJson() => {
    'has_ci': hasCi,
    'ci_systems': (ciSystems.toList()..sort()),
    'has_tests': hasTests,
    'test_markers': (testMarkers.toList()..sort()),
    'has_linting': hasLinting,
    'lint_markers': (lintMarkers.toList()..sort()),
  };
}

class _StackState {
  final Set<String> languages = {};
  final Set<String> frameworks = {};
  final Set<String> packageManagers = {};
  final Set<String> buildTools = {};
  final Set<String> runtime = {};
  bool containerDockerfile = false;
  bool containerCompose = false;
  bool kubernetesHelm = false;
  bool kubernetesKustomize = false;
  bool kubernetesManifests = false;

  String? primaryLanguage;

  void inferFromInventory(Map<String, int> extCounts) {
    // Rough weighted guess (extensions + known signals)
    final weights = <String, int>{};
    void add(String lang, int w) => weights[lang] = (weights[lang] ?? 0) + w;

    // extension-based weights
    add('php', (extCounts['.php'] ?? 0));
    add('javascript', (extCounts['.js'] ?? 0));
    add('typescript', (extCounts['.ts'] ?? 0));
    add('python', (extCounts['.py'] ?? 0));
    add('go', (extCounts['.go'] ?? 0));
    add('java', (extCounts['.java'] ?? 0));
    add('csharp', (extCounts['.cs'] ?? 0));
    add('ruby', (extCounts['.rb'] ?? 0));
    add('kotlin', (extCounts['.kt'] ?? 0));
    add('swift', (extCounts['.swift'] ?? 0));

    // boost for marker-inferred languages
    for (final l in languages) add(l, 50);

    if (weights.isNotEmpty) {
      final best = weights.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      primaryLanguage = best.first.value > 0 ? best.first.key : null;
    }

    // Ensure primary language appears in languages set if known
    if (primaryLanguage != null) languages.add(primaryLanguage!);
  }

  Map<String, dynamic> toJson() => {
    'languages': (languages.toList()..sort()),
    'primary_language': primaryLanguage,
    'frameworks': (frameworks.toList()..sort()),
    'package_managers': (packageManagers.toList()..sort()),
    'build_tools': (buildTools.toList()..sort()),
    'runtime': (runtime.toList()..sort()),
    'containerization': {
      'dockerfile': containerDockerfile,
      'compose': containerCompose,
    },
    'kubernetes': {
      'helm': kubernetesHelm,
      'kustomize': kubernetesKustomize,
      'manifests': kubernetesManifests,
    },
  };
}

class _SizedPath {
  final String path;
  final int sizeBytes;
  _SizedPath(this.path, this.sizeBytes);
}

/* ----------------------------- Lightweight gitignore ----------------------------- */

class _Gitignore {
  final List<_GlobRule> rules;

  const _Gitignore(this.rules);

  const _Gitignore.empty() : rules = const [];

  bool isIgnored(String relPath, {required bool isDir}) {
    // Very lightweight: supports:
    // - comments
    // - blank lines
    // - trailing / means dir
    // - simple globs: *, ?, and ** via regex conversion
    // - leading / anchors at repo root
    // Not a full .gitignore spec (no negation precedence, etc. is minimal but useful).
    for (final r in rules) {
      if (r.matches(relPath, isDir: isDir)) return true;
    }
    return false;
  }
}

class _GlobRule {
  final RegExp re;
  final bool dirOnly;

  _GlobRule(this.re, {required this.dirOnly});

  bool matches(String relPath, {required bool isDir}) {
    if (dirOnly && !isDir) return false;
    return re.hasMatch(relPath);
  }
}

Future<_Gitignore> _loadGitignore(Directory root) async {
  final f = File('${root.absolute.path}${Platform.pathSeparator}.gitignore');
  try {
    if (!await f.exists()) return const _Gitignore.empty();

    final lines = await f.readAsLines();
    final rules = <_GlobRule>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue;

      // Ignore negations for simplicity (you can extend later)
      if (line.startsWith('!')) continue;

      var dirOnly = false;
      if (line.endsWith('/')) {
        dirOnly = true;
        line = line.substring(0, line.length - 1);
      }

      final anchored = line.startsWith('/');
      if (anchored) line = line.substring(1);

      // Convert glob -> regex
      final re = _globToRegex(line, anchored: anchored);
      rules.add(_GlobRule(re, dirOnly: dirOnly));
    }

    return _Gitignore(rules);
  } catch (_) {
    return const _Gitignore.empty();
  }
}

RegExp _globToRegex(String glob, {required bool anchored}) {
  // Support ** (match across dirs), * (no slash), ? (single char)
  var pattern = RegExp.escape(glob);

  // Reintroduce glob tokens
  pattern = pattern.replaceAll(r'\*\*', '§§DOUBLESTAR§§');
  pattern = pattern.replaceAll(r'\*', '§§STAR§§');
  pattern = pattern.replaceAll(r'\?', '§§QMARK§§');

  // ** => .*
  pattern = pattern.replaceAll('§§DOUBLESTAR§§', '.*');
  // * => [^/]* (no slash)
  pattern = pattern.replaceAll('§§STAR§§', r'[^/]*');
  // ? => [^/]
  pattern = pattern.replaceAll('§§QMARK§§', r'[^/]');

  // If not anchored, allow match anywhere in path segments
  final prefix = anchored ? '^' : r'(^|.*/)'; // segment boundary-ish
  final suffix = r'($|/.*$)'; // allow path continuation
  return RegExp('$prefix$pattern$suffix');
}

/* ----------------------------- Helpers ----------------------------- */

String _nameOf(String path) =>
    path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).last;

String _extOf(String name) {
  final i = name.lastIndexOf('.');
  if (i <= 0 || i == name.length - 1) return '';
  return name.substring(i).toLowerCase();
}

void _trackLargeFile(
  List<_SizedPath> list,
  _SizedPath item, {
  required int keep,
}) {
  list.add(item);
  list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
  if (list.length > keep) {
    list.removeRange(keep, list.length);
  }
}

Map<String, int> _sortedMapByValueDesc(Map<String, int> m) {
  final entries = m.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final out = <String, int>{};
  for (final e in entries) {
    out[e.key] = e.value;
  }
  return out;
}

String _slugify(String s) {
  final lower = s.toLowerCase();
  final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return cleaned
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

String _relPath(String root, String full) {
  final rp = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';
  if (full.startsWith(rp))
    return full.substring(rp.length).replaceAll('\\', '/');
  return full.replaceAll('\\', '/');
}
