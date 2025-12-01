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
          : GoodVariantsResult.fromJson(json['result'] as Map<String, dynamic>),
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
              json['data']!.map((x) => GoodVariantItem.fromJson(x))),
      pagination: json['pagination'] == null
          ? null
          : Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
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
      total: json['total'],
      count: json['count'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
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
      id: json['id'],
      goodId: json['good_id'],
      isActive: json['is_active'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      oneCUid: json['one_c_uid'],
      barcode: json['barcode'],
      fullName: json['full_name'],
      good: json['good'] == null
          ? null
          : VariantGood.fromJson(json['good'] as Map<String, dynamic>),
      attributeValues: (json['attribute_values'] as List?)
              ?.map((i) => VariantAttributeValue.fromJson(i))
              .toList() ??
          [],
      price: json['price'] == null
          ? null
          : VariantPrice.fromJson(json['price'] as Map<String, dynamic>),
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
      id: json['id'],
      oneCId: json['one_c_id'],
      name: json['name'],
      categoryId: json['category_id'],
      description: json['description'],
      price: json['price'],
      unitId: json['unit_id'],
      quantity: json['quantity'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isActive: json['is_active'],
      article: json['article'],
      labelId: json['label_id'],
      getImage: json['get_image'],
      cip: json['cip'],
      packageCode: json['package_code'],
      units: (json['units'] as List?)
              ?.map((i) => VariantUnit.fromJson(i))
              .toList() ??
          [],
      category: json['category'] == null
          ? null
          : VariantCategory.fromJson(json['category'] as Map<String, dynamic>),
      files: (json['files'] as List?)
              ?.map((i) => VariantFile.fromJson(i))
              .toList() ??
          [],
      discounts: json['discounts'] as List?,
      goodPrice: json['good_price'] == null
          ? null
          : VariantGoodPrice.fromJson(json['good_price'] as Map<String, dynamic>),
      unit: json['unit'] == null
          ? null
          : VariantUnit.fromJson(json['unit'] as Map<String, dynamic>),
      measurements: (json['measurements'] as List?)
              ?.map((i) => VariantMeasurement.fromJson(i))
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
      id: json['id'],
      name: json['name'],
      isBase: json['is_base'],
      amount: json['amount'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      shortName: json['short_name'],
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
      id: json['id'],
      name: json['name'],
      image: json['image'],
      parentId: json['parent_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isActive: json['is_active'],
      hasPriceCharacteristics: json['has_price_characteristics'],
      displayType: json['display_type'],
      isParent: json['is_parent'],
    );
  }
}

class VariantFile {
  final int? id;
  final String? name;
  final String? path;
  final String? modelType;
  final String? modelId;
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
      id: json['id'],
      name: json['name'],
      path: json['path'],
      modelType: json['model_type'],
      modelId: json['model_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      externalId: json['external_id'],
      externalUrl: json['external_url'],
      isMain: json['is_main'],
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
      id: json['id'],
      variantId: json['variant_id'],
      price: json['price'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      goodId: json['good_id'],
      pricingId: json['pricing_id'],
      priceTypeId: json['price_type_id'],
      startDate: json['start_date'],
      laravelThroughKey: json['laravel_through_key'],
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
      id: json['id'],
      goodId: json['good_id'],
      unitId: json['unit_id'],
      amount: json['amount'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      unit: json['unit'] == null
          ? null
          : VariantUnit.fromJson(json['unit'] as Map<String, dynamic>),
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
      id: json['id'],
      categoryAttributeId: json['category_attribute_id'],
      value: json['value'],
      unitId: json['unit_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      variantAttributeId: json['variant_attribute_id'],
      variantId: json['variant_id'],
      categoryAttribute: json['category_attribute'] == null
          ? null
          : VariantCategoryAttribute.fromJson(
              json['category_attribute'] as Map<String, dynamic>),
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
      id: json['id'],
      categoryId: json['category_id'],
      attributeId: json['attribute_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isIndividual: json['is_individual'],
      showToSite: json['show_to_site'],
      attribute: json['attribute'] == null
          ? null
          : VariantAttribute.fromJson(json['attribute'] as Map<String, dynamic>),
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
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
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
      id: json['id'],
      variantId: json['variant_id'],
      price: json['price'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      goodId: json['good_id'],
      pricingId: json['pricing_id'],
      priceTypeId: json['price_type_id'],
    );
  }
}

