import 'package:crm_task_manager/utils/safe_converters.dart';

class CategoryDataById {
  final int id;
  final String name;
  final String? image;
  final String? displayType;
  final bool hasPriceCharacteristics;
  final ParentCategory? parent;
  final List<Attribute> attributes;
  final List<CategoryDataById> subcategories;

  CategoryDataById({
    required this.id,
    required this.name,
    this.image,
    this.displayType,
    required this.hasPriceCharacteristics,
    this.parent,
    required this.attributes,
    required this.subcategories,
  });

  CategoryDataById copyWith({
    int? id,
    String? name,
    String? image,
    String? displayType,
    bool? hasPriceCharacteristics,
    ParentCategory? parent,
    List<Attribute>? attributes,
    List<CategoryDataById>? subcategories,
  }) {
    return CategoryDataById(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      displayType: displayType ?? this.displayType,
      hasPriceCharacteristics: hasPriceCharacteristics ?? this.hasPriceCharacteristics,
      parent: parent ?? this.parent,
      attributes: attributes ?? this.attributes,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  factory CategoryDataById.fromJson(Map<String, dynamic> json) {
    return CategoryDataById(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      image: SafeConverters.toStringOrNull(json['image']),
      displayType: SafeConverters.toStringOrNull(json['display_type']),
      hasPriceCharacteristics: SafeConverters.toBool(json['has_price_characteristics']),
      parent: SafeConverters.toMapOrNull(json['parent']) != null
          ? ParentCategory.fromJson(SafeConverters.toMap(json['parent']))
          : null,
      attributes: SafeConverters.toList(json['attributes'])
          .map((attr) => Attribute.fromJson(SafeConverters.toMap(attr)))
          .toList(),
      subcategories: SafeConverters.toList(json['subcategories'])
          .map((subcat) => CategoryDataById.fromJson(SafeConverters.toMap(subcat)))
          .toList(),
    );
  }
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
  final bool isIndividual;

  Attribute({
    required this.id,
    required this.name,
    required this.isIndividual,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    final attributeMap = SafeConverters.toMap(json['attribute']);
    return Attribute(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(attributeMap['name']),
      isIndividual: SafeConverters.toBool(json['is_individual']),
    );
  }
}
class SubCategoryResponseASD {
  final List<CategoryDataById> categories;

  SubCategoryResponseASD({required this.categories});

  factory SubCategoryResponseASD.fromJson(Map<String, dynamic> json) {
    return SubCategoryResponseASD(
      categories: SafeConverters.toList(json['data'])
          .map((item) => CategoryDataById.fromJson(SafeConverters.toMap(item)))
          .toList(),
    );
  }
}
