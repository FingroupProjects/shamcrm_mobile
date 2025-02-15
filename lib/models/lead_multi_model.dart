import 'dart:convert';

class LeadData{
  final int id;
  final String name;
  final String? lastname;

  LeadData({
    required this.id,
    required this.name,
    this.lastname
  });



  factory LeadData.fromJson(Map<String, dynamic> json) => LeadData(
    id: json["id"],
    name: json["name"],
    lastname: json["lastname"]??""
  
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "lastname":lastname
   
  };

  @override
  String toString() {
    return 'UserData{id: $id, name: $name, lastname:$lastname}';
  }
}


LeadsMultiDataResponse leadsDataResponseFromJson(String str) => LeadsMultiDataResponse.fromJson(json.decode(str));

String leadsDataResponseToJson(LeadsMultiDataResponse data) => json.encode(data.toJson());

class LeadsMultiDataResponse {
  List<LeadData>? result;
  dynamic errors;

  LeadsMultiDataResponse({
    this.result,
    this.errors,
  });

  factory LeadsMultiDataResponse.fromJson(Map<String, dynamic> json) {
    // Печать данных для отладки
    return LeadsMultiDataResponse(
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

