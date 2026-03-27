// import 'package:flutter/material.dart';
// import 'package:json_annotation/json_annotation.dart';


// // @JsonSerializable()
// // class IncomingDocumentByIdResponse {
// //   final IncomingDocumentById? result;
// //   final dynamic errors;

// //   IncomingDocumentByIdResponse({this.result, this.errors});

// //   factory IncomingDocumentByIdResponse.fromJson(Map<String, dynamic> json) =>
// //       _$IncomingDocumentByIdResponseFromJson(json);
// //   Map<String, dynamic> toJson() => _$IncomingDocumentByIdResponseToJson(this);
// // }

// @JsonSerializable()
// class IncomingDocumentById {
//   final int id;
//   final String date;
//   final String modelType;
//   final int modelId;
//   final int counterpartyAgreementId;
//   final int organizationId;
//   final Storage storage;
//   final String? comment;
//   final Currency currency;
//   final List<DocumentGood> documentGoods;
//   final Model model;
//   final String createdAt;
//   final String updatedAt;
//   final String docNumber;
//   final int approved;

//   IncomingDocumentById({
//     required this.id,
//     required this.date,
//     required this.modelType,
//     required this.modelId,
//     required this.counterpartyAgreementId,
//     required this.organizationId,
//     required this.storage,
//     this.comment,
//     required this.currency,
//     required this.documentGoods,
//     required this.model,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.docNumber,
//     required this.approved,
//   });

//   factory IncomingDocumentById.fromJson(Map<String, dynamic> json) =>
//       _$IncomingDocumentByIdFromJson(json);
//   Map<String, dynamic> toJson() => _$IncomingDocumentByIdToJson(this);

//   // Подытог по товарам (для карточки)
//   double get totalSum {
//     if (documentGoods.isEmpty) return 0.0;
//     return documentGoods.fold(
//         0.0, (sum, good) => sum + (good.quantity * (double.tryParse(good.price) ?? 0)));
//   }

//   int get totalQuantity {
//     if (documentGoods.isEmpty) return 0;
//     return documentGoods.fold(0, (sum, good) => sum + good.quantity);
//   }

//   String get statusText {
//     return approved == 1 ? 'Проведен' : 'Не проведен';
//   }

//   Color get statusColor {
//     return approved == 1 ? Colors.green : Colors.orange;
//   }
// }

// @JsonSerializable()
// class Storage {
//   final int id;
//   final String name;
//   final String createdAt;
//   final String updatedAt;

//   Storage({
//     required this.id,
//     required this.name,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   factory Storage.fromJson(Map<String, dynamic> json) => _$StorageFromJson(json);
//   Map<String, dynamic> toJson() => _$StorageToJson(this);
// }

// @JsonSerializable()
// class Currency {
//   final int id;
//   final String name;
//   final int digitalCode;
//   final String symbolCode;
//   final int organizationId;
//   final String? createdAt;
//   final String? updatedAt;

//   Currency({
//     required this.id,
//     required this.name,
//     required this.digitalCode,
//     required this.symbolCode,
//     required this.organizationId,
//     this.createdAt,
//     this.updatedAt,
//   });

//   factory Currency.fromJson(Map<String, dynamic> json) => _$CurrencyFromJson(json);
//   Map<String, dynamic> toJson() => _$CurrencyToJson(this);
// }

// @JsonSerializable()
// class DocumentGood {
//   final int id;
//   final int documentId;
//   final int variantId;
//   final Good good;
//   final int quantity;
//   final String price;
//   final String createdAt;
//   final String updatedAt;
//   final List<Attribute> attributes;

//   DocumentGood({
//     required this.id,
//     required this.documentId,
//     required this.variantId,
//     required this.good,
//     required this.quantity,
//     required this.price,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.attributes,
//   });

//   factory DocumentGood.fromJson(Map<String, dynamic> json) => _$DocumentGoodFromJson(json);
//   Map<String, dynamic> toJson() => _$DocumentGoodToJson(this);
// }

// @JsonSerializable()
// class Good {
//   final int id;
//   final String? oneCId;
//   final String name;
//   final int categoryId;
//   final String? description;
//   final String price;
//   final int? unitId;
//   final int quantity;
//   final String? deletedAt;
//   final String createdAt;
//   final String updatedAt;
//   final bool isActive;
//   final String? article;
//   final int? labelId;
//   final bool getImage;
//   final String? cip;
//   final String? packageCode;

//   Good({
//     required this.id,
//     this.oneCId,
//     required this.name,
//     required this.categoryId,
//     this.description,
//     required this.price,
//     this.unitId,
//     required this.quantity,
//     this.deletedAt,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.isActive,
//     this.article,
//     this.labelId,
//     required this.getImage,
//     this.cip,
//     this.packageCode,
//   });

//   factory Good.fromJson(Map<String, dynamic> json) => _$GoodFromJson(json);
//   Map<String, dynamic> toJson() => _$GoodToJson(this);
// }

// @JsonSerializable()
// class Attribute {
//   final int id;
//   final int categoryAttributeId;
//   final String value;
//   final int? unitId;
//   final String createdAt;
//   final String updatedAt;
//   final int variantAttributeId;
//   final int variantId;
//   final CategoryAttribute categoryAttribute;

//   Attribute({
//     required this.id,
//     required this.categoryAttributeId,
//     required this.value,
//     this.unitId,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.variantAttributeId,
//     required this.variantId,
//     required this.categoryAttribute,
//   });

//   factory Attribute.fromJson(Map<String, dynamic> json) => _$AttributeFromJson(json);
//   Map<String, dynamic> toJson() => _$AttributeToJson(this);
// }

// @JsonSerializable()
// class CategoryAttribute {
//   final int id;
//   final int categoryId;
//   final int attributeId;
//   final String createdAt;
//   final String updatedAt;
//   final bool isIndividual;
//   final bool showToSite;
//   final AttributeDetail attribute;

//   CategoryAttribute({
//     required this.id,
//     required this.categoryId,
//     required this.attributeId,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.isIndividual,
//     required this.showToSite,
//     required this.attribute,
//   });

//   factory CategoryAttribute.fromJson(Map<String, dynamic> json) => _$CategoryAttributeFromJson(json);
//   Map<String, dynamic> toJson() => _$CategoryAttributeToJson(this);
// }

// @JsonSerializable()
// class AttributeDetail {
//   final int id;
//   final String name;
//   final String createdAt;
//   final String updatedAt;

//   AttributeDetail({
//     required this.id,
//     required this.name,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   factory AttributeDetail.fromJson(Map<String, dynamic> json) => _$AttributeDetailFromJson(json);
//   Map<String, dynamic> toJson() => _$AttributeDetailToJson(this);
// }

// @JsonSerializable()
// class Model {
//   final int id;
//   final String name;
//   final String phone;
//   final int inn;
//   final String? note;
//   final String createdAt;
//   final String updatedAt;

//   Model({
//     required this.id,
//     required this.name,
//     required this.phone,
//     required this.inn,
//     this.note,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);
//   Map<String, dynamic> toJson() => _$ModelToJson(this);
// }