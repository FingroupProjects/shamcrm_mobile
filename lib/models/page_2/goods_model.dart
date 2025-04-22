import 'package:crm_task_manager/models/page_2/category_model.dart';

class Goods {
  final int id;
  final String name;
  final CategoryData category;
  final String? description;
  final int? unitId;
  final int? quantity;
  final double? discountPrice;
  final bool? isActive;
  final List<GoodsFile> files;
  final List<GoodsAttribute> attributes;
  final List<GoodsVariant>? variants;

  Goods({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.unitId,
    this.quantity,
    this.discountPrice,
    this.isActive,
    required this.files,
    required this.attributes,
    this.variants,
  });

  factory Goods.fromJson(Map<String, dynamic> json) {
    try {
      int? quantity;
      if (json['quantity'] != null) {
        if (json['quantity'] is int) {
          quantity = json['quantity'];
        } else if (json['quantity'] is String) {
          quantity = int.tryParse(json['quantity']);
        }
      }

      int? unitId;
      if (json['unit_id'] != null) {
        if (json['unit_id'] is int) {
          unitId = json['unit_id'];
        } else if (json['unit_id'] is String) {
          unitId = int.tryParse(json['unit_id']);
        }
      }

      double? discountPrice;
      if (json['discount_price'] != null) {
        if (json['discount_price'] is double) {
          discountPrice = json['discount_price'];
        } else if (json['discount_price'] is String) {
          discountPrice = double.tryParse(json['discount_price']);
        }
      }

      print('GoodsModel: Parsing Goods JSON - id: ${json['id']}, name: ${json['name']}');
      return Goods(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        category: json['category'] != null
            ? CategoryData.fromJson(json['category'])
            : CategoryData(id: 0, name: 'Без категории', subcategories: []),
        description: json['description'] as String?,
        unitId: unitId,
        quantity: quantity,
        discountPrice: discountPrice,
        isActive: json['is_active'] as bool?,
        files: (json['files'] as List<dynamic>?)
                ?.map((f) {
                  print('GoodsModel: Parsing file - ${f['path']}');
                  return GoodsFile.fromJson(f as Map<String, dynamic>);
                })
                .toList() ??
            [],
        attributes: (json['attributes'] as List<dynamic>?)
                ?.map((attr) {
                  print('GoodsModel: Parsing attribute - ${attr['value']}');
                  return GoodsAttribute.fromJson(attr as Map<String, dynamic>);
                })
                .toList() ??
            [],
        variants: (json['variants'] as List<dynamic>?)
                ?.map((v) {
                  print('GoodsModel: Parsing variant - id: ${v['id']}');
                  return GoodsVariant.fromJson(v as Map<String, dynamic>);
                })
                .toList(),
      );
    } catch (e, stackTrace) {
      print('GoodsModel: Error parsing Goods: $e');
      print(stackTrace);
      rethrow;
    }
  }
}

class GoodsFile {
  final int id;
  final String name;
  final String path;

  GoodsFile({
    required this.id,
    required this.name,
    required this.path,
  });

  factory GoodsFile.fromJson(Map<String, dynamic> json) {
    return GoodsFile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
    );
  }
}

class GoodsAttribute {
  final int id;
  final String name;
  final String value;
  final bool isIndividual;
  final List<String>? images;

  GoodsAttribute({
    required this.id,
    required this.name,
    required this.value,
    required this.isIndividual,
    this.images,
  });

