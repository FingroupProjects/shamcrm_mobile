import 'dart:convert';

import 'package:crm_task_manager/utils/safe_converters.dart';

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
    id: SafeConverters.toInt(json["id"]),
    name: SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени'),
    currencyId: SafeConverters.toIntOrNull(json['currency_id']),
    currency: SafeConverters.toMapOrNull(json['currency']) != null
        ? CashRegisterCurrency.fromJson(SafeConverters.toMap(json['currency']))
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      symbolCode: SafeConverters.toStringOrNull(json['symbol_code']),
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
    final rawResult = json['result'];
    final rawItems = rawResult is List
        ? rawResult
        : SafeConverters.toList(SafeConverters.toMapOrNull(rawResult)?['data']);
    final items = rawItems
        .map(SafeConverters.toMapOrNull)
        .whereType<Map<String, dynamic>>()
        .map(CashRegisterData.fromJson)
        .toList();
    return CashRegistersDataResponse(
      result: items,
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
