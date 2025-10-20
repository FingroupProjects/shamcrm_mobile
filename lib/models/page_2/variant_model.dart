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
  String? selectedUnit;
  final List<Unit> availableUnits;
    final int? remainder; // ← ДОБАВЛЯЕМ


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
    this.selectedUnit,
    required this.availableUnits, // Added required modifier
    this.remainder,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('VariantModel: Парсинг варианта - id: ${json['id']}');
    }
    final attributeValues = (json['attribute_values'] as List<dynamic>?)?.map((v) {
      if (kDebugMode) {
        print('VariantModel: Парсинг атрибута - value: ${v['value']}');
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

    // Парсим единицы измерения из good
    final units = <Unit>[];
    
    // Добавляем единицы из good.units
    if (good?.units != null && good!.units!.isNotEmpty) {
      units.addAll(good.units!);
    }
    
    //  ""НЕ"" Добавляем единицы из good.measurements
    // if (good?.measurements != null && good!.measurements!.isNotEmpty) {
    //   for (var measurement in good.measurements!) {
    //     if (measurement.unit != null) { // Проверяем, что unit не null
    //       units.add(measurement.unit!);
    //     }
    //   }
    // }

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
      selectedUnit: units.isNotEmpty ? units.first.shortName ?? units.first.name : null,
      availableUnits: units, // Always non-null
      remainder: json['remainder'] != null
          ? int.tryParse(json['remainder'].toString())
          : null,

    );
  }
}

class AttributeValue {
  final int id;
  final int categoryAttributeId;
  final String value;
  final int? unitId;
  final List<String>? files;
  final CategoryAttribute? categoryAttribute;

  AttributeValue({
    required this.id,
    required this.categoryAttributeId,
    required this.value,
    this.unitId,
    this.files,
    this.categoryAttribute,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      id: json['id'] as int? ?? 0,
      categoryAttributeId: json['category_attribute_id'] as int? ?? 0,
      value: json['value'] as String? ?? '',
      unitId: json['unit_id'] as int?, // ← Can fail if API sends "123" as string
      files: (json['files'] as List<dynamic>?)?.cast<String>(),
      categoryAttribute: json['category_attribute'] != null
          ? CategoryAttribute.fromJson(
              json['category_attribute'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CategoryAttribute {
  final int id;
  final Attribute? attribute;
  final bool isIndividual;

  CategoryAttribute({
    required this.id,
    this.attribute,
    required this.isIndividual,
  });

  factory CategoryAttribute.fromJson(Map<String, dynamic> json) {
    return CategoryAttribute(
      id: json['id'] as int? ?? 0,
      attribute: json['attribute'] != null
          ? Attribute.fromJson(json['attribute'] as Map<String, dynamic>)
          : null,
      isIndividual: json['is_individual'] as bool? ?? false,
    );
  }
}

class Attribute {
  final int id;
  final String name;

  Attribute({
    required this.id,
    required this.name,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Неизвестная характеристика',
    );
  }
}