import 'dart:io';

import '../../domain/models/project.dart';

class ProjectMetadataService {
  ProjectMetadataService._internal();

  static final ProjectMetadataService instance =
      ProjectMetadataService._internal();

  Future<ProjectGitInfo> fetchGitInfo(String path) async {
    if (!Directory(path).existsSync()) {
      return const ProjectGitInfo();
    }

    final isRepo = await _isGitRepository(path);
    if (!isRepo) {
      return const ProjectGitInfo();
    }

    final rootPath = _cleanOutput(
      await _runGit(path, ['rev-parse', '--show-toplevel']),
    );

    var branch = _cleanOutput(
      await _runGit(path, ['rev-parse', '--abbrev-ref', 'HEAD']),
    );

    if (branch == 'HEAD') {
      final shortHash = _cleanOutput(
        await _runGit(path, ['rev-parse', '--short', 'HEAD']),
      );
      branch = shortHash == null ? 'detached' : 'detached@$shortHash';
    }

    final origin = _cleanOutput(
      await _runGit(path, ['config', '--get', 'remote.origin.url']),
    );

    final statusOutput = await _runGit(path, ['status', '--porcelain']);
    final status = _parseStatus(statusOutput ?? '');

    final upstream = _cleanOutput(
      await _runGit(
        path,
        ['rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}'],
      ),
    );

    _AheadBehindCounts? upstreamCounts;
    if (upstream != null) {
      upstreamCounts = _parseAheadBehind(
        await _runGit(
          path,
          ['rev-list', '--left-right', '--count', '@{upstream}...HEAD'],
        ),
      );
    }

    final lastCommit = _parseLastCommit(
      await _runGit(
        path,
        const ['log', '-1', '--pretty=%H%x1f%s%x1f%ct'],
      ),
    );

    return ProjectGitInfo(
      isGitRepo: true,
      rootPath: rootPath,
      branch: branch,
      origin: origin,
      stagedChanges: status.staged,
      unstagedChanges: status.unstaged,
      untrackedChanges: status.untracked,
      ahead: upstreamCounts?.ahead,
      behind: upstreamCounts?.behind,
      lastCommitHash: lastCommit?.hash,
      lastCommitMessage: lastCommit?.message,
      lastCommitDate: lastCommit?.date,
    );
  }

  Future<bool> _isGitRepository(String path) async {
    final output = _cleanOutput(
      await _runGit(path, ['rev-parse', '--is-inside-work-tree']),
    );
    return output == 'true';
  }

  Future<String?> _runGit(String path, List<String> args) async {
    try {
      final result = await Process.run(
        'git',
        args,
        workingDirectory: path,
      );
      if (result.exitCode != 0) return null;
      final stdout = result.stdout;
      if (stdout is String) return stdout.trimRight();
      return stdout.toString().trimRight();
    } catch (_) {
      return null;
    }
  }

  String? _cleanOutput(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  _GitStatusCounts _parseStatus(String output) {
    var staged = 0;
    var unstaged = 0;
    var untracked = 0;

    for (final line in output.split('\n')) {
      if (line.isEmpty) continue;
      if (line.startsWith('??')) {
        untracked += 1;
        continue;
      }
      if (line.length < 2) continue;
      final indexStatus = line[0];
      final workTreeStatus = line[1];
      if (indexStatus != ' ') {
        staged += 1;
      }
      if (workTreeStatus != ' ') {
        unstaged += 1;
      }
    }

    return _GitStatusCounts(
      staged: staged,
      unstaged: unstaged,
      untracked: untracked,
    );
  }

  _AheadBehindCounts? _parseAheadBehind(String? output) {
    if (output == null) return null;
    final parts = output.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return null;
    final behind = int.tryParse(parts[0]);
    final ahead = int.tryParse(parts[1]);
    if (ahead == null || behind == null) return null;
    return _AheadBehindCounts(ahead: ahead, behind: behind);
  }

  _GitLastCommit? _parseLastCommit(String? output) {
    if (output == null) return null;
    final trimmed = output.trim();
    if (trimmed.isEmpty) return null;

    const separator = '\x1f';
    final parts = trimmed.split(separator);
    if (parts.length < 3) return null;

    final hash = parts[0];
    final message = parts[1];
    final timestamp = int.tryParse(parts[2]);
    final date = timestamp == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    return _GitLastCommit(hash: hash, message: message, date: date);
  }
}

class _GitStatusCounts {
  final int staged;
  final int unstaged;
  final int untracked;

  const _GitStatusCounts({
    required this.staged,
    required this.unstaged,
    required this.untracked,
  });
}

class _AheadBehindCounts {
  final int ahead;
  final int behind;

  const _AheadBehindCounts({required this.ahead, required this.behind});
}

class _GitLastCommit {
  final String hash;
  final String message;
  final DateTime? date;

  const _GitLastCommit({
    required this.hash,
    required this.message,
    required this.date,
  });
}
