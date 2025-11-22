import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:flutter/foundation.dart';

class VariantResponse {
  final List<Variant> data;
  final VariantPagination pagination;

  VariantResponse({
    required this.data,
    required this.pagination,
  });

  factory VariantResponse.fromJson(Map<String, dynamic> json) {
    return VariantResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => Variant.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: VariantPagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class VariantPagination {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  VariantPagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory VariantPagination.fromJson(Map<String, dynamic> json) {
    return VariantPagination(
      total: json['total'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
      perPage: json['per_page'] as int? ?? 15,
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }
}

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
      debugPrint('VariantModel: Парсинг варианта - id: ${json['id']}');
    }
    final attributeValues = (json['attribute_values'] as List<dynamic>?)?.map((v) {
      if (kDebugMode) {
        debugPrint('VariantModel: Парсинг атрибута - value: ${v['value']}');
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