import 'dart:io';

import 'tool.dart';

class Project {
  final String id;
  final String name;
  final String path;
  final String? workspaceId;
  final bool isStarred;
  final DateTime lastOpened;
  final DateTime createdAt;
  final ToolId? lastUsedToolId;
  final ProjectGitInfo gitInfo;

  Project({
    required this.id,
    required this.name,
    required this.path,
    this.workspaceId,
    this.isStarred = false,
    required this.lastOpened,
    required this.createdAt,
    this.lastUsedToolId,
    this.gitInfo = const ProjectGitInfo(),
  });

  bool get pathExists => Directory(path).existsSync();

  Project copyWith({
    String? id,
    String? name,
    String? path,
    String? workspaceId,
    bool? isStarred,
    DateTime? lastOpened,
    DateTime? createdAt,
    ToolId? lastUsedToolId,
    ProjectGitInfo? gitInfo,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      workspaceId: workspaceId ?? this.workspaceId,
      isStarred: isStarred ?? this.isStarred,
      lastOpened: lastOpened ?? this.lastOpened,
      createdAt: createdAt ?? this.createdAt,
      lastUsedToolId: lastUsedToolId ?? this.lastUsedToolId,
      gitInfo: gitInfo ?? this.gitInfo,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'workspaceId': workspaceId,
    'isStarred': isStarred,
    'lastOpened': lastOpened.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'lastUsedToolId': lastUsedToolId?.name,
    if (gitInfo.hasData) 'gitInfo': gitInfo.toJson(),
  };

  factory Project.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {}
      }
      return fallback ?? now;
    }

    final createdAt = parseDate(
      json['createdAt'],
      fallback: parseDate(json['lastOpened'], fallback: now),
    );

    final lastOpened = parseDate(json['lastOpened'], fallback: createdAt);

    return Project(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      workspaceId: json['workspaceId'],
      isStarred: json['isStarred'] ?? false,
      lastOpened: lastOpened,
      createdAt: createdAt,
      lastUsedToolId: json['lastUsedToolId'] != null
          ? ToolId.values.firstWhere(
              (id) => id.name == json['lastUsedToolId'],
              orElse: () => ToolId.values.first,
            )
          : null,
      gitInfo: ProjectGitInfo.fromJson(
        json['gitInfo'] is Map<String, dynamic>
            ? json['gitInfo'] as Map<String, dynamic>
            : json['gitInfo'] is Map
            ? Map<String, dynamic>.from(json['gitInfo'] as Map)
            : null,
      ),
    );
  }

  static Project create({
    required String name,
    required String path,
    required String workspaceId,
    ToolId? preferredToolId,
  }) {
    final now = DateTime.now();
    return Project(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      path: path,
      workspaceId: workspaceId,
      lastOpened: now,
      createdAt: now,
      lastUsedToolId: preferredToolId,
      gitInfo: const ProjectGitInfo(),
    );
  }
}

class ProjectGitInfo {
  final bool isGitRepo;
  final String? rootPath;
  final String? branch;
  final String? origin;
  final int stagedChanges;
  final int unstagedChanges;
  final int untrackedChanges;
  final int? ahead;
  final int? behind;
  final String? lastCommitHash;
  final String? lastCommitMessage;
  final DateTime? lastCommitDate;

  const ProjectGitInfo({
    this.isGitRepo = false,
    this.rootPath,
    this.branch,
    this.origin,
    this.stagedChanges = 0,
    this.unstagedChanges = 0,
    this.untrackedChanges = 0,
    this.ahead,
    this.behind,
    this.lastCommitHash,
    this.lastCommitMessage,
    this.lastCommitDate,
  });

  bool get hasData =>
      isGitRepo ||
      rootPath != null ||
      branch != null ||
      origin != null ||
      stagedChanges != 0 ||
      unstagedChanges != 0 ||
      untrackedChanges != 0 ||
      ahead != null ||
      behind != null ||
      lastCommitHash != null ||
      lastCommitMessage != null ||
      lastCommitDate != null;

  int get totalChanges => stagedChanges + unstagedChanges + untrackedChanges;
  bool get isClean => totalChanges == 0;

  Map<String, dynamic> toJson() => {
    'isGitRepo': isGitRepo,
    'rootPath': rootPath,
    'branch': branch,
    'origin': origin,
    'stagedChanges': stagedChanges,
    'unstagedChanges': unstagedChanges,
    'untrackedChanges': untrackedChanges,
    'ahead': ahead,
    'behind': behind,
    'lastCommitHash': lastCommitHash,
    'lastCommitMessage': lastCommitMessage,
    'lastCommitDate': lastCommitDate?.toIso8601String(),
  };

  factory ProjectGitInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProjectGitInfo();
    }

    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {}
      }
      return null;
    }

    int? parseOptionalInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    int parseInt(dynamic value) => parseOptionalInt(value) ?? 0;

    String? readString(dynamic value) {
      if (value is String && value.isNotEmpty) return value;
      return null;
    }

    return ProjectGitInfo(
      isGitRepo: json['isGitRepo'] == true,
      rootPath: readString(json['rootPath']),
      branch: readString(json['branch']),
      origin: readString(json['origin']),
      stagedChanges: parseInt(json['stagedChanges']),
      unstagedChanges: parseInt(json['unstagedChanges']),
      untrackedChanges: parseInt(json['untrackedChanges']),
      ahead: parseOptionalInt(json['ahead']),
      behind: parseOptionalInt(json['behind']),
      lastCommitHash: readString(json['lastCommitHash']),
      lastCommitMessage: readString(json['lastCommitMessage']),
      lastCommitDate: parseDate(json['lastCommitDate']),
    );
  }
}

enum SortOption {
  recent,
  created,
  name;

  String get displayName {
    switch (this) {
      case SortOption.recent:
        return 'Last opened';
      case SortOption.created:
        return 'Created';
      case SortOption.name:
        return 'Name';
    }
  }
}
