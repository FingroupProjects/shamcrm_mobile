import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

class SubCategoryAttributesData with CustomDropdownListFilter {
  final int id;
  final String name;
  final String? image;
  final String? displayType;
  final bool hasPriceCharacteristics;
  final ParentCategory? parent; // Make parent nullable
  final List<Attribute> attributes;

  SubCategoryAttributesData({
    required this.id,
    required this.name,
    this.image,
    this.displayType,
    required this.hasPriceCharacteristics,
    this.parent, // Update constructor to allow null
    required this.attributes,
  });

  factory SubCategoryAttributesData.fromJson(Map<String, dynamic> json) {
    return SubCategoryAttributesData(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      image: SafeConverters.toStringOrNull(json['image']),
      displayType: SafeConverters.toStringOrNull(json['display_type']),
      hasPriceCharacteristics: SafeConverters.toBool(json['has_price_characteristics']),
      parent: SafeConverters.toMapOrNull(json['parent']) != null
          ? ParentCategory.fromJson(SafeConverters.toMap(json['parent']))
          : null,
      attributes: SafeConverters.toList(json['attributes'])
          .map((attribute) => Attribute.fromJson(SafeConverters.toMap(attribute)))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubCategoryAttributesData &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  bool filter(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return name.toLowerCase().contains(normalizedQuery) ||
        (parent?.name.toLowerCase().contains(normalizedQuery) ?? false);
  }

  @override
  String toString() => name;
}
class ParentCategory {
  final int id;
  final String name;
  final String? image;

  ParentCategory({
    required this.id,
    required this.name,
    this.image,
  });

  factory ParentCategory.fromJson(Map<String, dynamic> json) {
    return ParentCategory(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      image: SafeConverters.toStringOrNull(json['image']),
    );
  }
}

class Attribute {
  final int id;
  final String name;
  final String? value;
  final bool isIndividual;

  Attribute({
    required this.id,
    required this.name,
    this.value,
    required this.isIndividual,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    final attributeMap = SafeConverters.toMapOrNull(json['attribute']);
    return Attribute(
      id: SafeConverters.toInt(json['id']),
      name: attributeMap != null
          ? SafeConverters.toSafeString(attributeMap['name'])
          : SafeConverters.toSafeString(json['name']),
      value: SafeConverters.toStringOrNull(json['value']),
      isIndividual: SafeConverters.toBool(json['is_individual']),
    );
  }
}
