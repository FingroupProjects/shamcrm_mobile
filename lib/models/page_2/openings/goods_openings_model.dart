class GoodsOpeningsResponse {
  final List<GoodsOpeningDocument>? result;
  final dynamic errors;

  GoodsOpeningsResponse({
    this.result,
    this.errors,
  });

  factory GoodsOpeningsResponse.fromJson(dynamic json) {
    // API возвращает массив напрямую, а не обернутый в result
    if (json is List) {
      return GoodsOpeningsResponse(
        result: json.map((i) => GoodsOpeningDocument.fromJson(i)).toList(),
        errors: null,
      );
    } else if (json is Map<String, dynamic>) {
      // API может вернуть {"result": {"data": [...]}} или {"result": [...]}
      if (json["result"] != null) {
        final resultData = json["result"];
        if (resultData is Map<String, dynamic> && resultData["data"] != null) {
          // Формат: {"result": {"data": [...]}}
          return GoodsOpeningsResponse(
            result: (resultData["data"] as List?)
                ?.map((x) => GoodsOpeningDocument.fromJson(x as Map<String, dynamic>))
                .toList() ?? [],
            errors: json["errors"],
          );
        } else if (resultData is List) {
          // Формат: {"result": [...]}
      return GoodsOpeningsResponse(
            result: resultData.map((x) => GoodsOpeningDocument.fromJson(x as Map<String, dynamic>)).toList(),
        errors: json["errors"],
      );
        }
      }
      return GoodsOpeningsResponse(result: [], errors: json["errors"]);
    }
    return GoodsOpeningsResponse(result: [], errors: null);
  }
}

class GoodsOpeningDocument {
  final int? id;
  final String? date;
  final String? docNumber;
  final String? modelType;
  final int? modelId;
  final int? counterpartyAgreementId;
  final int? organizationId;
  final int? storageId;
  final String? comment;
  final int? currencyId;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? type;
  final int? approved;
  final int? authorId;
  final int? checkBySuppliers;
  final int? articleId;
  final int? isInitialBalance;
  final List<DocumentGood>? documentGoods;
  final Counterparty? model;
  final Storage? storage;
  final Author? author;

  GoodsOpeningDocument({
    this.id,
    this.date,
    this.docNumber,
    this.modelType,
    this.modelId,
    this.counterpartyAgreementId,
    this.organizationId,
    this.storageId,
    this.comment,
    this.currencyId,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.type,
    this.approved,
    this.authorId,
    this.checkBySuppliers,
    this.articleId,
    this.isInitialBalance,
    this.documentGoods,
    this.model,
    this.storage,
    this.author,
  });

  factory GoodsOpeningDocument.fromJson(Map<String, dynamic> json) {
    return GoodsOpeningDocument(
      id: json['id'],
      date: json['date'],
      docNumber: json['doc_number'],
      modelType: json['model_type'],
      modelId: json['model_id'],
      counterpartyAgreementId: json['counterparty_agreement_id'],
      organizationId: json['organization_id'],
      storageId: json['storage_id'],
      comment: json['comment'],
      currencyId: json['currency_id'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      type: json['type'],
      approved: json['approved'],
      authorId: json['author_id'],
      checkBySuppliers: json['checkBySuppliers'],
      articleId: json['article_id'],
      isInitialBalance: json['is_initial_balance'],
      documentGoods: (json['document_goods'] as List?)
              ?.map((i) => DocumentGood.fromJson(i))
              .toList() ??
          [],
      model: json['model'] == null
          ? null
          : Counterparty.fromJson(json['model'] as Map<String, dynamic>),
      storage: json['storage'] == null
          ? null
          : Storage.fromJson(json['storage'] as Map<String, dynamic>),
      author: json['author'] == null
          ? null
          : Author.fromJson(json['author'] as Map<String, dynamic>),
    );
  }
}

class DocumentGood {
  final int? id;
  final int? documentId;
  final int? goodVariantId;
  final String? quantity;
  final String? price;
  final int? unitId;
  final String? createdAt;
  final String? updatedAt;
  final String? sum;
  final GoodVariant? goodVariant;
  final Unit? unit;

  DocumentGood({
    this.id,
    this.documentId,
    this.goodVariantId,
    this.quantity,
    this.price,
    this.unitId,
    this.createdAt,
    this.updatedAt,
    this.sum,
    this.goodVariant,
    this.unit,
  });

  factory DocumentGood.fromJson(Map<String, dynamic> json) {
    return DocumentGood(
      id: json['id'],
      documentId: json['document_id'],
      goodVariantId: json['good_variant_id'],
      quantity: json['quantity'],
      price: json['price'],
      unitId: json['unit_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      sum: json['sum'],
      goodVariant: json['good_variant'] == null
          ? null
          : GoodVariant.fromJson(json['good_variant'] as Map<String, dynamic>),
      unit: json['unit'] == null
          ? null
          : Unit.fromJson(json['unit'] as Map<String, dynamic>),
    );
  }
}

class GoodVariant {
  final int? id;
  final int? goodId;
  final int? isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? oneCUid;
  final String? barcode;
  final String? fullName;
  final Good? good;
  final List<AttributeValue>? attributeValues;

  GoodVariant({
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
  });

