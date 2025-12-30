class Workspace {
  static const int maxNameLength = 15;

  final String id;
  final String name;
  final DateTime createdAt;
  final bool isDefault;

  Workspace({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isDefault = false,
  });

  Workspace copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'isDefault': isDefault,
  };

  factory Workspace.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    DateTime parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {}
      }
      return now;
    }

    return Workspace(
      id: json['id'],
      name: json['name'],
      createdAt: parseDate(json['createdAt']),
      isDefault: json['isDefault'] == true,
    );
  }

  static Workspace create({required String name, bool isDefault = false}) {
    final now = DateTime.now();
    return Workspace(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: now,
      isDefault: isDefault,
    );
  }
}
