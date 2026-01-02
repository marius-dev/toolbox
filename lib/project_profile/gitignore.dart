import 'dart:io';

class Gitignore {
  final List<GlobRule> rules;

  const Gitignore(this.rules);

  const Gitignore.empty() : rules = const [];

  bool isIgnored(String relPath, {required bool isDir}) {
    for (final r in rules) {
      if (r.matches(relPath, isDir: isDir)) return true;
    }
    return false;
  }
}

class GlobRule {
  final RegExp re;
  final bool dirOnly;

  GlobRule(this.re, {required this.dirOnly});

  bool matches(String relPath, {required bool isDir}) {
    if (dirOnly && !isDir) return false;
    return re.hasMatch(relPath);
  }
}

Future<Gitignore> loadGitignore(Directory root) async {
  final f = File('${root.absolute.path}${Platform.pathSeparator}.gitignore');
  try {
    if (!await f.exists()) return const Gitignore.empty();

    final lines = await f.readAsLines();
    final rules = <GlobRule>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue;

      if (line.startsWith('!')) continue;

      var dirOnly = false;
      if (line.endsWith('/')) {
        dirOnly = true;
        line = line.substring(0, line.length - 1);
      }

      final anchored = line.startsWith('/');
      if (anchored) line = line.substring(1);

      final re = globToRegex(line, anchored: anchored);
      rules.add(GlobRule(re, dirOnly: dirOnly));
    }

    return Gitignore(rules);
  } catch (_) {
    return const Gitignore.empty();
  }
}

RegExp globToRegex(String glob, {required bool anchored}) {
  var pattern = RegExp.escape(glob);

  pattern = pattern.replaceAll(r'\*\*', '§§DOUBLESTAR§§');
  pattern = pattern.replaceAll(r'\*', '§§STAR§§');
  pattern = pattern.replaceAll(r'\?', '§§QMARK§§');

  pattern = pattern.replaceAll('§§DOUBLESTAR§§', '.*');
  pattern = pattern.replaceAll('§§STAR§§', r'[^/]*');
  pattern = pattern.replaceAll('§§QMARK§§', r'[^/]');

  final prefix = anchored ? '^' : r'(^|.*/)';
  final suffix = r'($|/.*$)';
  return RegExp('$prefix$pattern$suffix');
}
