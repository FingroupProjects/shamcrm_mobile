import 'package:crm_task_manager/utils/safe_converters.dart';

class CategoryResponse {
  final List<CategoryDetail>? result;
  final dynamic errors;

  CategoryResponse({
    this.result,
    this.errors,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      result: SafeConverters.toList(json['result']).isEmpty
          ? null
          : SafeConverters.toList(json['result'])
              .whereType<Map<String, dynamic>>()
              .map((i) => CategoryDetail.fromJson(i))
              .toList(),
      errors: json['errors'],
    );
  }
}

class SubCategoryResponse {
  final int id;
  final String name;
  final String? image;

  final List<SubCategoryResponse> subcategories;
  final List<Attribute> attributes;

  SubCategoryResponse({
    required this.id,
    required this.name,
    this.image,
    required this.subcategories,
    required this.attributes,
  });

  factory SubCategoryResponse.fromJson(Map<String, dynamic> json) {
    return SubCategoryResponse(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      image: SafeConverters.toStringOrNull(json['image']),
      subcategories: SafeConverters.toList(json['subcategories'])
          .whereType<Map<String, dynamic>>()
          .map((i) => SubCategoryResponse.fromJson(i))
          .toList(),
      attributes: SafeConverters.toList(json['attributes'])
          .whereType<Map<String, dynamic>>()
          .map((i) => Attribute.fromJson(i))
          .toList(),
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
      name: SafeConverters.toSafeString(json['name']),
    );
  }
}

class CategoryData {
  final String name;
  final int id;
  final String? image;
  final List<SubCategoryResponse> subcategories;

  CategoryData({
    required this.name,
    required this.id,
    this.image,
    required this.subcategories,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      name: SafeConverters.toSafeString(json['name']),
      id: SafeConverters.toInt(json['id']),
      image: SafeConverters.toStringOrNull(json['image']),
      subcategories: SafeConverters.toList(json['subcategories'])
          .whereType<Map<String, dynamic>>()
          .map((i) => SubCategoryResponse.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'image': image,
      'subcategories': subcategories,
    };
  }
}

class CategoryDetail {
  final int id;
  final String name;
  final String? image;
  final List<SubCategoryResponse>? subcategories;

  CategoryDetail({
    required this.id,
    required this.name,
    this.image,
    this.subcategories,
  });

  factory CategoryDetail.fromJson(Map<String, dynamic> json) {
    return CategoryDetail(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      image: SafeConverters.toStringOrNull(json['image']),
      subcategories: SafeConverters.toList(json['subcategories']).isEmpty
          ? null
          : SafeConverters.toList(json['subcategories'])
              .whereType<Map<String, dynamic>>()
              .map((i) => SubCategoryResponse.fromJson(i))
              .toList(),
    );
  }
}

class CategoryWithCount {
  final CategoryData category;
  final int goodsCount;
  final int level; // Уровень вложенности: 0 = основная категория, 1+ = подкатегории
  final int? parentId; // ID родительской категории (для подкатегорий)

  CategoryWithCount({
    required this.category,
    required this.goodsCount,
    this.level = 0,
    this.parentId,
  });
}
