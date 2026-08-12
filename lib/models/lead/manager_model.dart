import 'dart:convert';

import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:flutter/material.dart';

class ManagerData {
  final int id;
  final String name;
  final String? lastname;

  ManagerData({
    required this.id,
    required this.name,
    this.lastname,
  });

  factory ManagerData.fromJson(Map<String, dynamic> json) => ManagerData(
    id: SafeConverters.toInt(json["id"]),
    name: SafeConverters.toSafeString(json["name"]),
    lastname: SafeConverters.toStringOrNull(json["lastname"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "lastname": lastname,
  };

  @override
  String toString() {
    return 'ManagerData{id: $id, name: $name, lastname: $lastname}';
  }
}

ManagersDataResponse managersDataResponseFromJson(String str) => 
    ManagersDataResponse.fromJson(json.decode(str));

String managersDataResponseToJson(ManagersDataResponse data) => 
    json.encode(data.toJson());

class ManagersDataResponse {
  List<ManagerData>? result;
  dynamic errors;

  ManagersDataResponse({
    this.result,
    this.errors,
  });

  factory ManagersDataResponse.fromJson(Map<String, dynamic> json) {
    try {
      final resultMap = SafeConverters.toMapOrNull(json["result"]);
      final dataList = SafeConverters.toList(resultMap?['data']);
      return ManagersDataResponse(
        result: dataList
            .map((x) => ManagerData.fromJson(SafeConverters.toMap(x)))
            .toList(),
        errors: json["errors"],
      );
    } catch (e) {
      debugPrint('ManagersDataResponse.fromJson error: $e');
      return ManagersDataResponse(
        result: <ManagerData>[],
        errors: 'Parsing error: $e',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
    "errors": errors,
  };
}