class Supplier {
  final int id;
  final String name;
  final String? phone; // Changed to nullable
  final int? inn; // Changed to nullable
  final String? note;
  final String createdAt;
  final String updatedAt;
  final int? currencyId;
  final SupplierCurrency? currency;

  Supplier({
    required this.id,
    required this.name,
    this.phone, // No longer required
    this.inn, // No longer required
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.currencyId,
    this.currency,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      // This will now handle null values
      inn: json['inn'],
      // This will now handle null values
      note: json['note'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      currencyId: json['currency_id'],
      currency: json['currency'] != null
          ? SupplierCurrency.fromJson(json['currency'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'inn': inn,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'currency_id': currencyId,
      'currency': currency?.toJson(),
    };
  }

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Supplier && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class SupplierCurrency {
  final int? id;
  final String? name;
  final int? digitalCode;
  final String? symbolCode;
  final int? organizationId;
  final String? createdAt;
  final String? updatedAt;

  SupplierCurrency({
    this.id,
    this.name,
    this.digitalCode,
    this.symbolCode,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory SupplierCurrency.fromJson(Map<String, dynamic> json) {
    return SupplierCurrency(
      id: json['id'],
      name: json['name']?.toString(),
      digitalCode: json['digital_code'],
      symbolCode: json['symbol_code']?.toString(),
      organizationId: json['organization_id'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'digital_code': digitalCode,
      'symbol_code': symbolCode,
      'organization_id': organizationId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
