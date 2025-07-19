import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:flutter/foundation.dart';

class Variant {
  final int id;
  final int goodId;
  final bool isActive;
  final String? fullName;
  final double? price;
  final List<AttributeValue> attributeValues;
  final Goods? good;
  bool isSelected;
  int quantitySelected;

  Variant({
    required this.id,
    required this.goodId,
    required this.isActive,
    this.fullName,
    this.price,
    required this.attributeValues,
    this.good,
    this.isSelected = false,
    this.quantitySelected = 1,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      //print('VariantModel: Парсинг варианта - id: ${json['id']}');
    }

    final attributeValues = (json['attribute_values'] as List<dynamic>?)?.map((v) {
      if (kDebugMode) {
        //print('VariantModel: Парсинг атрибута - value: ${v['value']}');
      }
      return AttributeValue.fromJson(v as Map<String, dynamic>);
    }).toList() ?? [];

    double? price;
    if (json['price'] != null) {
      if (json['price'] is Map) {
        price = double.tryParse(json['price']['price'].toString());
      } else if (json['price'] is String) {
        price = double.tryParse(json['price']);
      } else if (json['price'] is double) {
        price = json['price'];
      }
    }

    final good = json['good'] != null ? Goods.fromJson(json['good'] as Map<String, dynamic>) : null;

    return Variant(
      id: json['id'] as int? ?? 0,
      goodId: json['good_id'] as int? ?? 0,
      isActive: json['is_active'] == 1,
      fullName: json['full_name'] as String? ?? '',
      price: price,
      attributeValues: attributeValues,
      good: good,
      isSelected: false,
      quantitySelected: 1,
    );
  }
}