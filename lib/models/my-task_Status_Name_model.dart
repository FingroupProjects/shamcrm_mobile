class MyStatusName {
  final int id;
  final String name;
  final String? needsPermission;

  MyStatusName({
    required this.id,
    required this.name,
    this.needsPermission,
  });

  factory MyStatusName.fromJson(Map<String, dynamic> json) {
    return MyStatusName(
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
