class Branch {
  final int id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final int isActive; // Новое поле

  Branch({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    required this.isActive, // Поле обязательно
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    double? latitude;
    double? longitude;

    if (json['location_coordinates'] != null &&
        json['location_coordinates'] is Map<String, dynamic>) {
      latitude = double.tryParse(json['location_coordinates']['latitude'].toString());
      longitude = double.tryParse(json['location_coordinates']['longitude'].toString());
    } else {
      latitude = json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null;
      longitude = json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null;
    }

    return Branch(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      isActive: json['is_active'] as int? ?? 0, // Значение по умолчанию 0
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