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
        //print('Error parsing int from string "$value": $e');
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
      //print('Error parsing date $dateStr: $e');
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
        //print('Error parsing num from string "$value": $e');
        return null;
      }
    }
    return null;
  }

  toString() {
    return 'Unit(id: $id, name: $name, shortName: $shortName, isBase: $isBase, amount: $amount, createdAt: $createdAt, updatedAt: $updatedAt)';
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
      amount:
          parsedAmount, // ИСПРАВЛЕНО: используем безопасно распарсенное значение
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
  final String? barcode;
  final String? article;
  final List<Unit>? units;
  final List<Measurement>? measurements;
  final Unit? unit; // Добавляем поле unit для AddGoodsScreen и EditGoodsScreen
  final bool? isService;
  final String? productionType;
  final List<MaterialGood>? materialGoods;
  final List<RelatedGood>? relatedGoods;
  final String? availabilityStatus;
  final int? sortOrder;

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
    this.barcode,
    this.article,
    this.units,
    this.measurements,
    this.unit,
    this.isService,
    this.productionType,
    this.materialGoods,
    this.relatedGoods,
    this.availabilityStatus,
    this.sortOrder,
  });

  factory Goods.fromJson(Map<String, dynamic> json) {
    try {
      final Map<String, dynamic> data =
          json.containsKey('good') ? json['good'] : json;

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
        discounts = (json['discount'] as List)
            .map((d) => Discount.fromJson(d))
            .toList();
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
              //print('Ошибка парсинга даты скидки: $e');
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

      bool? isService;
      if (json['is_service'] != null) {
        if (json['is_service'] is bool) {
          isService = json['is_service'] as bool?;
        } else if (json['is_service'] is int) {
          isService = json['is_service'] == 1;
        }
      }

      List<Unit>? units;
      if (data['units'] != null && data['units'] is List) {
        units = (data['units'] as List)
            .map((u) => Unit.fromJson(u as Map<String, dynamic>))
            .toList();
      }

      List<Measurement>? measurements;
      if (data['measurements'] != null && data['measurements'] is List) {
        measurements = (data['measurements'] as List)
            .where((m) => m['unit'] != null) // Фильтруем элементы с null unit
            .map((m) => Measurement.fromJson(m as Map<String, dynamic>))
            .toList();
      }

      List<MaterialGood>? materialGoods;
      if (data['material_goods'] != null && data['material_goods'] is List) {
        materialGoods = (data['material_goods'] as List)
            .map((m) => MaterialGood.fromJson(m as Map<String, dynamic>))
            .toList();
      }

      List<RelatedGood>? relatedGoods;
      final relatedsData = data['related_goods'] ??
          json['related_goods'] ??
          data['relateds'] ??
          json['relateds'];
      if (relatedsData != null && relatedsData is List) {
        relatedGoods = relatedsData
            .map((r) => RelatedGood.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      String? parseStatus(dynamic value) {
        if (value == null) return null;
        if (value is String || value is num || value is bool) {
          final text = value.toString().trim();
          return text.isEmpty ? null : text;
        }
        if (value is Map<String, dynamic>) {
          for (final key in ['name', 'title', 'value', 'label', 'status']) {
            final nested = parseStatus(value[key]);
            if (nested != null) return nested;
          }
        }
        return null;
      }

      int? parseSortOrder(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value.trim());
        return null;
      }

      final availabilityStatus = parseStatus(data['status']) ??
          parseStatus(json['status']) ??
          parseStatus(data['status_name']) ??
          parseStatus(json['status_name']) ??
          parseStatus(data['availability_status']) ??
          parseStatus(json['availability_status']) ??
          parseStatus(data['availability']) ??
          parseStatus(json['availability']) ??
          parseStatus(data['apartment_status']) ??
          parseStatus(json['apartment_status']);

      // Парсим файлы: проверяем несколько возможных мест
      List<GoodsFile> files = [];
      if (json['files'] != null && json['files'] is List) {
        files = (json['files'] as List<dynamic>).map((f) {
          return GoodsFile.fromJson(f as Map<String, dynamic>);
        }).toList();
      } else if (data['files'] != null && data['files'] is List) {
        files = (data['files'] as List<dynamic>).map((f) {
          return GoodsFile.fromJson(f as Map<String, dynamic>);
        }).toList();
      } else if (json.containsKey('good') &&
          json['good'] is Map &&
          (json['good'] as Map)['files'] != null) {
        final goodData = json['good'] as Map<String, dynamic>;
        if (goodData['files'] is List) {
          files = (goodData['files'] as List<dynamic>).map((f) {
            return GoodsFile.fromJson(f as Map<String, dynamic>);
          }).toList();
        }
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
        isService: isService,
        files: files,
        attributes: ((json['attribute_values'] as List<dynamic>?) ??
                (data['attributes'] as List<dynamic>?) ??
                const [])
            .map((attr) {
          return GoodsAttribute.fromJson(attr as Map<String, dynamic>);
        }).toList(),
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
        barcode: data['barcode'] as String? ?? data['article'] as String?,
        article: data['article'] as String?,
        units: units,
        measurements: measurements,
        unit: data['unit'] != null
            ? Unit.fromJson(data['unit'])
            : null, // Инициализируем поле unit
        productionType: data['production_type'] as String?,
        materialGoods: materialGoods,
        relatedGoods: relatedGoods,
        availabilityStatus: availabilityStatus,
        sortOrder: parseSortOrder(data['sort']) ??
            parseSortOrder(json['sort']) ??
            parseSortOrder(data['sort_order']) ??
            parseSortOrder(json['sort_order']) ??
            parseSortOrder(data['order']) ??
            parseSortOrder(json['order']),
      );
    } catch (e, stackTrace) {
      //print('GoodsModel: Ошибка парсинга товара: $e');
      //print(stackTrace);
      rethrow;
    }
  }
  String? get mainImageUrl {
    if (files.isEmpty) return null;

    // Ищем главное изображение
    try {
      final mainFile = files.firstWhere(
        (file) => file.isMain,
        orElse: () => files.first,
      );

      // Проверяем, является ли путь уже полным URL
      if (mainFile.path.startsWith('http://') ||
          mainFile.path.startsWith('https://')) {
        return mainFile.path;
      }

      // Формируем полный URL из относительного пути
      return 'https://shamcrm.com/storage/${mainFile.path}';
    } catch (e) {
      //print('Ошибка получения главного изображения: $e');
      return null;
    }
  }

  String get characteristicsSummary {
    return characteristicLabels.join(' / ');
  }

  List<String> get characteristicLabels {
    return attributes
        .where((attribute) => attribute.value.trim().isNotEmpty)
        .map((attribute) {
      final name = attribute.name.trim();
      final value = attribute.value.trim();
      if (name.isEmpty || name == 'Неизвестная характеристика') {
        return value;
      }
      return '$name: $value';
    }).toList();
  }
}

