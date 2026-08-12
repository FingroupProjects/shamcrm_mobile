import 'dart:convert';

class LeadStatusForFilter {
  final int id;
  final String title;
  final String? createdAt;
  final String? updatedAt;

  LeadStatusForFilter({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  factory LeadStatusForFilter.fromJson(Map<String, dynamic> json) {
    return LeadStatusForFilter(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      updatedAt: json['updated_at'] is String ? json['updated_at'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}