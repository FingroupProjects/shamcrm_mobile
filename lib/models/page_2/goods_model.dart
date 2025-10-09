import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/label_list_model.dart';

class Discount {
  final int id;
  final String name;
  final String from;
  final String to;
  final int percent;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  Discount({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.percent,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      percent: json['percent'] as int? ?? 0,
      deletedAt: json['deleted_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class Unit {
  final int id;
  final String name;
  final String? shortName;
  final int? amount; // Добавлено поле amount

  Unit({
    required this.id,
    required this.name,
    this.shortName,
    this.amount,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      shortName: json['short_name'] as String?,
      amount: json['amount'] as int?,
    );
  }
}

class Measurement {
  final int id;
  final int goodId;
  final int unitId;
  final double amount;
  final Unit? unit; // Изменено на nullable

  Measurement({
    required this.id,
    required this.goodId,
    required this.unitId,
    required this.amount,
    this.unit, // Может быть null
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      id: json['id'] as int? ?? 0,
      goodId: json['good_id'] as int? ?? 0,
      unitId: json['unit_id'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] != null ? Unit.fromJson(json['unit'] as Map<String, dynamic>) : null,
    );
  }
}

class Goods {
  final int id;
  final String name;
  final CategoryData category;
  final String? description;
  final int? unitId;
  final int? quantity;
  final String? price;
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
  final Label? label;
  final List<Discount>? discount;
  final String? article;
  final List<Unit>? units;
  final List<Measurement>? measurements;

  Goods({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.unitId,
    this.quantity,
    this.price,
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
    this.label,
    this.discount,
    this.article,
    this.units,
    this.measurements,
  });

  factory Goods.fromJson(Map<String, dynamic> json) {
    try {
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

    String? priceString = json['price']?.toString();  // ИСПРАВЛЕННАЯ СТРОКА 164
double? discountPrice;
if (priceString != null) {
  discountPrice = double.tryParse(priceString);
}

      int? discountPercent;
      double? discountedPrice;

      List<Discount>? discounts;
      if (json['discount'] != null && json['discount'] is List) {
        discounts = (json['discount'] as List).map((d) => Discount.fromJson(d)).toList();
        if (discounts.isNotEmpty && discountPrice != null) {
          final now = DateTime.now();
          for (var discount in discounts) {
            try {
              final from = DateTime.parse(discount.from);
              final to = DateTime.parse(discount.to);
              if (now.isAfter(from) && now.isBefore(to)) {
                discountPercent = discount.percent;
                discountedPrice = discountPrice * (1 - discount.percent / 100);
                break;
              }
            } catch (e) {
              print('Ошибка парсинга даты скидки: $e');
            }
          }
        }
      }

      bool? isActive;
      if (json['is_active'] != null) {
        if (json['is_active'] is bool) {
          isActive = json['is_active'] as bool?;
        } else if (json['is_active'] is int) {
          isActive = json['is_active'] == 1;
        }
      }

      List<Unit>? units;
      if (data['units'] != null && data['units'] is List) {
        units = (data['units'] as List).map((u) => Unit.fromJson(u as Map<String, dynamic>)).toList();
      }

      List<Measurement>? measurements;
      if (data['measurements'] != null && data['measurements'] is List) {
        measurements = (data['measurements'] as List)
            .where((m) => m['unit'] != null) // Фильтруем элементы с null unit
            .map((m) => Measurement.fromJson(m as Map<String, dynamic>))
            .toList();
      }

      return Goods(
        id: json['id'] as int? ?? data['id'] as int? ?? 0,
        name: data['name'] as String? ?? '',
        category: data['category'] != null
            ? CategoryData.fromJson(data['category'])
            : CategoryData(id: 0, name: 'Без категории', subcategories: []),
        description: data['description'] as String?,
        unitId: unitId,
        quantity: quantity,
        price: priceString,
        discountPrice: discountPrice,
        discountedPrice: discountedPrice,
        discountPercent: discountPercent,
        isActive: isActive,
        files: (json['files'] as List<dynamic>?)?.map((f) {
              return GoodsFile.fromJson(f as Map<String, dynamic>);
            }).toList() ??
            [],
        attributes: (json['attribute_values'] as List<dynamic>?)?.map((attr) {
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
        discount: discounts,
        article: data['article'] as String?,
        units: units,
        measurements: measurements,
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
  final bool isMain;

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
    }

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
  final attributeValues =
      (json['attribute_values'] as List<dynamic>?)?.map((v) {
            return AttributeValue.fromJson(v as Map<String, dynamic>);
          }).toList() ??
          [];

  // Обработка price - может быть объектом, строкой или числом
  VariantPrice? variantPrice;
  if (json['price'] != null) {
    if (json['price'] is Map<String, dynamic>) {
      // Если price - это объект
      variantPrice = VariantPrice.fromJson(json['price']);
    } else {
      // Если price - это строка или число, создаём простой объект
      double priceValue = 0.0;
      if (json['price'] is String) {
        priceValue = double.tryParse(json['price']) ?? 0.0;
      } else if (json['price'] is num) {
        priceValue = (json['price'] as num).toDouble();
      }
      
      variantPrice = VariantPrice(
        id: 0,
        variantId: json['id'] as int? ?? 0,
        price: priceValue,
        startDate: null,
        endDate: null,
      );
    }
  }

  return GoodsVariant(
    id: json['id'] as int? ?? 0,
    goodId: json['good_id'] as int? ?? 0,
    isActive: json['is_active'] == 1,
    attributeValues: attributeValues,
    variantPrice: variantPrice,
    files: (json['files'] as List<dynamic>?)?.map((f) {
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

    return VariantPrice(
      id: json['id'] as int? ?? 0,
      variantId: json['variant_id'] as int? ?? 0,
      price: price,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );
  }
}