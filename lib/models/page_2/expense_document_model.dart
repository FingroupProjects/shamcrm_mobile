import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/utils/parser.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'goods_model.dart';

// ================ Expense Document Models ==================

class ExpenseResponse {
  final List<ExpenseDocument>? data;
  final Pagination? pagination;

  ExpenseResponse({this.data, this.pagination});

  factory ExpenseResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseResponse(
      data: json['data'] != null
          ? (json['data'] as List)
              .map((i) => ExpenseDocument.fromJson(i))
              .toList()
          : null,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.map((e) => e.toJson()).toList(),
      'pagination': pagination?.toJson(),
    };
  }
}

class ExpenseDocument extends Equatable {
  final int? id;
  final DateTime? date;
  final String? modelType;
  final int? modelId;
  final int? counterpartyAgreementId;
  final int? organizationId;
  final WareHouse? storage;
  final ArticleGood? article;
  final WareHouse? sender_storage_id;
  final WareHouse? recipient_storage_id;
  final String? type;
  final int? storageId;
  final int? currencyId;
  final int? authorId;
  final String? comment;
  final Currency? currency;
  final List<DocumentGood>? documentGoods;
  final Author? author;
  final Model? model;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? docNumber;
  final int? approved;

  const ExpenseDocument({
    this.id,
    this.date,
    this.modelType,
    this.modelId,
    this.counterpartyAgreementId,
    this.organizationId,
    this.storage,
    this.article,
    this.sender_storage_id,
    this.recipient_storage_id,
    this.comment,
    this.currency,
    this.documentGoods,
    this.author,
    this.model,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.docNumber,
    this.approved,
    this.type,
    this.storageId,
    this.currencyId,
    this.authorId,
  });

  @override
  List<Object?> get props => [
    id,
    deletedAt,
    approved,
    updatedAt
  ];

