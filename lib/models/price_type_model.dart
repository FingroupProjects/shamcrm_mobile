class PriceType {
  final int id;
  final String name;
  final int organizationId;
  final String? createdAt;
  final String? updatedAt;

  PriceType({
    required this.id,
    required this.name,
    required this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory PriceType.fromJson(Map<String, dynamic> json) {
    return PriceType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      organizationId: json['organization_id'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  @override
  String toString() => name;
}