class CategoryDataById {
  final int id;
  final String name;
  final String? image;
  final List<Attribute> attributes;
  final List<CategoryDataById> subcategories;

  CategoryDataById({
    required this.id,
    required this.name,
    this.image,
    required this.attributes,
    required this.subcategories,
  });

  // Добавляем метод copyWith
  CategoryDataById copyWith({
    int? id,
    String? name,
    String? image,
    List<Attribute>? attributes,
    List<CategoryDataById>? subcategories,
  }) {
    return CategoryDataById(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      attributes: attributes ?? this.attributes,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  factory CategoryDataById.fromJson(Map<String, dynamic> json) {
    return CategoryDataById(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      attributes: (json['attributes'] as List<dynamic>)
          .map((attr) => Attribute.fromJson(attr as Map<String, dynamic>))
          .toList(),
      subcategories: (json['subcategories'] as List<dynamic>)
          .map((subcat) => CategoryDataById.fromJson(subcat as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Attribute {
  final int id;
  final String name;

  Attribute({required this.id, required this.name});

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json['id'] as int,
      name: json['name'] as String,
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