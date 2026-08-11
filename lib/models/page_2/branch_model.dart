import 'package:crm_task_manager/utils/safe_converters.dart';

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

    final locationCoordinates = SafeConverters.toMapOrNull(json['location_coordinates']);
    if (locationCoordinates != null) {
      latitude = SafeConverters.toDoubleOrNull(locationCoordinates['latitude']);
      longitude = SafeConverters.toDoubleOrNull(locationCoordinates['longitude']);
    } else {
      latitude = SafeConverters.toDoubleOrNull(json['latitude']);
      longitude = SafeConverters.toDoubleOrNull(json['longitude']);
    }

    return Branch(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      address: SafeConverters.toSafeString(json['address']),
      latitude: latitude,
      longitude: longitude,
      isActive: SafeConverters.toInt(json['is_active']),
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
