import 'dart:convert';

class SourceLead {
  final int id;
  final String name;
  final String? createdAt;
  final String? updatedAt;

  SourceLead({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory SourceLead.fromJson(Map<String, dynamic> json) {
    return SourceLead(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      updatedAt: json['update_at'] is String ? json['update_at'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
