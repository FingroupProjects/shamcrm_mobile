class PermissionsModel {
  final List<String> permissions;

  PermissionsModel({required this.permissions});

  factory PermissionsModel.fromJson(Map<String, dynamic> json) {
    return PermissionsModel(
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }
}
