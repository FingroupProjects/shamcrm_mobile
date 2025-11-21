import 'dart:convert';

class CategoryDashboardWarehouse {
  final int id;
  final String name;
  final String? image;
  final int isParent;
  final List<dynamic> attributes;
  final bool hasPriceCharacteristics;
  final List<dynamic> subcategories;

  CategoryDashboardWarehouse({
    required this.id,
    required this.name,
    this.image,
    required this.isParent,
    required this.attributes,
    required this.hasPriceCharacteristics,
    required this.subcategories,
  });

  factory CategoryDashboardWarehouse.fromJson(Map<String, dynamic> json) {
    return CategoryDashboardWarehouse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] is String ? json['image'] : null,
      isParent: json['is_parent'] ?? 0,
      attributes: json['attributes'] ?? [],
      hasPriceCharacteristics: json['has_price_characteristics'] ?? false,
      subcategories: json['subcategories'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'is_parent': isParent,
      'attributes': attributes,
      'has_price_characteristics': hasPriceCharacteristics,
      'subcategories': subcategories,
    };
  }
}