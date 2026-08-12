class Role {
  final int id;
  final String name;
  final String guardName;
  final String createdAt;
  final String updatedAt;

  Role({
    required this.id,
    required this.name,
    required this.guardName,
    required this.createdAt,
    required this.updatedAt,
  });

factory Role.fromJson(Map<String, dynamic> json) {
  try {
    return Role(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      guardName: json['guard_name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  } catch (e) {
    throw FormatException('Failed to parse Role from JSON: $e');
  }
}

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'guard_name': guardName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
