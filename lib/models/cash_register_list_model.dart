import 'dart:convert';

class CashRegisterData {
  final int id;
  final String name;

  CashRegisterData({
    required this.id,
    required this.name,
  });

  factory CashRegisterData.fromJson(Map<String, dynamic> json) => CashRegisterData(
    id: json["id"],
    name: json['name'] is String ? json['name'] : 'Без имени',
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
  };

  @override
  String toString() {
    return 'CashRegisterData{id: $id, name: $name}';
  }
}

CashRegistersDataResponse cashRegistersDataResponseFromJson(String str) =>
    CashRegistersDataResponse.fromJson(json.decode(str));

String cashRegistersDataResponseToJson(CashRegistersDataResponse data) =>
    json.encode(data.toJson());

class CashRegistersDataResponse {
  List<CashRegisterData>? result;
  dynamic errors;

  CashRegistersDataResponse({
    this.result,
    this.errors,
  });

  factory CashRegistersDataResponse.fromJson(Map<String, dynamic> json) {
    return CashRegistersDataResponse(
      result: json["result"] != null && json["result"]["data"] != null
          ? List<CashRegisterData>.from(
          (json["result"]["data"] as List).map((x) => CashRegisterData.fromJson(x)))
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
