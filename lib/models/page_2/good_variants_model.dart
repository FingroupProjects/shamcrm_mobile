import 'package:crm_task_manager/utils/safe_converters.dart';

class GoodVariantsResponse {
  final GoodVariantsResult? result;
  final dynamic errors;

  GoodVariantsResponse({
    this.result,
    this.errors,
  });

  factory GoodVariantsResponse.fromJson(Map<String, dynamic> json) {
    return GoodVariantsResponse(
      result: json['result'] == null
          ? null
          : GoodVariantsResult.fromJson(SafeConverters.toMap(json['result'])),
      errors: json['errors'],
    );
  }
}

class GoodVariantsResult {
  final List<GoodVariantItem>? data;
  final Pagination? pagination;

  GoodVariantsResult({
    this.data,
    this.pagination,
  });

  factory GoodVariantsResult.fromJson(Map<String, dynamic> json) {
    return GoodVariantsResult(
      data: json['data'] == null
          ? []
          : List<GoodVariantItem>.from(
              SafeConverters.toList(json['data']).whereType<Map<String, dynamic>>().map((x) => GoodVariantItem.fromJson(x))),
      pagination: json['pagination'] == null
          ? null
          : Pagination.fromJson(SafeConverters.toMap(json['pagination'])),
    );
  }
}

class Pagination {
  final int? total;
  final int? count;
  final int? perPage;
  final int? currentPage;
  final int? totalPages;

  Pagination({
    this.total,
    this.count,
    this.perPage,
    this.currentPage,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: SafeConverters.toIntOrNull(json['total']),
      count: SafeConverters.toIntOrNull(json['count']),
      perPage: SafeConverters.toIntOrNull(json['per_page']),
      currentPage: SafeConverters.toIntOrNull(json['current_page']),
      totalPages: SafeConverters.toIntOrNull(json['total_pages']),
    );
  }
}

class GoodVariantItem {
  final int? id;
  final int? goodId;
  final int? isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? oneCUid;
  final String? barcode;
  final String? fullName;
  final VariantGood? good;
  final List<VariantAttributeValue>? attributeValues;
  final VariantPrice? price;

  GoodVariantItem({
    this.id,
    this.goodId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.oneCUid,
    this.barcode,
    this.fullName,
    this.good,
    this.attributeValues,
    this.price,
  });

  factory GoodVariantItem.fromJson(Map<String, dynamic> json) {
    return GoodVariantItem(
      id: SafeConverters.toIntOrNull(json['id']),
      goodId: SafeConverters.toIntOrNull(json['good_id']),
      isActive: SafeConverters.toIntOrNull(json['is_active']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      oneCUid: SafeConverters.toStringOrNull(json['one_c_uid']),
      barcode: SafeConverters.toStringOrNull(json['barcode']),
      fullName: SafeConverters.toStringOrNull(json['full_name']),
      good: json['good'] == null
          ? null
          : VariantGood.fromJson(SafeConverters.toMap(json['good'])),
      attributeValues: SafeConverters.toList(json['attribute_values'])
              .whereType<Map<String, dynamic>>()
              .map((i) => VariantAttributeValue.fromJson(i))
              .toList() ??
          [],
      price: json['price'] == null
          ? null
          : VariantPrice.fromJson(SafeConverters.toMap(json['price'])),
    );
  }
}

class VariantGood {
  final int? id;
  final String? oneCId;
  final String? name;
  final int? categoryId;
  final String? description;
  final String? price;
  final int? unitId;
  final int? quantity;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
  final bool? isActive;
  final String? article;
  final int? labelId;
  final bool? getImage;
  final String? cip;
  final String? packageCode;
  final List<VariantUnit>? units;
  final VariantCategory? category;
  final List<VariantFile>? files;
  final List<dynamic>? discounts;
  final VariantGoodPrice? goodPrice;
  final VariantUnit? unit;
  final List<VariantMeasurement>? measurements;

  VariantGood({
    this.id,
    this.oneCId,
    this.name,
    this.categoryId,
    this.description,
    this.price,
    this.unitId,
    this.quantity,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.isActive,
    this.article,
    this.labelId,
    this.getImage,
    this.cip,
    this.packageCode,
    this.units,
    this.category,
    this.files,
    this.discounts,
    this.goodPrice,
    this.unit,
    this.measurements,
  });

