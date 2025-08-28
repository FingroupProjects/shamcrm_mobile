import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/label_list_model.dart'; // Добавляем импорт модели Branch

class Goods {
  final int id;
  final String name;
  final CategoryData category;
  final String? description;
  final int? unitId;
  final int? quantity;
  final double? discountPrice;
  final double? discountedPrice;
  final int? discountPercent;
  final bool? isActive;
  final List<GoodsFile> files;
  final List<GoodsAttribute> attributes;
  final List<GoodsVariant>? variants;
  final List<Branch>? branches;
  final String? comments;
  final bool isNew;
  final bool isPopular;
  final bool isSale;
  final Label? label; // Добавляем поле label

  Goods({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.unitId,
    this.quantity,
    this.discountPrice,
    this.discountedPrice,
    this.discountPercent,
    this.isActive,
    required this.files,
    required this.attributes,
    this.variants,
    this.branches,
    this.comments,
    required this.isNew,
    required this.isPopular,
    required this.isSale,
    this.label, // Добавляем в конструктор
  });

factory Goods.fromJson(Map<String, dynamic> json) {
  try {
    // Если JSON содержит поле "good", используем его для основных данных
    final Map<String, dynamic> data = json.containsKey('good') ? json['good'] : json;

    int? quantity;
    if (data['quantity'] != null) {
      if (data['quantity'] is int) {
        quantity = data['quantity'];
      } else if (data['quantity'] is String) {
        quantity = int.tryParse(data['quantity']);
      }
    }

    int? unitId;
    if (data['unit_id'] != null) {
      if (data['unit_id'] is int) {
        unitId = data['unit_id'];
      } else if (data['unit_id'] is String) {
        unitId = int.tryParse(data['unit_id']);
      }
    }

    double? discountPrice;
    if (json['price'] != null) { // Используем json['price'] вместо data['price']
      if (json['price'] is double) {
        discountPrice = json['price'];
      } else if (json['price'] is String) {
        discountPrice = double.tryParse(json['price']);
      }
    }

    int? discountPercent;
    double? discountedPrice;
    if (data['discounts'] != null && (data['discounts'] as List).isNotEmpty) {
      final discount = data['discounts'][0];
      discountPercent = discount['percent'] as int? ?? 0;
      if (discountPrice != null && discountPercent != 0) {
        discountedPrice = discountPrice - (discountPrice * discountPercent / 100);
      }
    }

    bool? isActive;
    if (json['is_active'] != null) { // Используем json['is_active']
      if (json['is_active'] is bool) {
        isActive = json['is_active'] as bool?;
      } else if (json['is_active'] is int) {
        isActive = json['is_active'] == 1;
      }
    }

    return Goods(
      id: json['id'] as int? ?? data['id'] as int? ?? 0, // Используем id из корня или good
      name: data['name'] as String? ?? '',
      category: data['category'] != null
          ? CategoryData.fromJson(data['category'])
          : CategoryData(id: 0, name: 'Без категории', subcategories: []),
      description: data['description'] as String?,
      unitId: unitId,
      quantity: quantity,
      discountPrice: discountPrice,
      discountedPrice: discountedPrice,
      discountPercent: discountPercent,
      isActive: isActive,
      files: (json['files'] as List<dynamic>?)?.map((f) { // Используем json['files']
            return GoodsFile.fromJson(f as Map<String, dynamic>);
          }).toList() ??
          [],
      attributes: (json['attribute_values'] as List<dynamic>?)?.map((attr) { // Используем json['attribute_values']
            return GoodsAttribute.fromJson(attr as Map<String, dynamic>);
          }).toList() ??
          [],
      variants: (json['variants'] as List<dynamic>?)?.map((v) {
        return GoodsVariant.fromJson(v as Map<String, dynamic>);
      }).toList(),
      branches: (data['branches'] as List<dynamic>?)?.map((b) {
        return Branch.fromJson(b as Map<String, dynamic>);
      }).toList(),
      comments: data['comments'] as String?,
      isNew: data['is_new'] == 1 || data['is_new'] == true,
      isPopular: data['is_popular'] == 1 || data['is_popular'] == true,
      isSale: data['is_sale'] == 1 || data['is_sale'] == true,
      label: data['label'] != null ? Label.fromJson(data['label']) : null,
    );
  } catch (e, stackTrace) {
    print('GoodsModel: Ошибка парсинга товара: $e');
    print(stackTrace);
    rethrow;
  }
}
}

