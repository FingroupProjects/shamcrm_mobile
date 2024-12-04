import 'dart:convert';

class RegionData{
  final int id;
  final String name;

  RegionData({
    required this.id,
    required this.name,
  });



  factory RegionData.fromJson(Map<String, dynamic> json) => RegionData(
    id: json["id"],
    name: json["name"],
  
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
   
  };

  @override
  String toString() {
    return 'RegionData{id: $id, name: $name}';
  }
}


RegionsDataResponse regionsDataResponseFromJson(String str) => RegionsDataResponse.fromJson(json.decode(str));

String regionsDataResponseToJson(RegionsDataResponse data) => json.encode(data.toJson());

class RegionsDataResponse {
  List<RegionData>? result;
  dynamic errors;

  RegionsDataResponse({
    this.result,
    this.errors,
  });

  factory RegionsDataResponse.fromJson(Map<String, dynamic> json) {
  // Print the JSON data for debugging purposes
  print('JSON data: $json');

  return RegionsDataResponse(
    result: json["result"] != null
        ? List<RegionData>.from(
            (json["result"] as List).map((x) => RegionData.fromJson(x))
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

