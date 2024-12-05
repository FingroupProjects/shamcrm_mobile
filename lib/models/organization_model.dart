class Organization {
  final int id;
  final String name;
  final String? last1cUpdate;
  final bool is1cIntegration;

  Organization({
    required this.id,
    required this.name,
    this.last1cUpdate,
    required this.is1cIntegration,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      last1cUpdate: json['last_1c_update'] is String ? json['last_1c_update'] : null,
      is1cIntegration: json['1c_integration'] ?? false,
    );
  }
}
