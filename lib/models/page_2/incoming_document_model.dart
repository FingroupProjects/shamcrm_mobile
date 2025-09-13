import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:flutter/material.dart';

class IncomingResponse {
  final List<IncomingDocument>? data;
  final Pagination? pagination;

  IncomingResponse({this.data, this.pagination});

  factory IncomingResponse.fromJson(Map<String, dynamic> json) {
    return IncomingResponse(
      data: json['data'] != null
          ? (json['data'] as List)
              .map((i) => IncomingDocument.fromJson(i))
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

class IncomingDocument {
  final int? id;
  final DateTime? date;
  final String? modelType;
  final int? modelId;
  final int? counterpartyAgreementId;
  final int? organizationId;
  final WareHouse? storage;
  final String? comment;
  final Currency? currency;
  final List<DocumentGood>? documentGoods;
  final Model? model;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? docNumber;
  final int? approved;

  IncomingDocument({
    this.id,
    this.date,
    this.modelType,
    this.modelId,
    this.counterpartyAgreementId,
    this.organizationId,
    this.storage,
    this.comment,
    this.currency,
    this.documentGoods,
    this.model,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.docNumber,
    this.approved,
  });

  factory IncomingDocument.fromJson(Map<String, dynamic> json) {
    return IncomingDocument(
      id: json['id'],
      date: _parseDate(json['date']),
      modelType: json['model_type'],
      modelId: json['model_id'],
      counterpartyAgreementId: json['counterparty_agreement_id'],
      organizationId: json['organization_id'],
      storage:
          json['storage'] != null ? WareHouse.fromJson(json['storage']) : null,
      comment: json['comment'],
      currency:
          json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      documentGoods: json['document_goods'] != null
          ? (json['document_goods'] as List)
              .map((i) => DocumentGood.fromJson(i))
              .toList()
          : null,
      model: json['model'] != null ? Model.fromJson(json['model']) : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseDate(json['deleted_at']),
      docNumber: json['doc_number'],
      approved: json['approved'],
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
      'comment': comment,
      'currency': currency?.toJson(),
      'document_goods': documentGoods?.map((e) => e.toJson()).toList(),
      'model': model?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'doc_number': docNumber,
      'approved': approved,
    };
  }

  double get totalSum {
    if (documentGoods == null || documentGoods!.isEmpty) return 0.0;
    return documentGoods!.fold(
        0.0,
        (sum, good) =>
            sum +
            (good.quantity ?? 0) * (double.tryParse(good.price ?? '0') ?? 0));
  }

  int get totalQuantity {
    if (documentGoods == null || documentGoods!.isEmpty) return 0;
    return documentGoods!.fold(0, (sum, good) => sum + (good.quantity ?? 0));
  }

  // Обновленная логика определения статуса
  String get statusText {
    // Приоритет: сначала проверяем deleted_at
    if (deletedAt != null) {
      return 'Удален';
    }
    // Затем проверяем approved
    return approved == 1 ? 'Проведен' : 'Не проведен';
  }

  // Обновленная логика определения цвета статуса
  Color get statusColor {
    // Приоритет: сначала проверяем deleted_at
    if (deletedAt != null) {
      return Colors.red; // Красный цвет для удаленных документов
    }
    // Затем проверяем approved
    return approved == 1 ? Colors.green : Colors.orange;
  }

  // Метод copyWith для создания копии с измененными полями
  IncomingDocument copyWith({
    int? id,
    DateTime? date,
    String? modelType,
    int? modelId,
    int? counterpartyAgreementId,
    int? organizationId,
    Storage? storage,
    String? comment,
    Currency? currency,
    List<DocumentGood>? documentGoods,
    Model? model,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? docNumber,
    int? approved,
    bool clearDeletedAt = false, // Специальный флаг для очистки deletedAt
  }) {
    return IncomingDocument(
      id: id ?? this.id,
      date: date ?? this.date,
      modelType: modelType ?? this.modelType,
      modelId: modelId ?? this.modelId,
      counterpartyAgreementId: counterpartyAgreementId ?? this.counterpartyAgreementId,
      organizationId: organizationId ?? this.organizationId,
      storage: storage ?? this.storage,
      comment: comment ?? this.comment,
      currency: currency ?? this.currency,
      documentGoods: documentGoods ?? this.documentGoods,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      docNumber: docNumber ?? this.docNumber,
      approved: approved ?? this.approved,
    );
  }

  // Вспомогательная функция для безопасного парсинга даты
  static DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null || dateStr == '' || dateStr is! String) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      print('Error parsing date $dateStr: $e');
      return null; // Возвращаем null в случае ошибки
    }
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
      id: json['id'],
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
      id: json['id'],
      name: json['name'],
      digitalCode: json['digital_code'],
      symbolCode: json['symbol_code'],
      organizationId: json['organization_id'],
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
  final int? quantity;
  final String? price;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Attribute>? attributes;

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
  });

  factory DocumentGood.fromJson(Map<String, dynamic> json) {
    return DocumentGood(
      id: json['id'],
      documentId: json['document_id'],
      variantId: json['variant_id'],
      good: json['good'] != null ? Good.fromJson(json['good']) : null,
      quantity: json['quantity'],
      price: json['price'],
      createdAt: IncomingDocument._parseDate(json['created_at']),
      updatedAt: IncomingDocument._parseDate(json['updated_at']),
      attributes: json['attributes'] != null
          ? (json['attributes'] as List)
              .map((i) => Attribute.fromJson(i))
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
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isActive: json['is_active'],
      article: json['article'],
      labelId: json['label_id'],
      getImage: json['get_image'],
      cip: json['cip'],
      packageCode: json['package_code'],
      files: json['files'] != null
          ? (json['files'] as List).map((i) => GoodFile.fromJson(i)).toList()
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
      id: json['id'],
      path: json['path'],
      type: json['type'],
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
      'path': path,
      'type': type,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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
      id: json['id'],
      categoryAttributeId: json['category_attribute_id'],
      value: json['value'],
      unitId: json['unit_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      variantAttributeId: json['variant_attribute_id'],
      variantId: json['variant_id'],
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
      id: json['id'],
      categoryId: json['category_id'],
      attributeId: json['attribute_id'],
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
      id: json['id'],
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
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      inn: json['inn'],
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
      total: json['total'],
      count: json['count'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
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
