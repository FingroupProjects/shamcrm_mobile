
import 'package:crm_task_manager/models/page_2/category_model.dart';

class Goods {
  final int id;
  final String name;
  final CategoryData category;
  final String? description;
  final int? quantity;  // Изменено на nullable
  final List<GoodsFile> files;
  final List<Attribute> attributes;

  Goods({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.quantity,  // Теперь может быть null
    required this.files,
    required this.attributes,
  });

factory Goods.fromJson(Map<String, dynamic> json) {
  try {
    // Обработка quantity с проверкой на null и тип
    int? quantity;
    if (json['quantity'] != null) {
      if (json['quantity'] is int) {
        quantity = json['quantity'];
      } else if (json['quantity'] is String) {
        quantity = int.tryParse(json['quantity']);
      }
    }

    return Goods(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      category: json['category'] != null 
          ? CategoryData.fromJson(json['category']) 
          : CategoryData(id: 0, name: 'Без категории', subcategories: []),
      description: json['description'] as String?,
      quantity: quantity, // Используем обработанное значение
      files: (json['files'] as List<dynamic>?)
          ?.map((f) => GoodsFile.fromJson(f as Map<String, dynamic>))
          .toList() ?? [],
      attributes: (json['attributes'] as List<dynamic>?)
          ?.map((attr) => Attribute.fromJson(attr as Map<String, dynamic>))
          .toList() ?? [],
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
