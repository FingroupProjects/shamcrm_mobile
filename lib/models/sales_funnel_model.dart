class SalesFunnel {
  final int id;
  final String name;
  final int organizationId;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  SalesFunnel({
    required this.id,
    required this.name,
    required this.organizationId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SalesFunnel.fromJson(Map<String, dynamic> json) {
    return SalesFunnel(
      id: json['id'],
      name: json['name'],
      organizationId: json['organization_id'],
      isActive: json['is_active'] == 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'organization_id': organizationId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}