  factory ExpenseDocument.fromJson(Map<String, dynamic> json) {
    return ExpenseDocument(
      id: parseInt(json['id']),
      date: parseDate(json['date']),
      modelType: json['model_type'],
      modelId: parseInt(json['model_id']),
      counterpartyAgreementId: parseInt(json['counterparty_agreement_id']),
      organizationId: parseInt(json['organization_id']),
      storage: json['storage'] != null ? WareHouse.fromJson(json['storage']) : null,
      article: json['article'] != null ? ArticleGood.fromJson(json['article']) : null,
      sender_storage_id: json['sender_storage_id'] != null ? WareHouse.fromJson(json['sender_storage_id']) : null,
      recipient_storage_id: json['recipient_storage_id'] != null ? WareHouse.fromJson(json['recipient_storage_id']) : null,
      comment: json['comment'],
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      documentGoods: json['document_goods'] != null
          ? (json['document_goods'] as List).map((i) => DocumentGood.fromJson(i)).toList() : null,
      author: json['author'] != null ? Author.fromJson(json['author']) : null,
      model: json['model'] != null ? Model.fromJson(json['model']) : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      deletedAt: parseDate(json['deleted_at']),
      docNumber: json['doc_number'],
      approved: parseInt(json['approved']),
      type: json['type'],
      storageId: parseInt(json['storage_id']),
      currencyId: parseInt(json['currency_id']),
      authorId: parseInt(json['author_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date?.toIso8601String(),
      'model_type': modelType,
      'model_id': modelId,
      'counterparty_agreement_id': counterpartyAgreementId,
      'organization_id': organizationId,
      'storage': storage?.toJson(),
      'article': article?.toJson(),
      'comment': comment,
      'currency': currency?.toJson(),
      'document_goods': documentGoods?.map((e) => e.toJson()).toList(),
      'model': model?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'doc_number': docNumber,
      'approved': approved,
      'author': author?.toJson(),
      'type': type,
      'storage_id': storageId,
      'currency_id': currencyId,
      'author_id': authorId,
      'sender_storage_id': sender_storage_id?.toJson(),
      'recipient_storage_id': recipient_storage_id?.toJson(),
    };
  }

  double get totalSum {
    if (documentGoods == null || documentGoods!.isEmpty) return 0.0;
    return documentGoods!.fold(
      0.0,
      (sum, documentGood) {
        final quantity = documentGood.quantity ?? 0;
        final price = double.tryParse(documentGood.price ?? '0') ?? 0;

        num unitMultiplier = documentGood.selectedUnit.amount ?? 1;

        debugPrint("selected unit = ${documentGood.selectedUnit.name}, amount=${documentGood.selectedUnit.amount}");
        debugPrint('Calculating sum for documentGood id=${documentGood.id}: quantity=$quantity, price=$price, unitMultiplier=$unitMultiplier');

        return sum + (quantity * price * unitMultiplier);
      },
    );
  }

  int get totalQuantity {
    if (documentGoods == null || documentGoods!.isEmpty) return 0;
    return documentGoods!.fold(0, (sum, good) => sum + (good.quantity?.toInt() ?? 0));
  }

  String get statusText {
    if (deletedAt != null) {
      return 'Удален';
    }
    return approved == 1 ? 'Проведен' : 'Не проведен';
  }

  Color get statusColor {
    if (deletedAt != null) {
      return Colors.red;
    }
    return approved == 1 ? Colors.green : Colors.orange;
  }

  ExpenseDocument copyWith({
    int? id,
    DateTime? date,
    String? modelType,
    int? modelId,
    int? counterpartyAgreementId,
    int? organizationId,
    WareHouse? storage,
    ArticleGood? article,
    String? comment,
    Currency? currency,
    List<DocumentGood>? documentGoods,
    Model? model,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? docNumber,
    int? approved,
    bool clearDeletedAt = false,
    String? type,
    int? storageId,
    int? currencyId,
    int? authorId,
    WareHouse? sender_storage_id,
    WareHouse? recipient_storage_id,
  }) {
    return ExpenseDocument(
      id: id ?? this.id,
      date: date ?? this.date,
      modelType: modelType ?? this.modelType,
      modelId: modelId ?? this.modelId,
      counterpartyAgreementId: counterpartyAgreementId ?? this.counterpartyAgreementId,
      organizationId: organizationId ?? this.organizationId,
      storage: storage ?? this.storage,
      article: article ?? this.article,
      comment: comment ?? this.comment,
      currency: currency ?? this.currency,
      documentGoods: documentGoods ?? this.documentGoods,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      docNumber: docNumber ?? this.docNumber,
      approved: approved ?? this.approved,
      type: type ?? this.type,
      storageId: storageId ?? this.storageId,
      currencyId: currencyId ?? this.currencyId,
      authorId: authorId ?? this.authorId,
      sender_storage_id: sender_storage_id ?? this.sender_storage_id,
      recipient_storage_id: recipient_storage_id ?? this.recipient_storage_id,
    );
  }
}

// ================ Supporting Models ==================

class Author {
  final int? id;
  final String? name;
  final String? lastname;
  final String? login;
  final String? email;
  final String? phone;
  final String? telegramUserId;
  final DateTime? emailVerifiedAt;
  final String? image;
  final DateTime? lastSeen;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
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
      id: parseInt(json['id']),
      name: json['name'],
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      telegramUserId: json['telegram_user_id'],
      emailVerifiedAt: parseDate(json['email_verified_at']),
      image: json['image'],
      lastSeen: parseDate(json['last_seen']),
      deletedAt: parseDate(json['deleted_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      managerId: parseInt(json['manager_id']),
      jobTitle: json['job_title'],
      hasImage: parseInt(json['has_image']),
      isFirstLogin: parseInt(json['is_first_login']),
      internalNumber: json['internal_number']?.toString(),  // ← Добавлена конвертация
      departmentId: parseInt(json['department_id']),
      uniqueId: json['unique_id'],
      shiftId: parseInt(json['shift_id']),
      weekendPatternId: parseInt(json['weekend_pattern_id']),
      workBreakId: parseInt(json['work_break_id']),
      oneCId: json['one_c_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastname': lastname,
      'login': login,
      'email': email,
      'phone': phone,
      'telegram_user_id': telegramUserId,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'image': image,
      'last_seen': lastSeen?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'manager_id': managerId,
      'job_title': jobTitle,
      'has_image': hasImage,
      'is_first_login': isFirstLogin,
      'internal_number': internalNumber,
      'department_id': departmentId,
      'unique_id': uniqueId,
      'shift_id': shiftId,
      'weekend_pattern_id': weekendPatternId,
      'work_break_id': workBreakId,
      'one_c_id': oneCId,
    };
  }
}

class Storage {
  final int? id;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Storage({this.id, this.name, this.createdAt, this.updatedAt});

  factory Storage.fromJson(Map<String, dynamic> json) {
    return Storage(
      id: parseInt(json['id']),
      name: json['name'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class Currency {
  final int? id;
  final String? name;
  final int? digitalCode;
  final String? symbolCode;
  final int? organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Currency({
    this.id,
    this.name,
    this.digitalCode,
    this.symbolCode,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: parseInt(json['id']),
      name: json['name'],
      digitalCode: parseInt(json['digital_code']),
      symbolCode: json['symbol_code'],
      organizationId: parseInt(json['organization_id']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'digital_code': digitalCode,
      'symbol_code': symbolCode,
      'organization_id': organizationId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

 class DocumentGood {
  final int? id;
  final int? documentId;
  final int? variantId;
  final Good? good;
  final num? quantity;
  final String? price;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Attribute>? attributes;
  final String? fullName;
  final int? unitId; // ИЗМЕНЕНО: int? вместо Unit?
  final int? goodVariantId;
  final String? sum;
  final Unit? unit;
  final GoodVariant? goodVariant;

  Unit get selectedUnit {
    if (unitId != null && goodVariant?.good?.units != null) {
      return goodVariant!.good!.units!
          .firstWhere((u) => u.id == unitId, orElse: () => Unit(id: unitId, name: 'Шт', amount: 1));
    }
    return Unit(id: unit?.id, name: 'Шт', amount: 1);
  }

  DocumentGood({
    this.id,
    this.documentId,
    this.variantId,
    this.good,
    this.quantity,
    this.price,
    this.createdAt,
    this.updatedAt,
    this.attributes,
    this.fullName,
    this.unitId,
    this.goodVariantId,
    this.sum,
    this.unit,
    this.goodVariant,
  });

  factory DocumentGood.fromJson(Map<String, dynamic> json) {
    // Parse the unit object first
    final unitObj = json['unit'] != null ? Unit.fromJson(json['unit']) : null;

    return DocumentGood(
      id: parseInt(json['id']),
      documentId: parseInt(json['document_id']),
      variantId: parseInt(json['variant_id']),
      good: json['good'] != null ? Good.fromJson(json['good']) : null,
      quantity: parseNum(json['quantity']),
      price: json['price'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      attributes: json['attributes'] != null
          ? (json['attributes'] as List)
          .map((i) => Attribute.fromJson(i))
          .toList()
          : null,
      fullName: json['full_name'] as String?,
      // FIXED: Extract unit_id from the unit object if unit_id field doesn't exist
      unitId: parseInt(json['unit_id']) ?? unitObj?.id,
      goodVariant: json['good_variant'] != null
          ? GoodVariant.fromJson(json['good_variant'])
          : null,
      goodVariantId: parseInt(json['good_variant_id']),
      sum: json['sum'] as String?,
      unit: unitObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'variant_id': variantId,
      'good': good?.toJson(),
      'quantity': quantity,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'attributes': attributes?.map((e) => e.toJson()).toList(),
      'full_name': fullName,
      'unit_id': unitId,
    };
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
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isActive;
  final String? article;
  final int? labelId;
  final bool? getImage;
  final String? cip;
  final String? packageCode;
  final List<GoodFile>? files;
  final List<Unit>? units;
  final List<dynamic>? measurements;
  final dynamic category;
  final Unit? unit;

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
    this.files,
    this.units,
    this.measurements,
    this.category,
    this.unit,
  });

  factory Good.fromJson(Map<String, dynamic> json) {
    return Good(
      units: json['units'] != null ? (json['units'] as List).map((i) => Unit.fromJson(i)).toList() : null,
      unitId: json['unit_id'] is int ? json['unit_id']
          : (json['unit_id'] is String ? int.tryParse(json['unit_id']) : null),
      id: parseInt(json['id']),
      oneCId: json['one_c_id'],
      name: json['name'],
      categoryId: parseInt(json['category_id']),
      description: json['description'],
      price: json['price'],
      quantity: parseInt(json['quantity']),
      deletedAt: parseDate(json['deleted_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      isActive: json['is_active'],
      article: json['article'],
      labelId: parseInt(json['label_id']),
      getImage: json['get_image'],
      cip: json['cip'],
      packageCode: json['package_code'],
      files: json['files'] != null
          ? (json['files'] as List).map((i) => GoodFile.fromJson(i)).toList()
          : null,
      measurements: json['measurements'] as List<dynamic>?,
      category: json['category'],
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'one_c_id': oneCId,
      'name': name,
      'category_id': categoryId,
      'description': description,
      'price': price,
      'unit_id': unitId,
      'quantity': quantity,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'article': article,
      'label_id': labelId,
      'get_image': getImage,
      'cip': cip,
      'package_code': packageCode,
      'files': files?.map((e) => e.toJson()).toList(),
      'units': units?.map((e) => e.toJson()).toList(),
      'measurements': measurements,
      'category': category,
      'unit': unit?.toJson(),
    };
  }

  static int? parseInt(dynamic value) {
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

  static DateTime? parseDate(dynamic dateStr) {
    if (dateStr == null || dateStr == '' || dateStr is! String) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      //print('Error parsing date $dateStr: $e');
      return null;
    }
  }
}

class GoodFile {
  final int? id;
  final String? path;
  final String? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GoodFile({
    this.id,
    this.path,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory GoodFile.fromJson(Map<String, dynamic> json) {
    return GoodFile(
      id: parseInt(json['id']),
      path: json['path'],
      type: json['type'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'type': type,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class GoodVariant {
  final int? id;
  final int? goodId;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
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
      id: parseInt(json['id']),
      goodId: parseInt(json['good_id']),
      isActive: json['is_active'] is int
          ? json['is_active'] == 1
          : json['is_active'] as bool?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      oneCUid: json['one_c_uid'],
      barcode: json['barcode'],
      fullName: json['full_name'],
      good: json['good'] != null ? Good.fromJson(json['good']) : null,
      attributeValues: json['attribute_values'] != null
          ? (json['attribute_values'] as List)
          .map((i) => AttributeValue.fromJson(i))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'good_id': goodId,
      'is_active': isActive == true ? 1 : (isActive == false ? 0 : null),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'one_c_uid': oneCUid,
      'barcode': barcode,
      'full_name': fullName,
      'good': good?.toJson(),
      'attribute_values': attributeValues?.map((e) => e.toJson()).toList(),
    };
  }

  static int? parseInt(dynamic value) {
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
    //print('Unexpected type for int parsing: ${value.runtimeType}');
    return null;
  }

  static DateTime? parseDate(dynamic dateStr) {
    if (dateStr == null || dateStr == '' || dateStr is! String) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      //print('Error parsing date $dateStr: $e');
      return null;
    }
  }
}

class Attribute {
  final int? id;
  final int? categoryAttributeId;
  final String? value;
  final int? unitId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? variantAttributeId;
  final int? variantId;
  final CategoryAttribute? categoryAttribute;

  Attribute({
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

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: parseInt(json['id']),
      categoryAttributeId: parseInt(json['category_attribute_id']),
      value: json['value'],
      unitId: parseInt(json['unit_id']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      variantAttributeId: parseInt(json['variant_attribute_id']),
      variantId: parseInt(json['variant_id']),
      categoryAttribute: json['category_attribute'] != null
          ? CategoryAttribute.fromJson(json['category_attribute'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_attribute_id': categoryAttributeId,
      'value': value,
      'unit_id': unitId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'variant_attribute_id': variantAttributeId,
      'variant_id': variantId,
      'category_attribute': categoryAttribute?.toJson(),
    };
  }
}

class CategoryAttribute {
  final int? id;
  final int? categoryId;
  final int? attributeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isIndividual;
  final bool? showToSite;
  final AttributeModel? attribute;

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
      id: parseInt(json['id']),
      categoryId: parseInt(json['category_id']),
      attributeId: parseInt(json['attribute_id']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isIndividual: json['is_individual'],
      showToSite: json['show_to_site'],
      attribute: json['attribute'] != null
          ? AttributeModel.fromJson(json['attribute'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'attribute_id': attributeId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_individual': isIndividual,
      'show_to_site': showToSite,
      'attribute': attribute?.toJson(),
    };
  }
}

class AttributeModel {
  final int? id;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttributeModel({this.id, this.name, this.createdAt, this.updatedAt});

  factory AttributeModel.fromJson(Map<String, dynamic> json) {
    return AttributeModel(
      id: parseInt(json['id']),
      name: json['name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class Model {
  final int? id;
  final String? name;
  final String? phone;
  final int? inn;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Model({
    this.id,
    this.name,
    this.phone,
    this.inn,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: parseInt(json['id']),
      name: json['name'],
      phone: json['phone'],
      inn: parseInt(json['inn']),
      note: json['note'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'inn': inn,
      'note': note,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class Pagination {
  final int? total;
  final int? count;
  final int? perPage;
  final int? currentPage;
  final int? totalPages;

  Pagination(
      {this.total,
      this.count,
      this.perPage,
      this.currentPage,
      this.totalPages});

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: parseInt(json['total']),
      count: parseInt(json['count']),
      perPage: parseInt(json['per_page']),
      currentPage: parseInt(json['current_page']),
      totalPages: parseInt(json['total_pages']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'count': count,
      'per_page': perPage,
      'current_page': currentPage,
      'total_pages': totalPages,
    };
  }
}

class AttributeValue {
  final int? id;
  final int? categoryAttributeId;
  final String? value;
  final int? unitId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
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
      id: parseInt(json['id']),
      categoryAttributeId: parseInt(json['category_attribute_id']),
      value: json['value'],
      unitId: parseInt(json['unit_id']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      variantAttributeId: parseInt(json['variant_attribute_id']),
      variantId: parseInt(json['variant_id']),
      categoryAttribute: json['category_attribute'] != null
          ? CategoryAttribute.fromJson(json['category_attribute'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_attribute_id': categoryAttributeId,
      'value': value,
      'unit_id': unitId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'variant_attribute_id': variantAttributeId,
      'variant_id': variantId,
      'category_attribute': categoryAttribute?.toJson(),
    };
  }
}

class ArticleGood {

  final int? id;
  final String? name;
  final String? type;

  ArticleGood({this.id, this.name, this.type});
  factory ArticleGood.fromJson(Map<String, dynamic> json) {
    return ArticleGood(
      id: parseInt(json['id']),
      name: json['name'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  @override
  String toString() {
    return name ?? '';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArticleGood && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}