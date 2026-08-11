import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/label_list_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

List<T>? _nullableList<T>(List<T> list) => list.isEmpty ? null : list;

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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      from: SafeConverters.toSafeString(json['from']),
      to: SafeConverters.toSafeString(json['to']),
      percent: SafeConverters.toInt(json['percent']),
      deletedAt: SafeConverters.toStringOrNull(json['deleted_at']),
      createdAt: SafeConverters.toSafeString(json['created_at']),
      updatedAt: SafeConverters.toSafeString(json['updated_at']),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      shortName: SafeConverters.toStringOrNull(json['short_name']),
      isBase: SafeConverters.toBoolOrNull(json['is_base']),
      amount: SafeConverters.toNumOrNull(json['amount']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
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

  static int? _parseInt(dynamic value) => SafeConverters.toIntOrNull(value);

  static num? _parseNum(dynamic value) => SafeConverters.toNumOrNull(value);

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
    return Measurement(
      id: SafeConverters.toInt(json['id']),
      goodId: SafeConverters.toInt(json['good_id']),
      unitId: SafeConverters.toInt(json['unit_id']),
      amount: SafeConverters.toNumOrNull(json['amount']),
      unit: SafeConverters.toMapOrNull(json['unit']) != null
          ? Unit.fromJson(SafeConverters.toMap(json['unit']))
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
  final int? orderId;
  final String? orderNumber;

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
    this.orderId,
    this.orderNumber,
  });

  factory Goods.fromJson(Map<String, dynamic> json) {
    try {
      final Map<String, dynamic> data =
          json.containsKey('good') ? SafeConverters.toMap(json['good']) : json;

      final quantity = SafeConverters.toIntOrNull(data['quantity']);
      final unitId = SafeConverters.toIntOrNull(data['unit_id']);

      final priceRaw = json['price'];
      String? priceString;
      double? discountPrice;
      if (priceRaw != null) {
        priceString = SafeConverters.toSafeString(priceRaw);
        discountPrice = SafeConverters.toDoubleOrNull(priceRaw);
      }

      int? discountPercent;
      double? discountedPrice;

      List<Discount>? discounts;
      final discountList = SafeConverters.toList(json['discount']);
      if (discountList.isNotEmpty) {
        discounts = discountList
            .map((d) => Discount.fromJson(SafeConverters.toMap(d)))
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
              // ignore discount date parse errors
            }
          }
        }
      }

      final isActive = SafeConverters.toBoolOrNull(json['is_active']);
      final isService = SafeConverters.toBoolOrNull(json['is_service']);

      List<Unit>? units;
      final unitsList = SafeConverters.toList(data['units']);
      if (unitsList.isNotEmpty) {
        units = unitsList
            .map((u) => Unit.fromJson(SafeConverters.toMap(u)))
            .toList();
      }

      List<Measurement>? measurements;
      final measurementsList = SafeConverters.toList(data['measurements']);
      if (measurementsList.isNotEmpty) {
        measurements = measurementsList
            .where((m) => SafeConverters.toMap(m)['unit'] != null)
            .map((m) => Measurement.fromJson(SafeConverters.toMap(m)))
            .toList();
      }

      List<MaterialGood>? materialGoods;
      final materialGoodsList = SafeConverters.toList(data['material_goods']);
      if (materialGoodsList.isNotEmpty) {
        materialGoods = materialGoodsList
            .map((m) => MaterialGood.fromJson(SafeConverters.toMap(m)))
            .toList();
      }

      List<RelatedGood>? relatedGoods;
      final relatedsData = data['related_goods'] ??
          json['related_goods'] ??
          data['relateds'] ??
          json['relateds'];
      final relatedsList = SafeConverters.toList(relatedsData);
      if (relatedsList.isNotEmpty) {
        relatedGoods = relatedsList
            .map((r) => RelatedGood.fromJson(SafeConverters.toMap(r)))
            .toList();
      }

      String? parseStatus(dynamic value) {
        if (value == null) return null;
        if (value is String || value is num || value is bool) {
          final text = value.toString().trim();
          return text.isEmpty ? null : text;
        }
        final valueMap = SafeConverters.toMapOrNull(value);
        if (valueMap != null) {
          for (final key in ['name', 'title', 'value', 'label', 'status']) {
            final nested = parseStatus(valueMap[key]);
            if (nested != null) return nested;
          }
        }
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

      List<GoodsFile> files = [];
      final filesSources = [
        json['files'],
        data['files'],
        if (json.containsKey('good'))
          SafeConverters.toMapOrNull(json['good'])?['files'],
      ];
      for (final source in filesSources) {
        final sourceList = SafeConverters.toList(source);
        if (sourceList.isNotEmpty) {
          files = sourceList
              .map((f) => GoodsFile.fromJson(SafeConverters.toMap(f)))
              .toList();
          break;
        }
      }

      final attributesRaw = SafeConverters.toList(
          json['attribute_values'] ?? data['attributes']);

      return Goods(
        id: SafeConverters.toInt(json['id'] != null ? json['id'] : data['id']),
        name: SafeConverters.toSafeString(data['name']),
        category: SafeConverters.toMapOrNull(data['category']) != null
            ? CategoryData.fromJson(SafeConverters.toMap(data['category']))
            : CategoryData(id: 0, name: 'Без категории', subcategories: []),
        description: SafeConverters.toStringOrNull(data['description']),
        unitId: unitId,
        quantity: quantity,
        price: priceString,
        discountPrice: discountPrice,
        discountedPrice: discountedPrice,
        discountPercent: discountPercent,
        isActive: isActive,
        isService: isService,
        files: files,
        attributes: attributesRaw
            .map((attr) => GoodsAttribute.fromJson(SafeConverters.toMap(attr)))
            .toList(),
        variants: _nullableList(SafeConverters.toList(json['variants'])
            .map((v) => GoodsVariant.fromJson(SafeConverters.toMap(v)))
            .toList()),
        branches: _nullableList(SafeConverters.toList(data['branches'])
            .map((b) => Branch.fromJson(SafeConverters.toMap(b)))
            .toList()),
        comments: SafeConverters.toStringOrNull(data['comments']),
        isNew: SafeConverters.toBool(data['is_new']),
        isPopular: SafeConverters.toBool(data['is_popular']),
        isSale: SafeConverters.toBool(data['is_sale']),
        label: SafeConverters.toMapOrNull(data['label']) != null
            ? Label.fromJson(SafeConverters.toMap(data['label']))
            : null,
        discount: discounts,
        barcode: SafeConverters.toStringOrNull(data['barcode']) ??
            SafeConverters.toStringOrNull(data['article']),
        article: SafeConverters.toStringOrNull(data['article']),
        units: units,
        measurements: measurements,
        unit: SafeConverters.toMapOrNull(data['unit']) != null
            ? Unit.fromJson(SafeConverters.toMap(data['unit']))
            : null,
        productionType: SafeConverters.toStringOrNull(data['production_type']),
        materialGoods: materialGoods,
        relatedGoods: relatedGoods,
        availabilityStatus: availabilityStatus,
        sortOrder: SafeConverters.toIntOrNull(data['sort']) ??
            SafeConverters.toIntOrNull(json['sort']) ??
            SafeConverters.toIntOrNull(data['sort_order']) ??
            SafeConverters.toIntOrNull(json['sort_order']) ??
            SafeConverters.toIntOrNull(data['order']) ??
            SafeConverters.toIntOrNull(json['order']),
        orderId: SafeConverters.toIntOrNull(data['order_id']) ??
            SafeConverters.toIntOrNull(json['order_id']),
        orderNumber: SafeConverters.toStringOrNull(data['order_number'],
                emptyAsNull: true) ??
            SafeConverters.toStringOrNull(json['order_number'], emptyAsNull: true),
      );
    } catch (e) {
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
    final parsedGood = SafeConverters.toMapOrNull(json['good']) != null
        ? Goods.fromJson(SafeConverters.toMap(json['good']))
        : null;
    final variantId = Unit._parseInt(json['variant_id']);
    final priceRaw = json['price'];
    final parsedPrice = priceRaw != null
        ? (SafeConverters.toMapOrNull(priceRaw) != null
            ? VariantPrice.fromJson(SafeConverters.toMap(priceRaw))
            : VariantPrice(
                id: 0,
                variantId: variantId ?? 0,
                price: SafeConverters.toDouble(priceRaw),
              ))
        : null;
    final parsedPivot = SafeConverters.toMapOrNull(json['pivot']) != null
        ? MaterialGoodPivot.fromJson(SafeConverters.toMap(json['pivot']))
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
      fullName: SafeConverters.toStringOrNull(json['full_name']) ??
          SafeConverters.toStringOrNull(json['name']),
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
    final pivotData = SafeConverters.toMapOrNull(json['pivot']);
    final goodMap = SafeConverters.toMapOrNull(json['good']);
    final parsedPrice = _parsePrice(json['price']) ??
        _parsePrice(variantData?['price']) ??
        _parsePrice(goodMap?['price']);

    String? displayName =
        SafeConverters.toStringOrNull(json['full_name']) ??
            SafeConverters.toStringOrNull(json['name']);

    if ((displayName == null || displayName.isEmpty) && variantData != null) {
      displayName = SafeConverters.toStringOrNull(variantData['full_name']) ??
          SafeConverters.toStringOrNull(variantData['name']);
      final nestedGood = SafeConverters.toMapOrNull(variantData['good']);
      if ((displayName == null || displayName.isEmpty) && nestedGood != null) {
        displayName = SafeConverters.toStringOrNull(nestedGood['name']);
      }
    }

    if ((displayName == null || displayName.isEmpty) && goodMap != null) {
      displayName = SafeConverters.toStringOrNull(goodMap['name']);
    }

    return RelatedGood(
      id: Unit._parseInt(json['id']),
      variantId: Unit._parseInt(json['variant_id']) ??
          Unit._parseInt(variantData?['id']) ??
          (variantData == null ? Unit._parseInt(json['id']) : null),
      isRequired: SafeConverters.toBool(json['is_required']) ||
          SafeConverters.toBool(pivotData?['is_required']),
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
      final map = SafeConverters.toMapOrNull(candidate);
      if (map != null) return map;
    }

    return null;
  }

  static double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return SafeConverters.toDoubleOrNull(value);
    final map = SafeConverters.toMapOrNull(value);
    if (map != null) return _parsePrice(map['price']);
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      path: SafeConverters.toSafeString(json['path']),
      isMain: SafeConverters.toBool(json['is_main']),
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
    String attributeName = 'Неизвестная характеристика';
    final categoryAttribute = SafeConverters.toMapOrNull(json['category_attribute']);
    if (categoryAttribute != null) {
      final attribute = SafeConverters.toMapOrNull(categoryAttribute['attribute']);
      if (attribute != null) {
        attributeName = SafeConverters.toSafeString(attribute['name'],
            defaultValue: 'Неизвестная характеристика');
      }
    } else {
      final attribute = SafeConverters.toMapOrNull(json['attribute']);
      if (attribute != null) {
        final nestedAttribute = SafeConverters.toMapOrNull(attribute['attribute']);
        if (nestedAttribute != null) {
          attributeName = SafeConverters.toSafeString(nestedAttribute['name'],
              defaultValue: 'Неизвестная характеристика');
        }
      }
    }

    final nestedAttributeId = SafeConverters.toMapOrNull(json['attribute']);
    final deepAttributeId =
        nestedAttributeId != null
            ? SafeConverters.toMapOrNull(nestedAttributeId['attribute'])
            : null;

    return GoodsAttribute(
      id: SafeConverters.toInt(json['attribute_id'] != null
          ? json['attribute_id']
          : deepAttributeId?['id']),
      name: attributeName,
      value: SafeConverters.toSafeString(json['value']),
      isIndividual: SafeConverters.toBool(
          categoryAttribute?['is_individual'] ?? nestedAttributeId?['is_individual']),
      images: _parseStringList(json['images']),
    );
  }
}

