import 'dart:io';

import 'tool.dart';

class Project {
  final String id;
  final String name;
  final String path;
  final bool isStarred;
  final DateTime lastOpened;
  final DateTime createdAt;
  final ToolId? lastUsedToolId;

  Project({
    required this.id,
    required this.name,
    required this.path,
    this.isStarred = false,
    required this.lastOpened,
    required this.createdAt,
    this.lastUsedToolId,
  });

  bool get pathExists => Directory(path).existsSync();

  Project copyWith({
    String? id,
    String? name,
    String? path,
    bool? isStarred,
    DateTime? lastOpened,
    DateTime? createdAt,
    ToolId? lastUsedToolId,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      isStarred: isStarred ?? this.isStarred,
      lastOpened: lastOpened ?? this.lastOpened,
      createdAt: createdAt ?? this.createdAt,
      lastUsedToolId: lastUsedToolId ?? this.lastUsedToolId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'isStarred': isStarred,
    'lastOpened': lastOpened.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'lastUsedToolId': lastUsedToolId?.name,
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
      isStarred: json['isStarred'] ?? false,
      lastOpened: lastOpened,
      createdAt: createdAt,
      lastUsedToolId: json['lastUsedToolId'] != null
          ? ToolId.values.firstWhere(
              (id) => id.name == json['lastUsedToolId'],
              orElse: () => ToolId.values.first,
            )
          : null,
    );
  }

  static Project create({
    required String name,
    required String path,
    ToolId? preferredToolId,
  }) {
    final now = DateTime.now();
    return Project(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      path: path,
      lastOpened: now,
      createdAt: now,
      lastUsedToolId: preferredToolId,
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
