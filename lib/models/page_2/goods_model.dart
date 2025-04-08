import 'package:crm_task_manager/models/page_2/category_model.dart';

class Goods {
  final int id;
  final String name;
  final CategoryData category;
  final String? description;
  final int? quantity;
  final double? discountPrice; // Добавлено
  final bool? isActive; // Добавлено
  final List<GoodsFile> files;
  final List<GoodsAttribute> attributes; // Изменено на GoodsAttribute

  Goods({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.quantity,
    this.discountPrice,
    this.isActive,
    required this.files,
    required this.attributes,
  });

  factory Goods.fromJson(Map<String, dynamic> json) {
    try {
      int? quantity;
      if (json['quantity'] != null) {
        if (json['quantity'] is int) {
          quantity = json['quantity'];
        } else if (json['quantity'] is String) {
          quantity = int.tryParse(json['quantity']);
        }
      }

      double? discountPrice;
      if (json['discount_price'] != null) {
        if (json['discount_price'] is double) {
          discountPrice = json['discount_price'];
        } else if (json['discount_price'] is String) {
          discountPrice = double.tryParse(json['discount_price']);
        }
      }

      return Goods(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        category: json['category'] != null
            ? CategoryData.fromJson(json['category'])
            : CategoryData(id: 0, name: 'Без категории', subcategories: []),
        description: json['description'] as String?,
        quantity: quantity,
        discountPrice: discountPrice,
        isActive: json['is_active'] as bool?,
        files: (json['files'] as List<dynamic>?)
                ?.map((f) => GoodsFile.fromJson(f as Map<String, dynamic>))
                .toList() ??
            [],
        attributes: (json['attributes'] as List<dynamic>?)
                ?.map((attr) =>
                    GoodsAttribute.fromJson(attr as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e, stackTrace) {
      print('Error parsing Goods: $e');
      print(stackTrace);
      rethrow;
    }
  }
}

class GoodsFile {
  final int id;
  final String name;
  final String path;

  GoodsFile({
    required this.id,
    required this.name,
    required this.path,
  });

  factory GoodsFile.fromJson(Map<String, dynamic> json) {
    return GoodsFile(
      id: json['id'] as int,
      name: json['name'] as String,
      path: json['path'] as String,
    );
  }
}

class GoodsAttribute {
  final String name;
  final String value;

  GoodsAttribute({
    required this.name,
    required this.value,
  });

  factory GoodsAttribute.fromJson(Map<String, dynamic> json) {
  final attrData = json['attributes'] as Map<String, dynamic>?;
  return GoodsAttribute(
    name: attrData != null ? (attrData['name'] as String? ?? '') : '',
    value: json['value'] as String? ?? '',
  );
}
}
