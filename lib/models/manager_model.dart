import 'dart:convert';

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
    id: json["id"] ?? 0,
    name: json["name"]?.toString() ?? '', // Безопасное преобразование
    lastname: json["lastname"]?.toString(), // Безопасное nullable преобразование
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
      return ManagersDataResponse(
        result: json["result"] != null && json["result"]["data"] != null
            ? List<ManagerData>.from(
                (json["result"]["data"] as List).map((x) => ManagerData.fromJson(x))
              )
            : <ManagerData>[], // Пустой список вместо null
        errors: json["errors"],
      );
    } catch (e) {
      print('ManagersDataResponse.fromJson error: $e');
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