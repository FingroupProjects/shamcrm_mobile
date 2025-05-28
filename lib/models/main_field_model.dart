import 'dart:convert';

class MainField {
  final int id;
  final String value;

  MainField({
    required this.id,
    required this.value,
  });

  factory MainField.fromJson(Map<String, dynamic> json) => MainField(
        id: json['id'],
        value: json['value'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
      };
}

class MainFieldResponse {
  final List<MainField>? result;
  final dynamic errors;

  MainFieldResponse({
    this.result,
    this.errors,
  });

  factory MainFieldResponse.fromJson(Map<String, dynamic> json) {
    return MainFieldResponse(
      result: json['result'] != null
          ? List<MainField>.from(
              (json['result'] as List).map((x) => MainField.fromJson(x)))
          : [],
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() => {
        'result': result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toJson())),
        'errors': errors,
      };
}

MainFieldResponse mainFieldResponseFromJson(String str) =>
    MainFieldResponse.fromJson(json.decode(str));

String mainFieldResponseToJson(MainFieldResponse data) =>
    json.encode(data.toJson());