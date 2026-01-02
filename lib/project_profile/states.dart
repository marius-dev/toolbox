class DocsState {
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

class ProcessState {
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

class StackState {
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
    final weights = <String, int>{};
    void add(String lang, int w) => weights[lang] = (weights[lang] ?? 0) + w;

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

    for (final l in languages) add(l, 50);

    if (weights.isNotEmpty) {
      final best = weights.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      primaryLanguage = best.first.value > 0 ? best.first.key : null;
    }

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
