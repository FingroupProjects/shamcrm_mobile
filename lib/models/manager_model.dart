import 'dart:convert';

class ManagerData{
  final int id;
  final String name;

  ManagerData({
    required this.id,
    required this.name,
  });



  factory ManagerData.fromJson(Map<String, dynamic> json) => ManagerData(
    id: json["id"],
    name: json["name"],
  
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
   
  };

  @override
  String toString() {
    return 'UserData{id: $id, name: $name}';
  }
}


ManagersDataResponse managersDataResponseFromJson(String str) => ManagersDataResponse.fromJson(json.decode(str));

String managersDataResponseToJson(ManagersDataResponse data) => json.encode(data.toJson());

class ManagersDataResponse {
  List<ManagerData>? result;
  dynamic errors;

  ManagersDataResponse({
    this.result,
    this.errors,
  });

  factory ManagersDataResponse.fromJson(Map<String, dynamic> json) {
    // Печать данных для отладки
    print('JSON data: $json');

    return ManagersDataResponse(
      result: json["result"] != null && json["result"]["data"] != null
          ? List<ManagerData>.from(
              (json["result"]["data"] as List).map((x) => ManagerData.fromJson(x))
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

