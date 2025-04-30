class Branch {
  final int id;
  final String name;
  final String address;
  final double? latitude; // Made nullable
  final double? longitude; // Made nullable

  Branch({
    required this.id,
    required this.name,
    required this.address,
    this.latitude, // Nullable
    this.longitude, // Nullable
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    // Handle location_coordinates if it’s meant to provide latitude/longitude
    double? latitude;
    double? longitude;

    // If the backend provides location_coordinates as a pair [lat, lng]
    if (json['location_coordinates'] != null &&
        json['location_coordinates'] is List<dynamic> &&
        json['location_coordinates'].length == 2) {
      latitude = double.tryParse(json['location_coordinates'][0].toString());
      longitude = double.tryParse(json['location_coordinates'][1].toString());
    } else {
      // Fallback to latitude/longitude fields if provided
      latitude = json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null;
      longitude = json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null;
    }

    return Branch(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Branch &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}