class GoodsFile {
  final int id;
  final String name;
  final String path;
  final bool isMain; // Добавляем поле

  GoodsFile({
    required this.id,
    required this.name,
    required this.path,
    required this.isMain,
  });

  factory GoodsFile.fromJson(Map<String, dynamic> json) {
    return GoodsFile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      isMain: json['is_main'] as bool? ?? false,
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
      attributeName =
          json['category_attribute']['attribute']['name'] as String? ??
              'Неизвестная характеристика';
    } else {
      attributeName = 'Неизвестная характеристика';
      // //print(
      //     'GoodsModel: Missing category_attribute or attribute in JSON: $json');
    }
    // //print(
    //     'GoodsModel: Attribute name: $attributeName, value: ${json['value']}');

    return GoodsAttribute(
      id: json['attribute_id'] as int? ?? 0,
      name: attributeName,
      value: json['value'] as String? ?? '',
      isIndividual:
          json['category_attribute']?['is_individual'] as bool? ?? false,
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

class GoodsVariant {
  final int id;
  final int goodId;
  final bool isActive;
  final List<AttributeValue> attributeValues;
  final VariantPrice? variantPrice;
  final List<GoodsFile>? files;

  GoodsVariant({
    required this.id,
    required this.goodId,
    required this.isActive,
    required this.attributeValues,
    this.variantPrice,
    this.files,
  });

  factory GoodsVariant.fromJson(Map<String, dynamic> json) {
    //print('GoodsModel: Parsing variant attributes for variant ${json['id']}');
    final attributeValues =
        (json['attribute_values'] as List<dynamic>?)?.map((v) {
              // //print(
              //     'GoodsModel: Parsing attribute value - id: ${v['id']}, value: ${v['value']}');
              return AttributeValue.fromJson(v as Map<String, dynamic>);
            }).toList() ??
            [];
    // //print(
    //     'GoodsModel: Parsed ${attributeValues.length} attribute values for variant ${json['id']}');

    return GoodsVariant(
      id: json['id'] as int? ?? 0,
      goodId: json['good_id'] as int? ?? 0,
      isActive: json['is_active'] == 1,
      attributeValues: attributeValues,
      variantPrice:
          json['price'] != null ? VariantPrice.fromJson(json['price']) : null,
      files: (json['files'] as List<dynamic>?)?.map((f) {
            //print('GoodsModel: Parsing variant file - ${f['path']}');
            return GoodsFile.fromJson(f as Map<String, dynamic>);
          }).toList() ??
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
    //print(
        // 'GoodsModel: Parsing AttributeValue - category_attribute_id: ${json['category_attribute_id']}, value: ${json['value']}');
    if (json['category_attribute'] == null) {
      // //print(
        
      //     'GoodsModel: Warning: category_attribute is null for value ${json['value']}');
          
    }
    return AttributeValue(
      id: json['id'] as int? ?? 0,
      categoryAttributeId: json['category_attribute_id'] as int? ?? 0,
      value: json['value'] as String? ?? '',
      unitId: json['unit_id'] as int?,
      files: (json['files'] as List<dynamic>?)?.cast<String>(),
      categoryAttribute: json['category_attribute'] != null
          ? CategoryAttribute.fromJson(
              json['category_attribute'] as Map<String, dynamic>)
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
    //print(
        // 'GoodsModel: Parsing CategoryAttribute - id: ${json['id']}, is_individual: ${json['is_individual']}');
    if (json['attribute'] == null) {
      // //print(
      //     'GoodsModel: Warning: attribute is null for category_attribute_id ${json['id']}');
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
    // //print(
    //     'GoodsModel: Parsing Attribute - id: ${json['id']}, name: ${json['name']}');
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
    //print('GoodsModel: Parsing VariantPrice - price: $price');

    return VariantPrice(
      id: json['id'] as int? ?? 0,
      variantId: json['variant_id'] as int? ?? 0,
      price: price,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );
  }
}

