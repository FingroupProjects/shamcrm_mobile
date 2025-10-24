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
      // На случай если API вернет с оберткой
      return GoodsOpeningsResponse(
        result: json["result"] == null
            ? []
            : List<GoodsOpeningDocument>.from(
                json["result"]!.map((x) => GoodsOpeningDocument.fromJson(x))),
        errors: json["errors"],
      );
    }
    return GoodsOpeningsResponse(result: [], errors: null);
  }
}

class GoodsOpeningDocument {
  final int id;
  final String date;
  final String docNumber;
  final String modelType;
  final int modelId;
  final int counterpartyAgreementId;
  final int organizationId;
  final int storageId;
  final String comment;
  final int currencyId;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final String type;
  final int approved;
  final int authorId;
  final int checkBySuppliers;
  final int? articleId;
  final int isInitialBalance;
  final List<DocumentGood> documentGoods;
  final Counterparty model;
  final Storage storage;
  final Author author;

  GoodsOpeningDocument({
    required this.id,
    required this.date,
    required this.docNumber,
    required this.modelType,
    required this.modelId,
    required this.counterpartyAgreementId,
    required this.organizationId,
    required this.storageId,
    required this.comment,
    required this.currencyId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.approved,
    required this.authorId,
    required this.checkBySuppliers,
    this.articleId,
    required this.isInitialBalance,
    required this.documentGoods,
    required this.model,
    required this.storage,
    required this.author,
  });

  factory GoodsOpeningDocument.fromJson(Map<String, dynamic> json) {
    return GoodsOpeningDocument(
      id: json['id'] as int,
      date: json['date'] as String,
      docNumber: json['doc_number'] as String,
      modelType: json['model_type'] as String,
      modelId: json['model_id'] as int,
      counterpartyAgreementId: json['counterparty_agreement_id'] as int,
      organizationId: json['organization_id'] as int,
      storageId: json['storage_id'] as int,
      comment: json['comment'] as String,
      currencyId: json['currency_id'] as int,
      deletedAt: json['deleted_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      type: json['type'] as String,
      approved: json['approved'] as int,
      authorId: json['author_id'] as int,
      checkBySuppliers: json['checkBySuppliers'] as int,
      articleId: json['article_id'] as int?,
      isInitialBalance: json['is_initial_balance'] as int,
      documentGoods: (json['document_goods'] as List?)
              ?.map((i) => DocumentGood.fromJson(i))
              .toList() ??
          [],
      model: Counterparty.fromJson(json['model'] as Map<String, dynamic>),
      storage: Storage.fromJson(json['storage'] as Map<String, dynamic>),
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
    );
  }
}

class DocumentGood {
  final int id;
  final int documentId;
  final int goodVariantId;
  final String quantity;
  final String price;
  final int unitId;
  final String createdAt;
  final String updatedAt;
  final String? sum;
  final GoodVariant goodVariant;
  final Unit unit;

  DocumentGood({
    required this.id,
    required this.documentId,
    required this.goodVariantId,
    required this.quantity,
    required this.price,
    required this.unitId,
    required this.createdAt,
    required this.updatedAt,
    this.sum,
    required this.goodVariant,
    required this.unit,
  });

  factory DocumentGood.fromJson(Map<String, dynamic> json) {
    return DocumentGood(
      id: json['id'] as int,
      documentId: json['document_id'] as int,
      goodVariantId: json['good_variant_id'] as int,
      quantity: json['quantity'] as String,
      price: json['price'] as String,
      unitId: json['unit_id'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      sum: json['sum'] as String?,
      goodVariant: GoodVariant.fromJson(json['good_variant'] as Map<String, dynamic>),
      unit: Unit.fromJson(json['unit'] as Map<String, dynamic>),
    );
  }
}

class GoodVariant {
  final int id;
  final int goodId;
  final int isActive;
  final String createdAt;
  final String updatedAt;
  final String? oneCUid;
  final String? barcode;
  final String fullName;
  final Good good;
  final List<AttributeValue> attributeValues;

  GoodVariant({
    required this.id,
    required this.goodId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.oneCUid,
    this.barcode,
    required this.fullName,
    required this.good,
    required this.attributeValues,
  });

