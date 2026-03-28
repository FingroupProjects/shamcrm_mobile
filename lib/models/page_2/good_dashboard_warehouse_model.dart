import 'dart:convert';

class GoodDashboardWarehouse {
  final int id;
  final String name;
  final Category category;
  final List<dynamic> files;
  final String? label;
  final bool isActive;
  final String price;
  final List<Discount>? discount;
  final bool isNew;
  final bool isSale;
  final bool isPopular;
  final String? article;

  GoodDashboardWarehouse({
    required this.id,
    required this.name,
    required this.category,
    required this.files,
    this.label,
    required this.isActive,
    required this.price,
    this.discount,
    required this.isNew,
    required this.isSale,
    required this.isPopular,
    this.article,
  });

  factory GoodDashboardWarehouse.fromJson(Map<String, dynamic> json) {
    return GoodDashboardWarehouse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: Category.fromJson(json['category'] ?? {}),
      files: json['files'] ?? [],
      label: json['label'] is String ? json['label'] : null,
      isActive: json['is_active'] ?? false,
      price: json['price'] ?? '0.00',
      discount: json['discount'] != null
          ? (json['discount'] as List).map((d) => Discount.fromJson(d)).toList()
          : null,
      isNew: json['is_new'] ?? false,
      isSale: json['is_sale'] ?? false,
      isPopular: json['is_popular'] ?? false,
      article: json['article'] is String ? json['article'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.toJson(),
      'files': files,
      'label': label,
      'is_active': isActive,
      'price': price,
      'discount': discount?.map((d) => d.toJson()).toList(),
      'is_new': isNew,
      'is_sale': isSale,
      'is_popular': isPopular,
      'article': article,
    };
  }
}

class Category {
  final int id;
  final String name;
  final String? image;
  final String displayType;
  final int isParent;
  final bool hasPriceCharacteristics;
  final dynamic? parent;
  final List<dynamic> attributes;

  Category({
    required this.id,
    required this.name,
    this.image,
    required this.displayType,
    required this.isParent,
    required this.hasPriceCharacteristics,
    this.parent,
    required this.attributes,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] is String ? json['image'] : null,
      displayType: json['display_type'] ?? 'a',
      isParent: json['is_parent'] ?? 0,
      hasPriceCharacteristics: json['has_price_characteristics'] ?? false,
      parent: json['parent'],
      attributes: json['attributes'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'display_type': displayType,
      'is_parent': isParent,
      'has_price_characteristics': hasPriceCharacteristics,
      'parent': parent,
      'attributes': attributes,
    };
  }
}

class Discount {
  final int id;
  final String name;
  final String from;
  final String to;
  final int percent;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? pivot;

  Discount({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.percent,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.pivot,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      percent: json['percent'] ?? 0,
      deletedAt: json['deleted_at'] is String ? json['deleted_at'] : null,
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      updatedAt: json['updated_at'] is String ? json['updated_at'] : null,
      pivot: json['pivot'] != null ? Map<String, dynamic>.from(json['pivot']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'from': from,
      'to': to,
      'percent': percent,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'pivot': pivot,
    };
  }
}