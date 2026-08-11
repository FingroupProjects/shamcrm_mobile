import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';
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
      data: SafeConverters.toList(json['data'])
          .map((item) => Variant.fromJson(SafeConverters.toMap(item)))
          .toList(),
      pagination: VariantPagination.fromJson(
          SafeConverters.toMap(json['pagination'])),
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
      total: SafeConverters.toInt(json['total']),
      count: SafeConverters.toInt(json['count']),
      perPage: SafeConverters.toInt(json['per_page'], defaultValue: 15),
      currentPage: SafeConverters.toInt(json['current_page'], defaultValue: 1),
      totalPages: SafeConverters.toInt(json['total_pages'], defaultValue: 1),
    );
  }
}

class Variant {
  final int id;
  final int goodId;
  final bool isActive;
  final String? barcode;
  final String? fullName;
  final double? price;
  final List<AttributeValue> attributeValues;
  final Goods? good;
  bool isSelected;
  int quantitySelected;
  String? selectedUnit;
  final List<Unit> availableUnits;
  final double? remainder; // ← ДОБАВЛЯЕМ

  Variant({
    required this.id,
    required this.goodId,
    required this.isActive,
    this.barcode,
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
    final attributeValues = SafeConverters.toList(json['attribute_values'])
        .map((v) {
          if (kDebugMode) {
            final vMap = SafeConverters.toMap(v);
            debugPrint('VariantModel: Парсинг атрибута - value: ${vMap['value']}');
          }
          return AttributeValue.fromJson(SafeConverters.toMap(v));
        })
        .toList();

    double? price;
    if (json['price'] != null) {
      final priceRaw = json['price'];
      if (priceRaw is Map) {
        price = SafeConverters.toDoubleOrNull(
            SafeConverters.toMap(priceRaw)['price']);
      } else {
        price = SafeConverters.toDoubleOrNull(priceRaw);
      }
    }

    final good = SafeConverters.toMapOrNull(json['good']) != null
        ? Goods.fromJson(SafeConverters.toMap(json['good']))
        : null;

    // Парсим единицы измерения из good
    final units = <Unit>[];

    // Добавляем единицы из good.units
    if (good?.units != null && good!.units!.isNotEmpty) {
      units.addAll(good.units!);
    }

    return Variant(
      id: SafeConverters.toInt(json['id']),
      goodId: SafeConverters.toInt(json['good_id']),
      isActive: SafeConverters.toBool(json['is_active']),
      barcode: SafeConverters.toStringOrNull(json['barcode']),
      fullName: SafeConverters.toStringOrNull(json['full_name']),
      price: price,
      attributeValues: attributeValues,
      good: good,
      isSelected: false,
      quantitySelected: 1,
      selectedUnit:
          units.isNotEmpty ? units.first.shortName ?? units.first.name : null,
      availableUnits: units,
      remainder: SafeConverters.toDoubleOrNull(json['remainder']),
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
      id: SafeConverters.toInt(json['id']),
      categoryAttributeId: SafeConverters.toInt(json['category_attribute_id']),
      value: SafeConverters.toSafeString(json['value']),
      unitId: SafeConverters.toIntOrNull(json['unit_id']),
      files: _parseStringList(json['files']),
      categoryAttribute: SafeConverters.toMapOrNull(json['category_attribute']) != null
          ? CategoryAttribute.fromJson(
              SafeConverters.toMap(json['category_attribute']))
          : null,
    );
  }
}

List<String>? _parseStringList(dynamic value) {
  final raw = SafeConverters.toList(value);
  if (raw.isEmpty) return null;
  return raw.map((f) => SafeConverters.toSafeString(f)).toList();
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
      id: SafeConverters.toInt(json['id']),
      attribute: SafeConverters.toMapOrNull(json['attribute']) != null
          ? Attribute.fromJson(SafeConverters.toMap(json['attribute']))
          : null,
      isIndividual: SafeConverters.toBool(json['is_individual']),
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'],
          defaultValue: 'Неизвестная характеристика'),
    );
  }
}
