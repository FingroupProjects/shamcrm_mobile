import 'dart:convert';

class PriceTypeModel {
  int id;
  String name;
  int organizationId;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic oneCId;

  PriceTypeModel({
    required this.id,
    required this.name,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
    required this.oneCId,
  });

  factory PriceTypeModel.fromRawJson(String str) => PriceTypeModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory PriceTypeModel.fromJson(Map<String, dynamic> json) => PriceTypeModel(
        id: json["id"],
        name: json["name"],
        organizationId: json["organization_id"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        oneCId: json["one_c_id"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "organization_id": organizationId,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "one_c_id": oneCId,
      };
}
