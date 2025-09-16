import 'dart:convert';

class SupplierData {
  final int id;
  final String name;

  SupplierData({
    required this.id,
    required this.name,
  });

  factory SupplierData.fromJson(Map<String, dynamic> json) => SupplierData(
    id: json["id"],
    name: json['name'] is String ? json['name'] : 'Без имени',
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
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