class MaterialGoodPivot {
  final int? producedGoodId;
  final int? materialGoodId;
  final num? norm;

  MaterialGoodPivot({
    this.producedGoodId,
    this.materialGoodId,
    this.norm,
  });

  factory MaterialGoodPivot.fromJson(Map<String, dynamic> json) {
    return MaterialGoodPivot(
      producedGoodId: Unit._parseInt(json['produced_good_id']),
      materialGoodId: Unit._parseInt(json['material_good_id']),
      norm: Unit._parseNum(json['norm']),
    );
  }
}

class MaterialGood {
  final int id;
  final int? goodId;
  final String? fullName;
  final Goods? good;
  final VariantPrice? price;
  final MaterialGoodPivot? pivot;

  MaterialGood({
    required this.id,
    this.goodId,
    this.fullName,
    this.good,
    this.price,
    this.pivot,
  });

  factory MaterialGood.fromJson(Map<String, dynamic> json) {
    final parsedGood = json['good'] != null
        ? Goods.fromJson(json['good'] as Map<String, dynamic>)
        : null;
    final variantId = Unit._parseInt(json['variant_id']);
    final parsedPrice = json['price'] != null
        ? (json['price'] is Map<String, dynamic>
            ? VariantPrice.fromJson(json['price'] as Map<String, dynamic>)
            : VariantPrice(
                id: 0,
                variantId: variantId ?? 0,
                price: Unit._parseNum(json['price'])?.toDouble() ?? 0,
              ))
        : null;
    final parsedPivot = json['pivot'] != null
        ? MaterialGoodPivot.fromJson(json['pivot'] as Map<String, dynamic>)
        : (json['norm'] != null
            ? MaterialGoodPivot(
                producedGoodId: Unit._parseInt(json['produced_good_id']),
                materialGoodId: Unit._parseInt(json['material_good_id']) ??
                    Unit._parseInt(json['good_id']) ??
                    parsedGood?.id,
                norm: Unit._parseNum(json['norm']),
              )
            : null);

    return MaterialGood(
      id: Unit._parseInt(json['id']) ?? variantId ?? 0,
      goodId: Unit._parseInt(json['good_id']) ?? parsedGood?.id,
      fullName: json['full_name'] as String? ?? json['name'] as String?,
      good: parsedGood,
      price: parsedPrice,
      pivot: parsedPivot,
    );
  }

