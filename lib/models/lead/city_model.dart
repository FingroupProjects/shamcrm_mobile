import 'dart:convert';

class CityData {
  final int id;
  final String name;
  final int? parentId;
  final int? organizationId;
  final int? leadsCount;

  CityData({
    required this.id,
    required this.name,
    this.parentId,
    this.organizationId,
    this.leadsCount,
  });

  factory CityData.fromJson(Map<String, dynamic> json) => CityData(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? '',
        parentId: int.tryParse(json['parent_id']?.toString() ?? ''),
        organizationId: int.tryParse(json['organization_id']?.toString() ?? ''),
        leadsCount: int.tryParse(json['leads_count']?.toString() ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parent_id': parentId,
        'organization_id': organizationId,
        'leads_count': leadsCount,
      };

  @override
  String toString() => 'CityData{id: $id, name: $name}';
}

class CitiesDataResponse {
  final List<CityData>? result;
  final dynamic errors;

  CitiesDataResponse({
    this.result,
    this.errors,
  });

  factory CitiesDataResponse.fromJson(Map<String, dynamic> json) {
    return CitiesDataResponse(
      result: json['result'] != null
          ? List<CityData>.from(
              (json['result'] as List).map((x) => CityData.fromJson(x)),
            )
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

CitiesDataResponse citiesDataResponseFromJson(String str) =>
    CitiesDataResponse.fromJson(json.decode(str));
