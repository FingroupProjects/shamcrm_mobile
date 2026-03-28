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
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      displayType: json['display_type'] as String?,
      hasPriceCharacteristics: json['has_price_characteristics'] as bool,
      parent: json['parent'] != null ? ParentCategory.fromJson(json['parent']) : null,
      attributes: (json['attributes'] as List<dynamic>)
          .map((attr) => Attribute.fromJson(attr as Map<String, dynamic>))
          .toList(),
      subcategories: (json['subcategories'] as List<dynamic>)
          .map((subcat) => CategoryDataById.fromJson(subcat as Map<String, dynamic>))
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
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
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
    return Attribute(
      id: json['id'] as int,
      name: json['attribute']['name'] as String,
      isIndividual: json['is_individual'] as bool,
    );
  }
}
class SubCategoryResponseASD {
  final List<CategoryDataById> categories;

  SubCategoryResponseASD({required this.categories});

  factory SubCategoryResponseASD.fromJson(Map<String, dynamic> json) {
    return SubCategoryResponseASD(
      categories: (json['data'] as List<dynamic>)
          .map((item) => CategoryDataById.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}