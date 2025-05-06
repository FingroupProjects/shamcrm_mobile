class SubCategoryAttributesData {
  final int id;
  final String name;
  final String? image;
  final String? displayType;
  final bool hasPriceCharacteristics;
  final ParentCategory parent;
  final List<Attribute> attributes;

  SubCategoryAttributesData({
    required this.id,
    required this.name,
    this.image,
    this.displayType,
    required this.hasPriceCharacteristics,
    required this.parent,
    required this.attributes,
  });

  factory SubCategoryAttributesData.fromJson(Map<String, dynamic> json) {
    return SubCategoryAttributesData(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      displayType: json['display_type'] as String?,
      hasPriceCharacteristics: json['has_price_characteristics'] as bool,
      parent: ParentCategory.fromJson(json['parent'] as Map<String, dynamic>),
      attributes: (json['attributes'] as List)
          .map((attribute) => Attribute.fromJson(attribute as Map<String, dynamic>))
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
  final bool isIndividual;

  Attribute({
    required this.id,
    required this.name,
    this.value,
    required this.isIndividual,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: (json['id'] as int?) ?? 0,
      name: json['attribute'] != null
          ? (json['attribute']['name'] as String?) ?? ''
          : (json['name'] as String?) ?? '',
      value: json['value'] as String?,
      isIndividual: json['is_individual'] as bool? ?? false,
    );
  }
}