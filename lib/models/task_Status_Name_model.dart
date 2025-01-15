class StatusName {
  final int id;
  final String name;
  final String? needsPermission;

  StatusName({
    required this.id,
    required this.name,
    this.needsPermission,
  });

  factory StatusName.fromJson(Map<String, dynamic> json) {
    return StatusName(
      id: json['id'] as int,
      name: json['name'] as String,
      needsPermission: json['needs_permission'] as String?,
    );
  }

  @override
  String toString() {
    return 'StatusName(id: $id, name: $name, needsPermission: $needsPermission)';
  }
}
