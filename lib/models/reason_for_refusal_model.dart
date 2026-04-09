import 'dart:convert';

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
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      text: '${json['text'] ?? ''}',
      type: '${json['type'] ?? ''}',
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
        ? result['data'] as List
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
    ReasonForRefusalResponse.fromJson(json.decode(str) as Map<String, dynamic>);
