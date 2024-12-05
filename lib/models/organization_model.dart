class Organization {
  final int id;
  final String name;
  final DateTime? last1cUpdate;
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
      last1cUpdate: json['last_1c_update'] != null
          ? DateTime.parse(json['last_1c_update'])
          : null,
      is1cIntegration: json['1c_integration'] ?? false,
    );
  }
}
