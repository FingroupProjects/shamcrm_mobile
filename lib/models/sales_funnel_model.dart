class SalesFunnel {
  final int id;
  final String name;
  final int? organizationId;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  SalesFunnel({
    required this.id,
    required this.name,
    this.organizationId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory SalesFunnel.fromJson(Map<String, dynamic> json) {
    return SalesFunnel(
      id: json['id'] as int,
      name: json['name'] as String,
      organizationId: json['organization_id'] as int?,
      isActive: json['is_active'] != null ? json['is_active'] == 1 : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'organization_id': organizationId,
      'is_active': isActive != null ? (isActive! ? 1 : 0) : null,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}