  factory GoodsAttribute.fromJson(Map<String, dynamic> json) {
    String attributeName = '';
    if (json['category_attribute'] != null &&
        json['category_attribute']['attribute'] != null) {
      attributeName = json['category_attribute']['attribute']['name'] as String? ?? 'Неизвестная характеристика';
    } else {
      attributeName = 'Неизвестная характеристика';
      print('GoodsModel: Missing category_attribute or attribute in JSON: $json');
    }
    print('GoodsModel: Attribute name: $attributeName, value: ${json['value']}');

    return GoodsAttribute(
      id: json['id'] as int? ?? 0,
      name: attributeName,
      value: json['value'] as String? ?? '',
      isIndividual: json['category_attribute']?['is_individual'] as bool? ?? false,
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

class GoodsVariant {
  final int id;
  final int goodId;
  final bool isActive;
  final List<VariantAttribute> variantAttributes;
  final VariantPrice? variantPrice;
  final List<GoodsFile>? files;

  GoodsVariant({
    required this.id,
    required this.goodId,
    required this.isActive,
    required this.variantAttributes,
    this.variantPrice,
    this.files,
  });

  factory GoodsVariant.fromJson(Map<String, dynamic> json) {
    print('GoodsModel: Parsing variant attributes for variant ${json['id']}');
    return GoodsVariant(
      id: json['id'] as int? ?? 0,
      goodId: json['good_id'] as int? ?? 0,
      isActive: json['is_active'] == 1,
      variantAttributes: (json['attribute_values'] as List<dynamic>?)
              ?.map((v) {
                print('GoodsModel: Parsing attribute value - ${v['value']}');
                return VariantAttribute.fromJson(v as Map<String, dynamic>);
              })
              .toList() ??
          [],
      variantPrice: json['variant_price'] != null
          ? VariantPrice.fromJson(json['variant_price'])
          : null,
      files: (json['files'] as List<dynamic>?)
              ?.map((f) {
                print('GoodsModel: Parsing variant file - ${f['path']}');
                return GoodsFile.fromJson(f as Map<String, dynamic>);
              })
              .toList() ??
          [],
    );
  }
}

class VariantAttribute {
  final int id;
  final int variantId;
  final List<AttributeValue> attributeValues;

  VariantAttribute({
    required this.id,
    required this.variantId,
    required this.attributeValues,
  });

  factory VariantAttribute.fromJson(Map<String, dynamic> json) {
    print('GoodsModel: Parsing VariantAttribute - id: ${json['id']}, variant_id: ${json['variant_id']}');
    print('GoodsModel: Variant attribute_values: ${json['attribute_values']}');
    return VariantAttribute(
      id: json['id'] as int? ?? 0,
      variantId: json['variant_id'] as int? ?? 0,
      attributeValues: (json['attribute_values'] as List<dynamic>?)
              ?.map((v) {
                print('GoodsModel: Parsing nested attribute value - ${v['value']}');
                return AttributeValue.fromJson(v as Map<String, dynamic>);
              })
              .toList() ??
          [],
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
    print('GoodsModel: Parsing AttributeValue - category_attribute_id: ${json['category_attribute_id']}, value: ${json['value']}');
    if (json['category_attribute'] == null) {
      print('GoodsModel: Warning: category_attribute is null for value ${json['value']}');
    }
    return AttributeValue(
      id: json['id'] as int? ?? 0,
      categoryAttributeId: json['category_attribute_id'] as int? ?? 0,
      value: json['value'] as String? ?? '',
      unitId: json['unit_id'] as int?,
      files: (json['files'] as List<dynamic>?)?.cast<String>(),
      categoryAttribute: json['category_attribute'] != null
          ? CategoryAttribute.fromJson(json['category_attribute'] as Map<String, dynamic>)
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
    print('GoodsModel: Parsing CategoryAttribute - id: ${json['id']}, is_individual: ${json['is_individual']}');
    if (json['attribute'] == null) {
      print('GoodsModel: Warning: attribute is null for category_attribute_id ${json['id']}');
    }
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
    print('GoodsModel: Parsing Attribute - id: ${json['id']}, name: ${json['name']}');
    return Attribute(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Неизвестная характеристика',
    );
  }
}

class VariantPrice {
  final int id;
  final int variantId;
  final double price;
  final String? startDate;
  final String? endDate;

  VariantPrice({
    required this.id,
    required this.variantId,
    required this.price,
    this.startDate,
    this.endDate,
  });

  factory VariantPrice.fromJson(Map<String, dynamic> json) {
    double price = 0;
    if (json['price'] != null) {
      if (json['price'] is double) {
        price = json['price'];
      } else if (json['price'] is String) {
        price = double.tryParse(json['price']) ?? 0.0;
      }
    }
    print('GoodsModel: Parsing VariantPrice - price: $price');

    return VariantPrice(
      id: json['id'] as int? ?? 0,
      variantId: json['variant_id'] as int? ?? 0,
      price: price,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );
  }
}