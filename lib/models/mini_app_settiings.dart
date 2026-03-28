// models/mini_app_settings_model.dart
import 'dart:convert';

class MiniAppSettings {
  final int id;
  final bool active;
  final bool branch;
  final bool delivery;
  final String deliverySum;
  final String name;
  final String startDate;
  final String endDate;
  final String? startTime;
  final String? endTime;
  final String logo;
  final int currencyId;
  final int organizationId;
  final String? createdAt;
  final String updatedAt;
  final String phone;
  final bool hasBonus;
  final bool identifyByPhone;
  final int countryId;
  final String? country;

  MiniAppSettings({
    required this.id,
    required this.active,
    required this.branch,
    required this.delivery,
    required this.deliverySum,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    required this.logo,
    required this.currencyId,
    required this.organizationId,
    this.createdAt,
    required this.updatedAt,
    required this.phone,
    required this.hasBonus,
    required this.identifyByPhone,
    required this.countryId,
    this.country,
  });

  factory MiniAppSettings.fromJson(Map<String, dynamic> json) {
    return MiniAppSettings(
      id: json['id'] ?? 0,
      active: json['active'] ?? false,
      branch: json['branch'] ?? false,
      delivery: json['delivery'] ?? false,
      deliverySum: json['delivery_sum'] ?? '0.00',
      name: json['name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      logo: json['logo'] ?? '0',
      currencyId: json['currency_id'] ?? 0,
      organizationId: json['organization_id'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'] ?? '',
      phone: json['phone'] ?? '',
      hasBonus: json['has_bonus'] ?? false,
      identifyByPhone: json['identify_by_phone'] ?? false,
      countryId: json['country_id'] ?? 0,
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'active': active,
      'branch': branch,
      'delivery': delivery,
      'delivery_sum': deliverySum,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'start_time': startTime,
      'end_time': endTime,
      'logo': logo,
      'currency_id': currencyId,
      'organization_id': organizationId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'phone': phone,
      'has_bonus': hasBonus,
      'identify_by_phone': identifyByPhone,
      'country_id': countryId,
      'country': country,
    };
  }
}