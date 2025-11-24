import 'dart:io';

class Project {
  final String id;
  final String name;
  final String path;
  final ProjectType type;
  final bool isStarred;
  final DateTime lastOpened;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.isStarred = false,
    required this.lastOpened,
    required this.createdAt,
  });

  bool get pathExists => Directory(path).existsSync();

  Project copyWith({
    String? id,
    String? name,
    String? path,
    ProjectType? type,
    bool? isStarred,
    DateTime? lastOpened,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      isStarred: isStarred ?? this.isStarred,
      lastOpened: lastOpened ?? this.lastOpened,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'type': type.name,
    'isStarred': isStarred,
    'lastOpened': lastOpened.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    name: json['name'],
    path: json['path'],
    type: ProjectType.fromString(json['type']),
    isStarred: json['isStarred'] ?? false,
    lastOpened: DateTime.parse(json['lastOpened']),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.parse(json['lastOpened']),
  );

  static Project create({
    required String name,
    required String path,
    required ProjectType type,
  }) {
    final now = DateTime.now();
    return Project(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      path: path,
      type: type,
      lastOpened: now,
      createdAt: now,
    );
  }
}

enum ProjectType {
  flutter,
  web,
  mobile,
  desktop;

  String get displayName {
    switch (this) {
      case ProjectType.flutter:
        return 'Flutter';
      case ProjectType.web:
        return 'Web';
      case ProjectType.mobile:
        return 'Mobile';
      case ProjectType.desktop:
        return 'Desktop';
    }
  }

  static ProjectType fromString(String value) {
    return ProjectType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ProjectType.flutter,
    );
  }
}

enum SortOption {
  recent,
  created,
  name,
  type;

  String get displayName {
    switch (this) {
      case SortOption.recent:
        return 'Last opened';
      case SortOption.created:
        return 'Created';
      case SortOption.name:
        return 'Name';
      case SortOption.type:
        return 'Type';
    }
  }
}
