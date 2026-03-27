import 'dart:convert';

class Label {
  final int id;
  final String name;
  final String color;
  final int showOnMain;
  final String? createdAt;
  final String? updatedAt;

  Label({
    required this.id,
    required this.name,
    required this.color,
    required this.showOnMain,
    this.createdAt,
    this.updatedAt,
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      showOnMain: json['show_on_main'] ?? 0,
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      updatedAt: json['updated_at'] is String ? json['updated_at'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'show_on_main': showOnMain,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}