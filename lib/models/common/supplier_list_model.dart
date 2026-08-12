import 'dart:convert';

class SupplierData {
  final int id;
  final String name;
  final int? currencyId;
  final SupplierListCurrency? currency;

  SupplierData({
    required this.id,
    required this.name,
    this.currencyId,
    this.currency,
  });

  factory SupplierData.fromJson(Map<String, dynamic> json) => SupplierData(
    id: json["id"],
    name: json['name'] is String ? json['name'] : 'Без имени',
    currencyId: json['currency_id'],
    currency: json['currency'] != null
        ? SupplierListCurrency.fromJson(json['currency'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "currency_id": currencyId,
    "currency": currency?.toJson(),
  };

  @override
  String toString() {
    return 'SupplierData{id: $id, name: $name}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupplierData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class SupplierListCurrency {
  final int? id;
  final String? name;
  final int? digitalCode;
  final String? symbolCode;
  final int? organizationId;
  final String? createdAt;
  final String? updatedAt;

  SupplierListCurrency({
    this.id,
    this.name,
    this.digitalCode,
    this.symbolCode,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory SupplierListCurrency.fromJson(Map<String, dynamic> json) {
    return SupplierListCurrency(
      id: json['id'],
      name: json['name']?.toString(),
      digitalCode: json['digital_code'],
      symbolCode: json['symbol_code']?.toString(),
      organizationId: json['organization_id'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'digital_code': digitalCode,
      'symbol_code': symbolCode,
      'organization_id': organizationId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

SuppliersDataResponse suppliersDataResponseFromJson(String str) =>
    SuppliersDataResponse.fromJson(json.decode(str));

String suppliersDataResponseToJson(SuppliersDataResponse data) =>
    json.encode(data.toJson());

class SuppliersDataResponse {
  List<SupplierData>? result;
  dynamic errors;

  SuppliersDataResponse({
    this.result,
    this.errors,
  });

  factory SuppliersDataResponse.fromJson(Map<String, dynamic> json) {
    return SuppliersDataResponse(
      result: json["result"] != null && json["result"]["data"] != null
          ? List<SupplierData>.from(
          (json["result"]["data"] as List).map((x) => SupplierData.fromJson(x)))
          : [],
      errors: json["errors"],
    );
  }

  Map<String, dynamic> toJson() => {
    "result": result == null
        ? []
        : List<dynamic>.from(result!.map((x) => x.toJson())),
    "errors": errors,
  };
}