  factory VariantGood.fromJson(Map<String, dynamic> json) {
    return VariantGood(
      id: SafeConverters.toIntOrNull(json['id']),
      oneCId: SafeConverters.toStringOrNull(json['one_c_id']),
      name: SafeConverters.toStringOrNull(json['name']),
      categoryId: SafeConverters.toIntOrNull(json['category_id']),
      description: SafeConverters.toStringOrNull(json['description']),
      price: SafeConverters.toStringOrNull(json['price']),
      unitId: SafeConverters.toIntOrNull(json['unit_id']),
      quantity: SafeConverters.toIntOrNull(json['quantity']),
      deletedAt: SafeConverters.toStringOrNull(json['deleted_at']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      isActive: SafeConverters.toBoolOrNull(json['is_active']),
      article: SafeConverters.toStringOrNull(json['article']),
      labelId: SafeConverters.toIntOrNull(json['label_id']),
      getImage: SafeConverters.toBoolOrNull(json['get_image']),
      cip: SafeConverters.toStringOrNull(json['cip']),
      packageCode: SafeConverters.toStringOrNull(json['package_code']),
      units: SafeConverters.toList(json['units'])
              .whereType<Map<String, dynamic>>()
              .map((i) => VariantUnit.fromJson(i))
              .toList() ??
          [],
      category: json['category'] == null
          ? null
          : VariantCategory.fromJson(SafeConverters.toMap(json['category'])),
      files: SafeConverters.toList(json['files'])
              .whereType<Map<String, dynamic>>()
              .map((i) => VariantFile.fromJson(i))
              .toList() ??
          [],
      discounts: SafeConverters.toList(json['discounts']),
      goodPrice: json['good_price'] == null
          ? null
          : VariantGoodPrice.fromJson(SafeConverters.toMap(json['good_price'])),
      unit: json['unit'] == null
          ? null
          : VariantUnit.fromJson(SafeConverters.toMap(json['unit'])),
      measurements: SafeConverters.toList(json['measurements'])
              .whereType<Map<String, dynamic>>()
              .map((i) => VariantMeasurement.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class VariantUnit {
  final int? id;
  final String? name;
  final bool? isBase;
  final String? amount;
  final String? createdAt;
  final String? updatedAt;
  final String? shortName;

  VariantUnit({
    this.id,
    this.name,
    this.isBase,
    this.amount,
    this.createdAt,
    this.updatedAt,
    this.shortName,
  });

  factory VariantUnit.fromJson(Map<String, dynamic> json) {
    return VariantUnit(
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      isBase: SafeConverters.toBoolOrNull(json['is_base']),
      amount: SafeConverters.toStringOrNull(json['amount']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      shortName: SafeConverters.toStringOrNull(json['short_name']),
    );
  }
}

class VariantCategory {
  final int? id;
  final String? name;
  final String? image;
  final int? parentId;
  final String? createdAt;
  final String? updatedAt;
  final bool? isActive;
  final bool? hasPriceCharacteristics;
  final String? displayType;
  final int? isParent;

  VariantCategory({
    this.id,
    this.name,
    this.image,
    this.parentId,
    this.createdAt,
    this.updatedAt,
    this.isActive,
    this.hasPriceCharacteristics,
    this.displayType,
    this.isParent,
  });

  factory VariantCategory.fromJson(Map<String, dynamic> json) {
    return VariantCategory(
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      image: SafeConverters.toStringOrNull(json['image']),
      parentId: SafeConverters.toIntOrNull(json['parent_id']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      isActive: SafeConverters.toBoolOrNull(json['is_active']),
      hasPriceCharacteristics: SafeConverters.toBoolOrNull(json['has_price_characteristics']),
      displayType: SafeConverters.toStringOrNull(json['display_type']),
      isParent: SafeConverters.toIntOrNull(json['is_parent']),
    );
  }
}

class VariantFile {
  final int? id;
  final String? name;
  final String? path;
  final String? modelType;
  final int? modelId;
  final String? createdAt;
  final String? updatedAt;
  final String? externalId;
  final String? externalUrl;
  final bool? isMain;

  VariantFile({
    this.id,
    this.name,
    this.path,
    this.modelType,
    this.modelId,
    this.createdAt,
    this.updatedAt,
    this.externalId,
    this.externalUrl,
    this.isMain,
  });

  factory VariantFile.fromJson(Map<String, dynamic> json) {
    return VariantFile(
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      path: SafeConverters.toStringOrNull(json['path']),
      modelType: SafeConverters.toStringOrNull(json['model_type']),
      modelId: SafeConverters.toIntOrNull(json['model_id']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      externalId: SafeConverters.toStringOrNull(json['external_id']),
      externalUrl: SafeConverters.toStringOrNull(json['external_url']),
      isMain: SafeConverters.toBoolOrNull(json['is_main']),
    );
  }
}

class VariantGoodPrice {
  final int? id;
  final int? variantId;
  final String? price;
  final String? createdAt;
  final String? updatedAt;
  final int? goodId;
  final int? pricingId;
  final int? priceTypeId;
  final String? startDate;
  final int? laravelThroughKey;

  VariantGoodPrice({
    this.id,
    this.variantId,
    this.price,
    this.createdAt,
    this.updatedAt,
    this.goodId,
    this.pricingId,
    this.priceTypeId,
    this.startDate,
    this.laravelThroughKey,
  });

  factory VariantGoodPrice.fromJson(Map<String, dynamic> json) {
    return VariantGoodPrice(
      id: SafeConverters.toIntOrNull(json['id']),
      variantId: SafeConverters.toIntOrNull(json['variant_id']),
      price: SafeConverters.toStringOrNull(json['price']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      goodId: SafeConverters.toIntOrNull(json['good_id']),
      pricingId: SafeConverters.toIntOrNull(json['pricing_id']),
      priceTypeId: SafeConverters.toIntOrNull(json['price_type_id']),
      startDate: SafeConverters.toStringOrNull(json['start_date']),
      laravelThroughKey: SafeConverters.toIntOrNull(json['laravel_through_key']),
    );
  }
}

class VariantMeasurement {
  final int? id;
  final int? goodId;
  final int? unitId;
  final String? amount;
  final String? createdAt;
  final String? updatedAt;
  final VariantUnit? unit;

  VariantMeasurement({
    this.id,
    this.goodId,
    this.unitId,
    this.amount,
    this.createdAt,
    this.updatedAt,
    this.unit,
  });

  factory VariantMeasurement.fromJson(Map<String, dynamic> json) {
    return VariantMeasurement(
      id: SafeConverters.toIntOrNull(json['id']),
      goodId: SafeConverters.toIntOrNull(json['good_id']),
      unitId: SafeConverters.toIntOrNull(json['unit_id']),
      amount: SafeConverters.toStringOrNull(json['amount']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      unit: json['unit'] == null
          ? null
          : VariantUnit.fromJson(SafeConverters.toMap(json['unit'])),
    );
  }
}

class VariantAttributeValue {
  final int? id;
  final int? categoryAttributeId;
  final String? value;
  final int? unitId;
  final String? createdAt;
  final String? updatedAt;
  final int? variantAttributeId;
  final int? variantId;
  final VariantCategoryAttribute? categoryAttribute;

  VariantAttributeValue({
    this.id,
    this.categoryAttributeId,
    this.value,
    this.unitId,
    this.createdAt,
    this.updatedAt,
    this.variantAttributeId,
    this.variantId,
    this.categoryAttribute,
  });

  factory VariantAttributeValue.fromJson(Map<String, dynamic> json) {
    return VariantAttributeValue(
      id: SafeConverters.toIntOrNull(json['id']),
      categoryAttributeId: SafeConverters.toIntOrNull(json['category_attribute_id']),
      value: SafeConverters.toStringOrNull(json['value']),
      unitId: SafeConverters.toIntOrNull(json['unit_id']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      variantAttributeId: SafeConverters.toIntOrNull(json['variant_attribute_id']),
      variantId: SafeConverters.toIntOrNull(json['variant_id']),
      categoryAttribute: json['category_attribute'] == null
          ? null
          : VariantCategoryAttribute.fromJson(SafeConverters.toMap(json['category_attribute'])),
    );
  }
}

class VariantCategoryAttribute {
  final int? id;
  final int? categoryId;
  final int? attributeId;
  final String? createdAt;
  final String? updatedAt;
  final bool? isIndividual;
  final bool? showToSite;
  final VariantAttribute? attribute;

  VariantCategoryAttribute({
    this.id,
    this.categoryId,
    this.attributeId,
    this.createdAt,
    this.updatedAt,
    this.isIndividual,
    this.showToSite,
    this.attribute,
  });

  factory VariantCategoryAttribute.fromJson(Map<String, dynamic> json) {
    return VariantCategoryAttribute(
      id: SafeConverters.toIntOrNull(json['id']),
      categoryId: SafeConverters.toIntOrNull(json['category_id']),
      attributeId: SafeConverters.toIntOrNull(json['attribute_id']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      isIndividual: SafeConverters.toBoolOrNull(json['is_individual']),
      showToSite: SafeConverters.toBoolOrNull(json['show_to_site']),
      attribute: json['attribute'] == null
          ? null
          : VariantAttribute.fromJson(SafeConverters.toMap(json['attribute'])),
    );
  }
}

class VariantAttribute {
  final int? id;
  final String? name;
  final String? createdAt;
  final String? updatedAt;

  VariantAttribute({
    this.id,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory VariantAttribute.fromJson(Map<String, dynamic> json) {
    return VariantAttribute(
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
    );
  }
}

class VariantPrice {
  final int? id;
  final int? variantId;
  final String? price;
  final String? createdAt;
  final String? updatedAt;
  final int? goodId;
  final int? pricingId;
  final int? priceTypeId;

  VariantPrice({
    this.id,
    this.variantId,
    this.price,
    this.createdAt,
    this.updatedAt,
    this.goodId,
    this.pricingId,
    this.priceTypeId,
  });

  factory VariantPrice.fromJson(Map<String, dynamic> json) {
    return VariantPrice(
      id: SafeConverters.toIntOrNull(json['id']),
      variantId: SafeConverters.toIntOrNull(json['variant_id']),
      price: SafeConverters.toStringOrNull(json['price']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      goodId: SafeConverters.toIntOrNull(json['good_id']),
      pricingId: SafeConverters.toIntOrNull(json['pricing_id']),
      priceTypeId: SafeConverters.toIntOrNull(json['price_type_id']),
    );
  }
}
