import 'dart:convert';

class LeadData {
  final int id;
  final String name;  

  LeadData({
    required this.id,
    required this.name,
  });

  factory LeadData.fromJson(Map<String, dynamic> json) => LeadData(
    id: json["id"],
    name: json['name'] is String ? json['name'] : 'Без имени',
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
  };

  @override
  String toString() {
    return 'LeadData{id: $id, name: $name}';
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

