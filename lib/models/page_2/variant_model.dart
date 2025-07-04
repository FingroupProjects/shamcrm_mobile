import 'package:crm_task_manager/models/page_2/goods_model.dart'; // Для переиспользования моделей Attribute, CategoryAttribute и т.д.

class Variant {
  final int id;
  final int goodId;
  final bool isActive;
  final String? fullName;
  final double? price;
  final List<AttributeValue> attributeValues;

  Variant({
    required this.id,
    required this.goodId,
    required this.isActive,
    this.fullName,
    this.price,
    required this.attributeValues,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    print('VariantModel: Парсинг варианта - id: ${json['id']}');
    final attributeValues = (json['attribute_values'] as List<dynamic>?)?.map((v) {
      print('VariantModel: Парсинг атрибута - value: ${v['value']}');
      return AttributeValue.fromJson(v as Map<String, dynamic>);
    }).toList() ?? [];

    double? price;
    if (json['price'] != null) {
      if (json['price'] is double) {
        price = json['price'];
      } else if (json['price'] is String) {
        price = double.tryParse(json['price']);
      }
    }

    return Variant(
      id: json['id'] as int? ?? 0,
      goodId: json['good_id'] as int? ?? 0,
      isActive: json['is_active'] == 1,
      fullName: json['full_name'] as String? ?? '',
      price: price,
      attributeValues: attributeValues,
    );
  }
}