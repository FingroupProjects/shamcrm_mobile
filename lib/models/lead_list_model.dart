import 'dart:convert';

class LeadData {
  final int id;
  final String name;
  final int? managerId;
  final String? debt; // ← Добавляем поле долга

  LeadData({
    required this.id,
    required this.name,
    this.managerId,
    this.debt, // ← Добавляем в конструктор
  });

  factory LeadData.fromJson(Map<String, dynamic> json) => LeadData(
        id: json["id"],
        name: json['name'] is String ? json['name'] : 'Без имени',
        managerId: json['manager'] != null ? json['manager']['id'] : null,
        debt: json['debt'], // ← Парсим долг из JSON
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "managerId": managerId,
        "debt": debt, // ← Добавляем в toJson
      };

  @override
  String toString() {
    return 'LeadData{id: $id, name: $name, managerId: $managerId, debt: $debt}';
  }
}


LeadsDataResponse leadsDataResponseFromJson(String str) => LeadsDataResponse.fromJson(json.decode(str));

String leadsDataResponseToJson(LeadsDataResponse data) => json.encode(data.toJson());

class LeadsDataResponse {
  List<LeadData>? result;
  dynamic errors;

  LeadsDataResponse({
    this.result,
    this.errors,
  });

  factory LeadsDataResponse.fromJson(Map<String, dynamic> json) {
    return LeadsDataResponse(
      result: json["result"] != null && json["result"]["data"] != null
          ? List<LeadData>.from(
              (json["result"]["data"] as List).map((x) => LeadData.fromJson(x))
            )
          : [],
      errors: json["errors"],
    );
  }

  Map<String, dynamic> toJson() => {
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
    "errors": errors,
  };
}

