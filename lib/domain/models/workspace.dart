class Workspace {
  static const int maxNameLength = 15;
  static const int defaultIconIndex = 0;

  final String id;
  final String name;
  final DateTime createdAt;
  final bool isDefault;
  final int iconIndex;
  final int order;

  Workspace({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isDefault = false,
    this.iconIndex = defaultIconIndex,
    this.order = 0,
  });

  Workspace copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isDefault,
    int? iconIndex,
    int? order,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
      iconIndex: iconIndex ?? this.iconIndex,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'isDefault': isDefault,
    'iconIndex': iconIndex,
    'order': order,
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

    // For backward compatibility, convert old iconCodePoint to iconIndex
    int iconIndex = defaultIconIndex;
    if (json.containsKey('iconIndex')) {
      iconIndex = json['iconIndex'] as int? ?? defaultIconIndex;
    } else if (json.containsKey('iconCodePoint')) {
      // Old data - use default index
      iconIndex = defaultIconIndex;
    }

    return Workspace(
      id: json['id'],
      name: json['name'],
      createdAt: parseDate(json['createdAt']),
      isDefault: json['isDefault'] == true,
      iconIndex: iconIndex,
      order: json['order'] as int? ?? 0,
    );
  }

  static Workspace create({
    required String name,
    bool isDefault = false,
    int? iconIndex,
    int order = 0,
  }) {
    final now = DateTime.now();
    return Workspace(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: now,
      isDefault: isDefault,
      iconIndex: iconIndex ?? defaultIconIndex,
      order: order,
    );
  }
}
