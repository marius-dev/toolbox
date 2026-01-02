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

ScanOptions parseScanOptions(List<String> args) {
  var maxDepth = 25;
  var pretty = false;
  var noGit = false;
  var followLinks = false;
  var respectGitignore = false;

  for (final a in args) {
    if (a == '--pretty') {
      pretty = true;
    } else if (a == '--no-git') {
      noGit = true;
    } else if (a == '--follow-links') {
      followLinks = true;
    } else if (a == '--respect-gitignore') {
      respectGitignore = true;
    } else if (a.startsWith('--max-depth=')) {
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
