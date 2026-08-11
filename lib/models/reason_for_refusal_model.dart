import 'dart:convert';

import 'package:crm_task_manager/utils/safe_converters.dart';

class ReasonForRefusalData {
  final int id;
  final String text;
  final String type;

  ReasonForRefusalData({
    required this.id,
    required this.text,
    required this.type,
  });

  factory ReasonForRefusalData.fromJson(Map<String, dynamic> json) {
    return ReasonForRefusalData(
      id: SafeConverters.toInt(json['id']),
      text: SafeConverters.toSafeString(json['text']),
      type: SafeConverters.toSafeString(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
    };
  }

  @override
  String toString() => text;
}

class ReasonForRefusalResponse {
  final List<ReasonForRefusalData> data;
  final dynamic errors;

  ReasonForRefusalResponse({
    required this.data,
    this.errors,
  });

  factory ReasonForRefusalResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    final rawData = (result is Map<String, dynamic> && result['data'] is List)
        ? SafeConverters.toList(result['data'])
        : <dynamic>[];

    return ReasonForRefusalResponse(
      data: rawData
          .whereType<Map<String, dynamic>>()
          .map(ReasonForRefusalData.fromJson)
          .toList(),
      errors: json['errors'],
    );
  }
}

ReasonForRefusalResponse reasonForRefusalResponseFromJson(String str) =>
    ReasonForRefusalResponse.fromJson(
        SafeConverters.toMap(json.decode(str)));