List<String>? _parseStringList(dynamic value) {
  final raw = SafeConverters.toList(value);
  if (raw.isEmpty) return null;
  return raw.map((f) => SafeConverters.toSafeString(f)).toList();
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
    final attributeValues = SafeConverters.toList(json['attributes'])
        .map((v) => AttributeValue.fromJson(SafeConverters.toMap(v)))
        .toList();

    final filesList = SafeConverters.toList(json['files'])
        .map((f) => GoodsFile.fromJson(SafeConverters.toMap(f)))
        .toList();

    return GoodsVariant(
      id: SafeConverters.toInt(json['id']),
      goodId: SafeConverters.toInt(json['good_id']),
      isActive: SafeConverters.toBool(json['is_active']),
      attributeValues: attributeValues,
      price: SafeConverters.toSafeString(json['price'], defaultValue: '0'),
      files: filesList.isEmpty ? null : filesList,
      barcode: SafeConverters.toStringOrNull(json['barcode']),
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
      id: SafeConverters.toInt(json['id']),
      categoryAttributeId: SafeConverters.toInt(json['category_attribute_id']),
      value: SafeConverters.toSafeString(json['value']),
      unitId: SafeConverters.toIntOrNull(json['unit_id']),
      files: _parseStringList(json['files']),
      categoryAttribute: SafeConverters.toMapOrNull(json['category_attribute']) != null
          ? CategoryAttribute.fromJson(
              SafeConverters.toMap(json['category_attribute']))
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
      id: SafeConverters.toInt(json['id']),
      attribute: SafeConverters.toMapOrNull(json['attribute']) != null
          ? Attribute.fromJson(SafeConverters.toMap(json['attribute']))
          : null,
      isIndividual: SafeConverters.toBool(json['is_individual']),
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'],
          defaultValue: 'Неизвестная характеристика'),
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
    return VariantPrice(
      id: SafeConverters.toInt(json['id']),
      variantId: SafeConverters.toInt(json['variant_id']),
      price: SafeConverters.toDouble(json['price']),
      startDate: SafeConverters.toStringOrNull(json['start_date']),
      endDate: SafeConverters.toStringOrNull(json['end_date']),
    );
  }
}
