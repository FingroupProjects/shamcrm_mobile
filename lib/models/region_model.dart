class Region {
  final int id;
  final String name;

  Region({required this.id, required this.name});

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'],
      name: json['name'],
    );
  }
}

class RegionResponse {
  final List<Region> regions;
  final String? error;

  RegionResponse({required this.regions, this.error});

  factory RegionResponse.fromJson(Map<String, dynamic> json) {
    var regionsJson = json['result'] as List;
    List<Region> regionsList = regionsJson.map((region) => Region.fromJson(region)).toList();

    return RegionResponse(
      regions: regionsList,
      error: json['errors'],
    );
  }
}