  factory GoodVariant.fromJson(Map<String, dynamic> json) {
    return GoodVariant(
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
          : Good.fromJson(json['good'] as Map<String, dynamic>),
      attributeValues: (json['attribute_values'] as List?)
              ?.map((i) => AttributeValue.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class Good {
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
  final Category? category;
  final Unit? unit;
  final List<dynamic>? measurements;

  Good({
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
    this.category,
    this.unit,
    this.measurements,
  });

  factory Good.fromJson(Map<String, dynamic> json) {
    return Good(
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
      category: json['category'] == null
          ? null
          : Category.fromJson(json['category'] as Map<String, dynamic>),
      unit: json['unit'] == null
          ? null
          : Unit.fromJson(json['unit'] as Map<String, dynamic>),
      measurements: json['measurements'],
    );
  }
}

class Category {
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

  Category({
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

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
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

class Unit {
  final int? id;
  final String? name;
  final String? createdAt;
  final String? updatedAt;
  final String? shortName;

  Unit({
    this.id,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.shortName,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      shortName: json['short_name'],
    );
  }
}

class AttributeValue {
  final int? id;
  final int? categoryAttributeId;
  final String? value;
  final int? unitId;
  final String? createdAt;
  final String? updatedAt;
  final int? variantAttributeId;
  final int? variantId;
  final CategoryAttribute? categoryAttribute;

  AttributeValue({
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

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
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
          : CategoryAttribute.fromJson(json['category_attribute'] as Map<String, dynamic>),
    );
  }
}

class CategoryAttribute {
  final int? id;
  final int? categoryId;
  final int? attributeId;
  final String? createdAt;
  final String? updatedAt;
  final bool? isIndividual;
  final bool? showToSite;
  final Attribute? attribute;

  CategoryAttribute({
    this.id,
    this.categoryId,
    this.attributeId,
    this.createdAt,
    this.updatedAt,
    this.isIndividual,
    this.showToSite,
    this.attribute,
  });

  factory CategoryAttribute.fromJson(Map<String, dynamic> json) {
    return CategoryAttribute(
      id: json['id'],
      categoryId: json['category_id'],
      attributeId: json['attribute_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isIndividual: json['is_individual'],
      showToSite: json['show_to_site'],
      attribute: json['attribute'] == null
          ? null
          : Attribute.fromJson(json['attribute'] as Map<String, dynamic>),
    );
  }
}

class Attribute {
  final int? id;
  final String? name;
  final String? createdAt;
  final String? updatedAt;

  Attribute({
    this.id,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class Counterparty {
  final int? id;
  final String? name;
  final String? phone;
  final int? inn;
  final String? note;
  final String? createdAt;
  final String? updatedAt;

  Counterparty({
    this.id,
    this.name,
    this.phone,
    this.inn,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory Counterparty.fromJson(Map<String, dynamic> json) {
    return Counterparty(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      inn: json['inn'],
      note: json['note'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class Storage {
  final int? id;
  final String? name;
  final String? createdAt;
  final String? updatedAt;
  final String? address;
  final int? isActive;
  final int? deliveryServiceId;
  final int? showOnSite;
  final int? coordinates;

  Storage({
    this.id,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.address,
    this.isActive,
    this.deliveryServiceId,
    this.showOnSite,
    this.coordinates,
  });

  factory Storage.fromJson(Map<String, dynamic> json) {
    return Storage(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      address: json['address'],
      isActive: json['is_active'],
      deliveryServiceId: json['delivery_service_id'],
      showOnSite: json['show_on_site'],
      coordinates: json['coordinates'],
    );
  }
}

class Author {
  final int? id;
  final String? name;
  final String? lastname;
  final String? login;
  final String? email;
  final String? phone;
  final String? telegramUserId;
  final String? emailVerifiedAt;
  final String? image;
  final String? lastSeen;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
  final int? managerId;
  final String? jobTitle;
  final int? hasImage;
  final int? isFirstLogin;
  final String? internalNumber;
  final int? departmentId;
  final String? uniqueId;
  final int? shiftId;
  final int? weekendPatternId;
  final int? workBreakId;
  final String? oneCId;

  Author({
    this.id,
    this.name,
    this.lastname,
    this.login,
    this.email,
    this.phone,
    this.telegramUserId,
    this.emailVerifiedAt,
    this.image,
    this.lastSeen,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.managerId,
    this.jobTitle,
    this.hasImage,
    this.isFirstLogin,
    this.internalNumber,
    this.departmentId,
    this.uniqueId,
    this.shiftId,
    this.weekendPatternId,
    this.workBreakId,
    this.oneCId,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      telegramUserId: json['telegram_user_id'],
      emailVerifiedAt: json['email_verified_at'],
      image: json['image'],
      lastSeen: json['last_seen'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      managerId: json['manager_id'],
      jobTitle: json['job_title'],
      hasImage: json['has_image'],
      isFirstLogin: json['is_first_login'],
      internalNumber: json['internal_number'],
      departmentId: json['department_id'],
      uniqueId: json['unique_id'],
      shiftId: json['shift_id'],
      weekendPatternId: json['weekend_pattern_id'],
      workBreakId: json['work_break_id'],
      oneCId: json['one_c_id'],
    );
  }
}