  String get displayName => fullName ?? good?.name ?? '';

  Unit? get displayUnit {
    if (good?.unit != null) return good?.unit;
    if (good?.units?.isNotEmpty == true) return good!.units!.first;
    return null;
  }
}

class RelatedGood {
  final int? id;
  final int? variantId;
  final bool isRequired;
  final String? fullName;
  final double? price;

  RelatedGood({
    this.id,
    this.variantId,
    required this.isRequired,
    this.fullName,
    this.price,
  });

  factory RelatedGood.fromJson(Map<String, dynamic> json) {
    final variantData = _extractVariantData(json);
    final pivotData = json['pivot'] is Map<String, dynamic>
        ? json['pivot'] as Map<String, dynamic>
        : null;
    final parsedPrice = _parsePrice(json['price']) ??
        _parsePrice(variantData?['price']) ??
        _parsePrice((json['good'] is Map<String, dynamic>)
            ? (json['good'] as Map<String, dynamic>)['price']
            : null);

    String? displayName =
        json['full_name']?.toString() ?? json['name']?.toString();

    if ((displayName == null || displayName.isEmpty) && variantData != null) {
      displayName = variantData['full_name']?.toString() ??
          variantData['name']?.toString();
      final nestedGood = variantData['good'];
      if ((displayName == null || displayName.isEmpty) &&
          nestedGood is Map<String, dynamic>) {
        displayName = nestedGood['name']?.toString();
      }
    }

    if ((displayName == null || displayName.isEmpty) &&
        json['good'] is Map<String, dynamic>) {
      displayName = (json['good'] as Map<String, dynamic>)['name']?.toString();
    }

    return RelatedGood(
      id: Unit._parseInt(json['id']),
      variantId: Unit._parseInt(json['variant_id']) ??
          Unit._parseInt(variantData?['id']) ??
          (variantData == null ? Unit._parseInt(json['id']) : null),
      isRequired: _parseBool(json['is_required']) ||
          _parseBool(pivotData?['is_required']),
      fullName: displayName,
      price: parsedPrice,
    );
  }

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!;
    }
    if (variantId != null) {
      return 'Вариант #$variantId';
    }
    return 'Неизвестный товар';
  }

  static Map<String, dynamic>? _extractVariantData(Map<String, dynamic> json) {
    final candidates = [
      json['variant'],
      json['good_variant'],
      json['related_variant'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        return candidate;
      }
    }

    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }

  static double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is Map<String, dynamic>) {
      return _parsePrice(value['price']);
    }
    return null;
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
    } else if (json['attribute'] != null &&
        json['attribute'] is Map<String, dynamic> &&
        json['attribute']['attribute'] != null) {
      attributeName = json['attribute']['attribute']['name'] as String? ??
          'Неизвестная характеристика';
    } else {
      attributeName = 'Неизвестная характеристика';
    }

    return GoodsAttribute(
      id: json['attribute_id'] as int? ??
          (json['attribute']?['attribute']?['id'] as int?) ??
          0,
      name: attributeName,
      value: json['value'] as String? ?? '',
      isIndividual: json['category_attribute']?['is_individual'] as bool? ??
          json['attribute']?['is_individual'] as bool? ??
          false,
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
  final String? barcode;
  final List<GoodsFile>? files;

  GoodsVariant({
    required this.id,
    required this.goodId,
    required this.isActive,
    required this.attributeValues,
    // this.variantPrice,
    required this.price,
    this.barcode,
    this.files,
  });

  factory GoodsVariant.fromJson(Map<String, dynamic> json) {
    final attributeValues = (json['attributes'] as List<dynamic>?)?.map((v) {
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
      barcode: json['barcode']?.toString(),
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
