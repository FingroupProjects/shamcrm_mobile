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
  final int? id;
  final String? name;
  final String? shortName;
  final bool? isBase;
  final num? amount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Unit({
    this.id,
    this.name,
    this.shortName,
    this.isBase,
    this.amount,
    this.createdAt,
    this.updatedAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: _parseInt(json['id']),
      name: json['name'],
      shortName: json['short_name'],
      isBase: json['is_base'],
      amount: _parseNum(json['amount']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': shortName,
      'is_base': isBase,
      'amount': amount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('Error parsing int from string "$value": $e');
        return null;
      }
    }
    return null;
  }

  static DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null || dateStr == '' || dateStr is! String) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      print('Error parsing date $dateStr: $e');
      return null;
    }
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      if (value is int) return value;
      if (value is double) {
        if (value == value.toInt()) {
          return value.toInt();
        }
        return value;
      }
      return value;
    }
    if (value is String) {
      if (value.isEmpty) return null;
      try {
        double parsed = double.parse(value.replaceAll(',', '.'));
        
        if (parsed == parsed.toInt()) {
          return parsed.toInt(); // Return as int (1, 2, 3, etc.)
        }
        return parsed; // Return as double (1.23, 90.30, etc.)
      } catch (e) {
        print('Error parsing num from string "$value": $e');
        return null;
      }
    }
    return null;
  }
}

class Measurement {
  final int id;
  final int goodId;
  final int unitId;
  final num? amount; // Оставляем тип num?
  final Unit? unit;

  Measurement({
    required this.id,
    required this.goodId,
    required this.unitId,
    this.amount,
    this.unit,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    // ИСПРАВЛЕНО: Безопасное преобразование amount из String в num
    num? parsedAmount;
    if (json['amount'] != null) {
      if (json['amount'] is num) {
        parsedAmount = json['amount'] as num;
      } else if (json['amount'] is String) {
        parsedAmount = num.tryParse(json['amount'] as String);
      }
    }

    return Measurement(
      id: json['id'] as int? ?? 0,
      goodId: json['good_id'] as int? ?? 0,
      unitId: json['unit_id'] as int? ?? 0,
      amount: parsedAmount, // ИСПРАВЛЕНО: используем безопасно распарсенное значение
      unit: json['unit'] != null 
          ? Unit.fromJson(json['unit'] as Map<String, dynamic>) 
          : null,
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
  final Unit? unit; // Добавляем поле unit для AddGoodsScreen и EditGoodsScreen

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
    this.unit,
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

      dynamic priceRaw = json['price'];
      String? priceString;
      double? discountPrice;
      if (priceRaw is String) {
        priceString = priceRaw;
        discountPrice = double.tryParse(priceRaw);
      } else if (priceRaw is num) {
        priceString = priceRaw.toString();
        discountPrice = priceRaw.toDouble();
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
        unit: data['unit'] != null ? Unit.fromJson(data['unit']) : null, // Инициализируем поле unit

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
  // final VariantPrice? variantPrice; // instead of price NEW price String
  final String price; // NEW price String
  final List<GoodsFile>? files;

  GoodsVariant({
    required this.id,
    required this.goodId,
    required this.isActive,
    required this.attributeValues,
    // this.variantPrice,
    required this.price,
    this.files,
  });

  factory GoodsVariant.fromJson(Map<String, dynamic> json) {
    final attributeValues =
        (json['attributes'] as List<dynamic>?)?.map((v) {
              return AttributeValue.fromJson(v as Map<String, dynamic>);
            }).toList() ??
            [];

    return GoodsVariant(
      id: json['id'] as int? ?? 0,
      goodId: json['good_id'] as int? ?? 0,
      isActive: json['is_active'] == 1,
      attributeValues: attributeValues,
      // variantPrice:
      //     json['price'] != null ? VariantPrice.fromJson(json['price']) : null,
      price: json['price'] != null
          ? (json['price'] is String
              ? json['price'] as String
              : (json['price'] is num
                  ? (json['price'] as num).toString()
                  : '0'))
          : '0',
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