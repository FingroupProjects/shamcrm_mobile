import 'package:crm_task_manager/utils/safe_converters.dart';

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
        result: json.whereType<Map<String, dynamic>>().map((i) => GoodsOpeningDocument.fromJson(i)).toList(),
        errors: null,
      );
    } else if (json is Map<String, dynamic>) {
      // API может вернуть {"result": {"data": [...]}} или {"result": [...]}
      if (json["result"] != null) {
        final resultData = json["result"];
        if (resultData is Map<String, dynamic> && resultData["data"] != null) {
          // Формат: {"result": {"data": [...]}}
          return GoodsOpeningsResponse(
            result: SafeConverters.toList(resultData["data"])
                .whereType<Map<String, dynamic>>()
                .map((x) => GoodsOpeningDocument.fromJson(x))
                .toList(),
            errors: json["errors"],
          );
        } else if (resultData is List) {
          // Формат: {"result": [...]}
      return GoodsOpeningsResponse(
            result: resultData
                .whereType<Map<String, dynamic>>()
                .map((x) => GoodsOpeningDocument.fromJson(x))
                .toList(),
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
      id: SafeConverters.toIntOrNull(json['id']),
      date: SafeConverters.toStringOrNull(json['date'], emptyAsNull: true),
      docNumber: SafeConverters.toStringOrNull(json['doc_number'], emptyAsNull: true),
      modelType: SafeConverters.toStringOrNull(json['model_type'], emptyAsNull: true),
      modelId: json['model_id'],
      counterpartyAgreementId: json['counterparty_agreement_id'],
      organizationId: json['organization_id'],
      storageId: json['storage_id'],
      comment: SafeConverters.toStringOrNull(json['comment'], emptyAsNull: true),
      currencyId: json['currency_id'],
      deletedAt: SafeConverters.toStringOrNull(json['deleted_at'], emptyAsNull: true),
      createdAt: SafeConverters.toStringOrNull(json['created_at'], emptyAsNull: true),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at'], emptyAsNull: true),
      type: SafeConverters.toStringOrNull(json['type'], emptyAsNull: true),
      approved: SafeConverters.toIntOrNull(json['approved']),
      authorId: json['author_id'],
      checkBySuppliers: SafeConverters.toIntOrNull(json['checkBySuppliers']),
      articleId: json['article_id'],
      isInitialBalance: json['is_initial_balance'],
      documentGoods: SafeConverters.toList(json['document_goods']).whereType<Map<String, dynamic>>().map((i) => DocumentGood.fromJson(i))
              .toList() ??
          [],
      model: json['model'] == null
          ? null
          : Counterparty.fromJson(SafeConverters.toMap(json['model'])),
      storage: json['storage'] == null
          ? null
          : Storage.fromJson(SafeConverters.toMap(json['storage'])),
      author: json['author'] == null
          ? null
          : Author.fromJson(SafeConverters.toMap(json['author'])),
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
      id: SafeConverters.toIntOrNull(json['id']),
      documentId: json['document_id'],
      goodVariantId: json['good_variant_id'],
      quantity: SafeConverters.toStringOrNull(json['quantity'], emptyAsNull: true),
      price: SafeConverters.toStringOrNull(json['price'], emptyAsNull: true),
      unitId: json['unit_id'],
      createdAt: SafeConverters.toStringOrNull(json['created_at'], emptyAsNull: true),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at'], emptyAsNull: true),
      sum: SafeConverters.toStringOrNull(json['sum'], emptyAsNull: true),
      goodVariant: json['good_variant'] == null
          ? null
          : GoodVariant.fromJson(SafeConverters.toMap(json['good_variant'])),
      unit: json['unit'] == null
          ? null
          : Unit.fromJson(SafeConverters.toMap(json['unit'])),
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
      id: SafeConverters.toIntOrNull(json['id']),
      goodId: json['good_id'],
      isActive: json['is_active'],
      createdAt: SafeConverters.toStringOrNull(json['created_at'], emptyAsNull: true),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at'], emptyAsNull: true),
      oneCUid: SafeConverters.toStringOrNull(json['one_c_uid'], emptyAsNull: true),
      barcode: SafeConverters.toStringOrNull(json['barcode'], emptyAsNull: true),
      fullName: SafeConverters.toStringOrNull(json['full_name'], emptyAsNull: true),
      good: json['good'] == null
          ? null
          : Good.fromJson(SafeConverters.toMap(json['good'])),
      attributeValues: SafeConverters.toList(json['attribute_values']).whereType<Map<String, dynamic>>().map((i) => AttributeValue.fromJson(i))
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
      id: SafeConverters.toIntOrNull(json['id']),
      oneCId: SafeConverters.toStringOrNull(json['one_c_id'], emptyAsNull: true),
      name: SafeConverters.toStringOrNull(json['name'], emptyAsNull: true),
      categoryId: json['category_id'],
      description: SafeConverters.toStringOrNull(json['description'], emptyAsNull: true),
      price: SafeConverters.toStringOrNull(json['price'], emptyAsNull: true),
      unitId: json['unit_id'],
      quantity: SafeConverters.toIntOrNull(json['quantity']),
      deletedAt: SafeConverters.toStringOrNull(json['deleted_at'], emptyAsNull: true),
      createdAt: SafeConverters.toStringOrNull(json['created_at'], emptyAsNull: true),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at'], emptyAsNull: true),
      isActive: json['is_active'],
      article: SafeConverters.toStringOrNull(json['article'], emptyAsNull: true),
      labelId: json['label_id'],
      getImage: json['get_image'],
      cip: SafeConverters.toStringOrNull(json['cip'], emptyAsNull: true),
      packageCode: SafeConverters.toStringOrNull(json['package_code'], emptyAsNull: true),
      category: json['category'] == null
          ? null
          : Category.fromJson(SafeConverters.toMap(json['category'])),
      unit: json['unit'] == null
          ? null
          : Unit.fromJson(SafeConverters.toMap(json['unit'])),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name'], emptyAsNull: true),
      image: SafeConverters.toStringOrNull(json['image'], emptyAsNull: true),
      parentId: json['parent_id'],
      createdAt: SafeConverters.toStringOrNull(json['created_at'], emptyAsNull: true),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at'], emptyAsNull: true),
      isActive: json['is_active'],
      hasPriceCharacteristics: json['has_price_characteristics'],
      displayType: SafeConverters.toStringOrNull(json['display_type'], emptyAsNull: true),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name'], emptyAsNull: true),
      createdAt: SafeConverters.toStringOrNull(json['created_at'], emptyAsNull: true),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at'], emptyAsNull: true),
      shortName: SafeConverters.toStringOrNull(json['short_name'], emptyAsNull: true),
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
      id: SafeConverters.toIntOrNull(json['id']),
      categoryAttributeId: json['category_attribute_id'],
      value: SafeConverters.toStringOrNull(json['value'], emptyAsNull: true),
      unitId: json['unit_id'],
      createdAt: SafeConverters.toStringOrNull(json['created_at'], emptyAsNull: true),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at'], emptyAsNull: true),
      variantAttributeId: json['variant_attribute_id'],
      variantId: json['variant_id'],
      categoryAttribute: json['category_attribute'] == null
          ? null
          : CategoryAttribute.fromJson(
              SafeConverters.toMap(json['category_attribute'])),
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
      id: SafeConverters.toIntOrNull(json['id']),
      categoryId: json['category_id'],
      attributeId: json['attribute_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isIndividual: json['is_individual'],
      showToSite: json['show_to_site'],
      attribute: json['attribute'] == null
          ? null
          : Attribute.fromJson(SafeConverters.toMap(json['attribute'])),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name'], emptyAsNull: true),
      createdAt: SafeConverters.toStringOrNull(json['created_at'], emptyAsNull: true),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at'], emptyAsNull: true),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name'], emptyAsNull: true),
      phone: SafeConverters.toStringOrNull(json['phone'], emptyAsNull: true),
      inn: SafeConverters.toIntOrNull(json['inn']),
      note: SafeConverters.toStringOrNull(json['note'], emptyAsNull: true),
      createdAt: SafeConverters.toStringOrNull(json['created_at'], emptyAsNull: true),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at'], emptyAsNull: true),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name'], emptyAsNull: true),
      createdAt: SafeConverters.toStringOrNull(json['created_at'], emptyAsNull: true),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at'], emptyAsNull: true),
      address: SafeConverters.toStringOrNull(json['address'], emptyAsNull: true),
      isActive: json['is_active'],
      deliveryServiceId: json['delivery_service_id'],
      showOnSite: json['show_on_site'],
      coordinates: SafeConverters.toIntOrNull(json['coordinates']),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name'], emptyAsNull: true),
      lastname: SafeConverters.toStringOrNull(json['lastname'], emptyAsNull: true),
      login: SafeConverters.toStringOrNull(json['login'], emptyAsNull: true),
      email: SafeConverters.toStringOrNull(json['email'], emptyAsNull: true),
      phone: SafeConverters.toStringOrNull(json['phone'], emptyAsNull: true),
      telegramUserId: SafeConverters.toStringOrNull(json['telegram_user_id'], emptyAsNull: true),
      emailVerifiedAt: SafeConverters.toStringOrNull(json['email_verified_at'], emptyAsNull: true),
      image: SafeConverters.toStringOrNull(json['image'], emptyAsNull: true),
      lastSeen: SafeConverters.toStringOrNull(json['last_seen'], emptyAsNull: true),
      deletedAt: SafeConverters.toStringOrNull(json['deleted_at'], emptyAsNull: true),
      createdAt: SafeConverters.toStringOrNull(json['created_at'], emptyAsNull: true),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at'], emptyAsNull: true),
      managerId: json['manager_id'],
      jobTitle: SafeConverters.toStringOrNull(json['job_title'], emptyAsNull: true),
      hasImage: json['has_image'],
      isFirstLogin: json['is_first_login'],
      internalNumber: SafeConverters.toStringOrNull(json['internal_number'], emptyAsNull: true),
      departmentId: json['department_id'],
      uniqueId: SafeConverters.toStringOrNull(json['unique_id'], emptyAsNull: true),
      shiftId: json['shift_id'],
      weekendPatternId: json['weekend_pattern_id'],
      workBreakId: json['work_break_id'],
      oneCId: SafeConverters.toStringOrNull(json['one_c_id'], emptyAsNull: true),
    );
  }
}

