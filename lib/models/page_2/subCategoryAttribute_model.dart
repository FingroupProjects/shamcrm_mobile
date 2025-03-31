

class SubCategoryAttributesData {
  final int id;
  final String name;
  final String? image;
  final ParentCategory parent;
  final List<Attribute> attributes;

  SubCategoryAttributesData({
    required this.id,
    required this.name,
    this.image,
    required this.parent,
    required this.attributes,
  });

  factory SubCategoryAttributesData.fromJson(Map<String, dynamic> json) {
    return SubCategoryAttributesData(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      parent: ParentCategory.fromJson(json['parent'] as Map<String, dynamic>),
      attributes: (json['attributes'] as List)
          .map((attribute) => Attribute.fromJson(attribute as Map<String, dynamic>))
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
  final String? value; 

  Attribute({
    required this.id,
    required this.name,
    this.value, 
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
  return Attribute(
    id: (json['id'] as int?) ?? 0, 
    name: (json['name'] as String?) ?? '',
    value: json['value'] as String?,
  );
}
}