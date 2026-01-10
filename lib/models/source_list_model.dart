import 'dart:convert';

class SourceData {
  final int id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDefault;

  SourceData({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    required this.isDefault,
  });

  factory SourceData.fromJson(Map<String, dynamic> json) {
    return SourceData(
      id: json["id"],
      name: json["name"],
      createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
      updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
      isDefault: json["default"] == true,  // Ensure it's a boolean value
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "default": isDefault,
      };

  @override
  String toString() {
    return 'SourceData{id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, isDefault: $isDefault}';
  }
}

List<SourceData> sourcesDataFromJson(String str) => List<SourceData>.from(json.decode(str).map((x) => SourceData.fromJson(x)));

String sourcesDataToJson(List<SourceData> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
