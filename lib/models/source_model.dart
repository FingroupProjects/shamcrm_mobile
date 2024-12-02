class SourceLead {
  final int id;
  final String name;
  // final String? createdAt;
  // final String? updatedAt;

  SourceLead({
    required this.id,
    required this.name,
    // this.createdAt,
    // this.updatedAt,
  });

 factory SourceLead.fromJson(Map<String, dynamic> json) {
    return SourceLead(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Без имени',
      // createdAt: json['created_at'],
      // updatedAt: json['updated_at'],
    );
  }
}
