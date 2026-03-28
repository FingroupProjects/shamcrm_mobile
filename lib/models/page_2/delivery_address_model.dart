import 'dart:convert';

class DeliveryAddress {
  final int id;
  final String address;
  final int leadId;
  final int isActive;
  final String createdAt;
  final String updatedAt;

  DeliveryAddress({
    required this.id,
    required this.address,
    required this.leadId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'] ?? 0,
      address: json['address'] ?? '',
      leadId: json['lead_id'] ?? 0,
      isActive: json['is_active'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'lead_id': leadId,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class DeliveryAddressResponse {
  final List<DeliveryAddress>? result;
  final dynamic errors;

  DeliveryAddressResponse({this.result, this.errors});

  factory DeliveryAddressResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressResponse(
      result: json['result'] != null
          ? List<DeliveryAddress>.from(
              json['result'].map((x) => DeliveryAddress.fromJson(x)))
          : [],
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result?.map((x) => x.toJson()).toList(),
      'errors': errors,
    };
  }
}