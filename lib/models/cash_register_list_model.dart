import 'dart:convert';

class CashRegisterData {
  final int id;
  final String name;
  final int? currencyId;
  final CashRegisterCurrency? currency;

  CashRegisterData({
    required this.id,
    required this.name,
    this.currencyId,
    this.currency,
  });

  factory CashRegisterData.fromJson(Map<String, dynamic> json) => CashRegisterData(
    id: json["id"],
    name: json['name'] is String ? json['name'] : 'Без имени',
    currencyId: json['currency_id'] is int
        ? json['currency_id'] as int
        : int.tryParse('${json['currency_id']}'),
    currency: json['currency'] is Map<String, dynamic>
        ? CashRegisterCurrency.fromJson(json['currency'] as Map<String, dynamic>)
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
    return 'CashRegisterData{id: $id, name: $name}';
  }
}

class CashRegisterCurrency {
  final int? id;
  final String? name;
  final String? symbolCode;

  CashRegisterCurrency({
    this.id,
    this.name,
    this.symbolCode,
  });

  factory CashRegisterCurrency.fromJson(Map<String, dynamic> json) {
    return CashRegisterCurrency(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      name: json['name']?.toString(),
      symbolCode: json['symbol_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'symbol_code': symbolCode,
      };
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
