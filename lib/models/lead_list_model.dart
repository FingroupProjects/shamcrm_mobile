import 'dart:convert';

class LeadData {
  final int id;
  final String name;
  final int? managerId; // Добавляем ID менеджера

  LeadData({
    required this.id,
    required this.name,
    this.managerId,
  });

  factory LeadData.fromJson(Map<String, dynamic> json) => LeadData(
        id: json["id"],
        name: json['name'] is String ? json['name'] : 'Без имени',
        managerId: json['manager'] != null ? json['manager']['id'] : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "managerId": managerId,
      };

  @override
  String toString() {
    return 'LeadData{id: $id, name: $name, managerId: $managerId}';
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

