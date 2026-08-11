import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/utils/parser.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'goods_model.dart';

// ================ Incoming Document Models ==================

class IncomingResponse {
  final List<IncomingDocument>? data;
  final Pagination? pagination;

  IncomingResponse({this.data, this.pagination});

  factory IncomingResponse.fromJson(Map<String, dynamic> json) {
    return IncomingResponse(
      data: json['data'] != null
          ? SafeConverters.toList(json['data'])
              .map((i) => IncomingDocument.fromJson(SafeConverters.toMap(i)))
              .toList()
          : null,
      pagination: SafeConverters.toMapOrNull(json['pagination']) != null
          ? Pagination.fromJson(SafeConverters.toMap(json['pagination']))
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

class IncomingDocument extends Equatable {
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
  final ExchangeRate? exchangeRate;
  final List<DocumentGood>? documentGoods;
  final Author? author;
  final Model? model;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? docNumber;
  final int? approved;

  const IncomingDocument({
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
    this.exchangeRate,
  });

  @override
  List<Object?> get props => [id, deletedAt, approved, updatedAt];

  factory IncomingDocument.fromJson(Map<String, dynamic> json) {
    final senderStorageJson = SafeConverters.toMapOrNull(json['sender_storage_id']) ??
        SafeConverters.toMapOrNull(json['sender_storage']);
    final recipientStorageJson =
        SafeConverters.toMapOrNull(json['recipient_storage_id']) ??
            SafeConverters.toMapOrNull(json['recipient_storage']);

    return IncomingDocument(
      id: SafeConverters.toIntOrNull(json['id']),
      date: SafeConverters.toDateTimeOrNull(json['date']),
      modelType: SafeConverters.toStringOrNull(json['model_type']),
      modelId: SafeConverters.toIntOrNull(json['model_id']),
      counterpartyAgreementId: SafeConverters.toIntOrNull(json['counterparty_agreement_id']),
      organizationId: SafeConverters.toIntOrNull(json['organization_id']),
      storage: SafeConverters.toMapOrNull(json['storage']) != null
          ? WareHouse.fromJson(SafeConverters.toMap(json['storage']))
          : null,
      article: SafeConverters.toMapOrNull(json['article']) != null
          ? ArticleGood.fromJson(SafeConverters.toMap(json['article']))
          : null,
      sender_storage_id: senderStorageJson != null
          ? WareHouse.fromJson(senderStorageJson)
          : null,
      recipient_storage_id: recipientStorageJson != null
          ? WareHouse.fromJson(recipientStorageJson)
          : null,
      comment: SafeConverters.toStringOrNull(json['comment']),
      currency: SafeConverters.toMapOrNull(json['currency']) != null
          ? Currency.fromJson(SafeConverters.toMap(json['currency']))
          : null,
      exchangeRate: SafeConverters.toMapOrNull(json['exchangeRate']) != null
          ? ExchangeRate.fromJson(SafeConverters.toMap(json['exchangeRate']))
          : (SafeConverters.toMapOrNull(json['exchange_rate']) != null
              ? ExchangeRate.fromJson(SafeConverters.toMap(json['exchange_rate']))
              : null),
      documentGoods: json['document_goods'] != null
          ? SafeConverters.toList(json['document_goods'])
              .map((i) => DocumentGood.fromJson(SafeConverters.toMap(i)))
              .toList()
          : null,
      author: SafeConverters.toMapOrNull(json['author']) != null
          ? Author.fromJson(SafeConverters.toMap(json['author']))
          : null,
      model: SafeConverters.toMapOrNull(json['model']) != null
          ? Model.fromJson(SafeConverters.toMap(json['model']))
          : null,
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
      deletedAt: SafeConverters.toDateTimeOrNull(json['deleted_at']),
      docNumber: SafeConverters.toStringOrNull(json['doc_number']),
      approved: SafeConverters.toIntOrNull(json['approved']),
      type: SafeConverters.toStringOrNull(json['type']),
      storageId: SafeConverters.toIntOrNull(json['storage_id']),
      currencyId: SafeConverters.toIntOrNull(json['currency_id']),
      authorId: SafeConverters.toIntOrNull(json['author_id']),
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
      'exchangeRate': exchangeRate?.toJson(),
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

        num unitMultiplier =
            1.0; // USE 1 for amount, DO NOT CALCULATE BASED ON unitId

        // debugPrint("=== Processing IncomingDocumentGood ===");
        // debugPrint("DocumentGood.unitId: ${documentGood.unitId}");
        //
        // final good = documentGood.good;
        //
        // if (good != null && good.units != null && documentGood.unitId != null) {
        //   // Find the unit with matching id in good.units array
        //   try {
        //     final matchingUnit = good.units!.firstWhere(
        //       (unit) => unit.id == documentGood.unitId,
        //     );
        //     unitMultiplier = matchingUnit.amount ?? 1.0;
        //     debugPrint("Found matching unit: id=${matchingUnit.id}, amount=${matchingUnit.amount}");
        //   } catch (e) {
        //     debugPrint("Unit not found in good.units array, using default multiplier 1.0");
        //   }
        // }
        //
        // debugPrint("Good.units array: ${good?.units?.map((u) => 'id:${u.id}, amount:${u.amount}').toList()}");
        // debugPrint("FINAL: price=$price, quantity=$quantity, multiplier=$unitMultiplier");
        // debugPrint("Item total: ${quantity * price * unitMultiplier}");
        // debugPrint("=== End IncomingDocumentGood ===\n");

        return sum + (quantity * price * unitMultiplier);
      },
    );
  }

  int get totalQuantity {
    if (documentGoods == null || documentGoods!.isEmpty) return 0;
    return documentGoods!
        .fold(0, (sum, good) => sum + (good.quantity?.toInt() ?? 0));
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

  IncomingDocument copyWith({
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
    ExchangeRate? exchangeRate,
    WareHouse? sender_storage_id,
    WareHouse? recipient_storage_id,
  }) {
    return IncomingDocument(
      id: id ?? this.id,
      date: date ?? this.date,
      modelType: modelType ?? this.modelType,
      modelId: modelId ?? this.modelId,
      counterpartyAgreementId:
          counterpartyAgreementId ?? this.counterpartyAgreementId,
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
      exchangeRate: exchangeRate ?? this.exchangeRate,
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: json['name'],
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      telegramUserId: json['telegram_user_id'],
      emailVerifiedAt: SafeConverters.toDateTimeOrNull(json['email_verified_at']),
      image: json['image'],
      lastSeen: SafeConverters.toDateTimeOrNull(json['last_seen']),
      deletedAt: SafeConverters.toDateTimeOrNull(json['deleted_at']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
      managerId: SafeConverters.toIntOrNull(json['manager_id']),
      jobTitle: json['job_title'],
      hasImage: SafeConverters.toIntOrNull(json['has_image']),
      isFirstLogin: SafeConverters.toIntOrNull(json['is_first_login']),
      internalNumber:
          json['internal_number']?.toString(), // ← Добавлена конвертация
      departmentId: SafeConverters.toIntOrNull(json['department_id']),
      uniqueId: json['unique_id'],
      shiftId: SafeConverters.toIntOrNull(json['shift_id']),
      weekendPatternId: SafeConverters.toIntOrNull(json['weekend_pattern_id']),
      workBreakId: SafeConverters.toIntOrNull(json['work_break_id']),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: json['name'],
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: json['name'],
      digitalCode: SafeConverters.toIntOrNull(json['digital_code']),
      symbolCode: json['symbol_code'],
      organizationId: SafeConverters.toIntOrNull(json['organization_id']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
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

class ExchangeRate {
  final int? id;
  final DateTime? date;
  final int? currencyId;
  final String? value;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExchangeRate({
    this.id,
    this.date,
    this.currencyId,
    this.value,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      id: SafeConverters.toIntOrNull(json['id']),
      date: SafeConverters.toDateTimeOrNull(json['date']),
      currencyId: SafeConverters.toIntOrNull(json['currency_id']),
      value: json['value']?.toString(),
      deletedAt: SafeConverters.toDateTimeOrNull(json['deleted_at']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date?.toIso8601String(),
      'currency_id': currencyId,
      'value': value,
      'deleted_at': deletedAt?.toIso8601String(),
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
  final String? costPrice;
  final Unit? unit;
  final GoodVariant? goodVariant;
  final List<DocumentGoodMaterial>? materials;

  Unit get selectedUnit {
    if (unit?.id != null && good?.units != null) {
      final value = good!.units!.firstWhere(
        (u) => u.id == unit!.id,
        orElse: () => Unit(id: unit!.id, name: unit!.name, amount: 1),
      );

      debugPrint(
          "Selected unit for DocumentGood id=$id: id=${value.id}, name=${value.name}, amount=${value.amount}");

      return value;
    }

    return Unit(id: unit?.id, name: unit?.name, amount: 1);
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
    this.costPrice,
    this.unit,
    this.goodVariant,
    this.materials,
  });

  factory DocumentGood.fromJson(Map<String, dynamic> json) {
    final unitObj = SafeConverters.toMapOrNull(json['unit']) != null
        ? Unit.fromJson(SafeConverters.toMap(json['unit']))
        : null;

    return DocumentGood(
      id: SafeConverters.toIntOrNull(json['id']),
      documentId: SafeConverters.toIntOrNull(json['document_id']),
      variantId: SafeConverters.toIntOrNull(json['variant_id']),
      good: SafeConverters.toMapOrNull(json['good']) != null
          ? Good.fromJson(SafeConverters.toMap(json['good']))
          : null,
      quantity: SafeConverters.toNumOrNull(json['quantity']),
      price: SafeConverters.toStringOrNull(json['price']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
      attributes: json['attributes'] != null
          ? SafeConverters.toList(json['attributes'])
              .map((i) => Attribute.fromJson(SafeConverters.toMap(i)))
              .toList()
          : null,
      fullName: SafeConverters.toStringOrNull(json['full_name']),
      unitId: SafeConverters.toIntOrNull(json['unit_id']) ?? unitObj?.id,
      goodVariant: SafeConverters.toMapOrNull(json['good_variant']) != null
          ? GoodVariant.fromJson(SafeConverters.toMap(json['good_variant']))
          : null,
      goodVariantId: SafeConverters.toIntOrNull(json['good_variant_id']),
      sum: SafeConverters.toStringOrNull(json['sum']),
      costPrice: SafeConverters.toStringOrNull(json['cost_price']) ??
          SafeConverters.toStringOrNull(json['cost_price_per_unit']),
      unit: unitObj,
      materials: json['materials'] != null
          ? SafeConverters.toList(json['materials'])
              .map((i) => DocumentGoodMaterial.fromJson(SafeConverters.toMap(i)))
              .toList()
          : null,
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
      'cost_price': costPrice,
      'materials': materials?.map((e) => e.toJson()).toList(),
    };
  }
}

class DocumentGoodMaterial {
  final int? id;
  final int? documentGoodId;
  final int? goodVariantId;
  final int? unitId;
  final num? norm;
  final num? quantity;
  final Unit? unit;
  final GoodVariant? goodVariant;

  const DocumentGoodMaterial({
    this.id,
    this.documentGoodId,
    this.goodVariantId,
    this.unitId,
    this.norm,
    this.quantity,
    this.unit,
    this.goodVariant,
  });

  factory DocumentGoodMaterial.fromJson(Map<String, dynamic> json) {
    return DocumentGoodMaterial(
      id: SafeConverters.toIntOrNull(json['id']),
      documentGoodId: SafeConverters.toIntOrNull(json['document_good_id']),
      goodVariantId: SafeConverters.toIntOrNull(json['good_variant_id']),
      unitId: SafeConverters.toIntOrNull(json['unit_id']),
      norm: SafeConverters.toNumOrNull(json['norm']),
      quantity: SafeConverters.toNumOrNull(json['quantity']),
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
      goodVariant: json['good_variant'] != null
          ? GoodVariant.fromJson(json['good_variant'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_good_id': documentGoodId,
      'good_variant_id': goodVariantId,
      'unit_id': unitId,
      'norm': norm,
      'quantity': quantity,
      'unit': unit?.toJson(),
      'good_variant': goodVariant?.toJson(),
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
      units: json['units'] != null
          ? SafeConverters.toList(json['units'])
              .map((i) => Unit.fromJson(SafeConverters.toMap(i)))
              .toList()
          : null,
      unitId: SafeConverters.toIntOrNull(json['unit_id']),
      id: SafeConverters.toIntOrNull(json['id']),
      oneCId: SafeConverters.toStringOrNull(json['one_c_id']),
      name: SafeConverters.toStringOrNull(json['name']),
      categoryId: SafeConverters.toIntOrNull(json['category_id']),
      description: SafeConverters.toStringOrNull(json['description']),
      price: SafeConverters.toStringOrNull(json['price']),
      quantity: SafeConverters.toIntOrNull(json['quantity']),
      deletedAt: SafeConverters.toDateTimeOrNull(json['deleted_at']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
      isActive: SafeConverters.toBoolOrNull(json['is_active']),
      article: SafeConverters.toStringOrNull(json['article']),
      labelId: SafeConverters.toIntOrNull(json['label_id']),
      getImage: SafeConverters.toBoolOrNull(json['get_image']),
      cip: SafeConverters.toStringOrNull(json['cip']),
      packageCode: SafeConverters.toStringOrNull(json['package_code']),
      files: json['files'] != null
          ? SafeConverters.toList(json['files'])
              .map((i) => GoodFile.fromJson(SafeConverters.toMap(i)))
              .toList()
          : null,
      measurements: SafeConverters.toList(json['measurements']).isEmpty
          ? null
          : SafeConverters.toList(json['measurements']),
      category: json['category'],
      unit: SafeConverters.toMapOrNull(json['unit']) != null
          ? Unit.fromJson(SafeConverters.toMap(json['unit']))
          : null,
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
      id: SafeConverters.toIntOrNull(json['id']),
      path: json['path'],
      type: json['type'],
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
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
      id: SafeConverters.toIntOrNull(json['id']),
      goodId: SafeConverters.toIntOrNull(json['good_id']),
      isActive: SafeConverters.toBoolOrNull(json['is_active']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
      oneCUid: SafeConverters.toStringOrNull(json['one_c_uid']),
      barcode: SafeConverters.toStringOrNull(json['barcode']),
      fullName: SafeConverters.toStringOrNull(json['full_name']),
      good: SafeConverters.toMapOrNull(json['good']) != null
          ? Good.fromJson(SafeConverters.toMap(json['good']))
          : null,
      attributeValues: json['attribute_values'] != null
          ? SafeConverters.toList(json['attribute_values'])
              .map((i) => AttributeValue.fromJson(SafeConverters.toMap(i)))
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
      id: SafeConverters.toIntOrNull(json['id']),
      categoryAttributeId: SafeConverters.toIntOrNull(json['category_attribute_id']),
      value: SafeConverters.toStringOrNull(json['value']),
      unitId: SafeConverters.toIntOrNull(json['unit_id']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
      variantAttributeId: SafeConverters.toIntOrNull(json['variant_attribute_id']),
      variantId: SafeConverters.toIntOrNull(json['variant_id']),
      categoryAttribute: SafeConverters.toMapOrNull(json['category_attribute']) != null
          ? CategoryAttribute.fromJson(SafeConverters.toMap(json['category_attribute']))
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
      id: SafeConverters.toIntOrNull(json['id']),
      categoryId: SafeConverters.toIntOrNull(json['category_id']),
      attributeId: SafeConverters.toIntOrNull(json['attribute_id']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
      isIndividual: SafeConverters.toBoolOrNull(json['is_individual']),
      showToSite: SafeConverters.toBoolOrNull(json['show_to_site']),
      attribute: SafeConverters.toMapOrNull(json['attribute']) != null
          ? AttributeModel.fromJson(SafeConverters.toMap(json['attribute']))
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: json['name'],
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
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
  final int? currencyId;
  final Currency? currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Model({
    this.id,
    this.name,
    this.phone,
    this.inn,
    this.note,
    this.currencyId,
    this.currency,
    this.createdAt,
    this.updatedAt,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: SafeConverters.toIntOrNull(json['id']),
      name: json['name'],
      phone: json['phone'],
      inn: SafeConverters.toIntOrNull(json['inn']),
      note: json['note'],
      currencyId: SafeConverters.toIntOrNull(json['currency_id']),
      currency:
          json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'inn': inn,
      'note': note,
      'currency_id': currencyId,
      'currency': currency?.toJson(),
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
      total: SafeConverters.toIntOrNull(json['total']),
      count: SafeConverters.toIntOrNull(json['count']),
      perPage: SafeConverters.toIntOrNull(json['per_page']),
      currentPage: SafeConverters.toIntOrNull(json['current_page']),
      totalPages: SafeConverters.toIntOrNull(json['total_pages']),
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
      id: SafeConverters.toIntOrNull(json['id']),
      categoryAttributeId: SafeConverters.toIntOrNull(json['category_attribute_id']),
      value: SafeConverters.toStringOrNull(json['value']),
      unitId: SafeConverters.toIntOrNull(json['unit_id']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
      variantAttributeId: SafeConverters.toIntOrNull(json['variant_attribute_id']),
      variantId: SafeConverters.toIntOrNull(json['variant_id']),
      categoryAttribute: SafeConverters.toMapOrNull(json['category_attribute']) != null
          ? CategoryAttribute.fromJson(SafeConverters.toMap(json['category_attribute']))
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
      id: SafeConverters.toIntOrNull(json['id']),
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