  factory GoodVariant.fromJson(Map<String, dynamic> json) {
    return GoodVariant(
      id: json['id'] as int,
      goodId: json['good_id'] as int,
      isActive: json['is_active'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      oneCUid: json['one_c_uid'] as String?,
      barcode: json['barcode'] as String?,
      fullName: json['full_name'] as String,
      good: Good.fromJson(json['good'] as Map<String, dynamic>),
      attributeValues: (json['attribute_values'] as List?)
              ?.map((i) => AttributeValue.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class Good {
  final int id;
  final String? oneCId;
  final String name;
  final int categoryId;
  final String description;
  final String price;
  final int unitId;
  final int quantity;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final bool isActive;
  final String? article;
  final int? labelId;
  final bool getImage;
  final String? cip;
  final String? packageCode;
  final Category category;
  final Unit unit;
  final List<dynamic> measurements;

  Good({
    required this.id,
    this.oneCId,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.price,
    required this.unitId,
    required this.quantity,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.article,
    this.labelId,
    required this.getImage,
    this.cip,
    this.packageCode,
    required this.category,
    required this.unit,
    required this.measurements,
  });

  factory Good.fromJson(Map<String, dynamic> json) {
    return Good(
      id: json['id'] as int,
      oneCId: json['one_c_id'] as String?,
      name: json['name'] as String,
      categoryId: json['category_id'] as int,
      description: json['description'] as String,
      price: json['price'] as String,
      unitId: json['unit_id'] as int,
      quantity: json['quantity'] as int,
      deletedAt: json['deleted_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      isActive: json['is_active'] as bool,
      article: json['article'] as String?,
      labelId: json['label_id'] as int?,
      getImage: json['get_image'] as bool,
      cip: json['cip'] as String?,
      packageCode: json['package_code'] as String?,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      unit: Unit.fromJson(json['unit'] as Map<String, dynamic>),
      measurements: json['measurements'] as List<dynamic>,
    );
  }
}

class Category {
  final int id;
  final String name;
  final String? image;
  final int parentId;
  final String createdAt;
  final String updatedAt;
  final bool isActive;
  final bool hasPriceCharacteristics;
  final String displayType;
  final int isParent;

  Category({
    required this.id,
    required this.name,
    this.image,
    required this.parentId,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.hasPriceCharacteristics,
    required this.displayType,
    required this.isParent,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      parentId: json['parent_id'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      isActive: json['is_active'] as bool,
      hasPriceCharacteristics: json['has_price_characteristics'] as bool,
      displayType: json['display_type'] as String,
      isParent: json['is_parent'] as int,
    );
  }
}

class Unit {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final String shortName;

  Unit({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.shortName,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      shortName: json['short_name'] as String,
    );
  }
}

class AttributeValue {
  final int id;
  final int categoryAttributeId;
  final String value;
  final int? unitId;
  final String createdAt;
  final String updatedAt;
  final int variantAttributeId;
  final int variantId;
  final CategoryAttribute categoryAttribute;

  AttributeValue({
    required this.id,
    required this.categoryAttributeId,
    required this.value,
    this.unitId,
    required this.createdAt,
    required this.updatedAt,
    required this.variantAttributeId,
    required this.variantId,
    required this.categoryAttribute,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      id: json['id'] as int,
      categoryAttributeId: json['category_attribute_id'] as int,
      value: json['value'] as String,
      unitId: json['unit_id'] as int?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      variantAttributeId: json['variant_attribute_id'] as int,
      variantId: json['variant_id'] as int,
      categoryAttribute: CategoryAttribute.fromJson(json['category_attribute'] as Map<String, dynamic>),
    );
  }
}

class CategoryAttribute {
  final int id;
  final int categoryId;
  final int attributeId;
  final String createdAt;
  final String updatedAt;
  final bool isIndividual;
  final bool showToSite;
  final Attribute attribute;

  CategoryAttribute({
    required this.id,
    required this.categoryId,
    required this.attributeId,
    required this.createdAt,
    required this.updatedAt,
    required this.isIndividual,
    required this.showToSite,
    required this.attribute,
  });

  factory CategoryAttribute.fromJson(Map<String, dynamic> json) {
    return CategoryAttribute(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      attributeId: json['attribute_id'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      isIndividual: json['is_individual'] as bool,
      showToSite: json['show_to_site'] as bool,
      attribute: Attribute.fromJson(json['attribute'] as Map<String, dynamic>),
    );
  }
}

class Attribute {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  Attribute({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class Counterparty {
  final int id;
  final String name;
  final String phone;
  final int inn;
  final String note;
  final String createdAt;
  final String updatedAt;

  Counterparty({
    required this.id,
    required this.name,
    required this.phone,
    required this.inn,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Counterparty.fromJson(Map<String, dynamic> json) {
    return Counterparty(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      inn: json['inn'] as int,
      note: json['note'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class Storage {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final String? address;
  final int isActive;
  final int? deliveryServiceId;
  final int showOnSite;
  final int coordinates;

  Storage({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    required this.isActive,
    this.deliveryServiceId,
    required this.showOnSite,
    required this.coordinates,
  });

  factory Storage.fromJson(Map<String, dynamic> json) {
    return Storage(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      address: json['address'] as String?,
      isActive: json['is_active'] as int,
      deliveryServiceId: json['delivery_service_id'] as int?,
      showOnSite: json['show_on_site'] as int,
      coordinates: json['coordinates'] as int,
    );
  }
}

class Author {
  final int id;
  final String name;
  final String lastname;
  final String login;
  final String email;
  final String phone;
  final String? telegramUserId;
  final String? emailVerifiedAt;
  final String image;
  final String? lastSeen;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final int? managerId;
  final String jobTitle;
  final int hasImage;
  final int isFirstLogin;
  final String? internalNumber;
  final int? departmentId;
  final String uniqueId;
  final int? shiftId;
  final int? weekendPatternId;
  final int? workBreakId;
  final String? oneCId;

  Author({
    required this.id,
    required this.name,
    required this.lastname,
    required this.login,
    required this.email,
    required this.phone,
    this.telegramUserId,
    this.emailVerifiedAt,
    required this.image,
    this.lastSeen,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.managerId,
    required this.jobTitle,
    required this.hasImage,
    required this.isFirstLogin,
    this.internalNumber,
    this.departmentId,
    required this.uniqueId,
    this.shiftId,
    this.weekendPatternId,
    this.workBreakId,
    this.oneCId,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as int,
      name: json['name'] as String,
      lastname: json['lastname'] as String,
      login: json['login'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      telegramUserId: json['telegram_user_id'] as String?,
      emailVerifiedAt: json['email_verified_at'] as String?,
      image: json['image'] as String,
      lastSeen: json['last_seen'] as String?,
      deletedAt: json['deleted_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      managerId: json['manager_id'] as int?,
      jobTitle: json['job_title'] as String,
      hasImage: json['has_image'] as int,
      isFirstLogin: json['is_first_login'] as int,
      internalNumber: json['internal_number'] as String?,
      departmentId: json['department_id'] as int?,
      uniqueId: json['unique_id'] as String,
      shiftId: json['shift_id'] as int?,
      weekendPatternId: json['weekend_pattern_id'] as int?,
      workBreakId: json['work_break_id'] as int?,
      oneCId: json['one_c_id'] as String?,
    );
  }
}

