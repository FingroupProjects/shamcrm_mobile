// lib/models/branch.dart
import 'package:equatable/equatable.dart';

class Branch extends Equatable {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, name, address, latitude, longitude];

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Branch &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          address == other.address &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ address.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}