class CategoryResponse {
  final List<CategoryDetail>? result;
  final dynamic errors;

  CategoryResponse({
    this.result,
    this.errors,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      result: json['result'] != null
          ? (json['result'] as List)
              .map((i) => CategoryDetail.fromJson(i))
              .toList()
          : null,
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
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image'],
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((i) => SubCategoryResponse.fromJson(i))
              .toList()
          : [],
      attributes: json['attributes'] != null
          ? (json['attributes'] as List)
              .map((i) => Attribute.fromJson(i))
              .toList()
          : [],
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
      name: json['name'] as String? ?? '',
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
      name: json['name'] ?? '',
      id: json['id'],
      image: json['image'],
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((i) => SubCategoryResponse.fromJson(i))
              .toList()
          : [],
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
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image'],
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((i) => SubCategoryResponse.fromJson(i))
              .toList()
          : null,
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
