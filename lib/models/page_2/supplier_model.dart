class Supplier {
  final int id;
  final String name;
  final String? phone; // Changed to nullable
  final int? inn; // Changed to nullable
  final String? note;
  final String createdAt;
  final String updatedAt;

  Supplier({
    required this.id,
    required this.name,
    this.phone, // No longer required
    this.inn, // No longer required
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
      phone: json['phone'], // This will now handle null values
      inn: json['inn'], // This will now handle null values
      note: json['note'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
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

/// Модель ответа API для списка поставщиков (используется в диалоге выбора)
class SuppliersForOpeningsResponse {
  final List<Supplier>? result;
  final dynamic errors;

  SuppliersForOpeningsResponse({
    this.result,
    this.errors,
  });

  factory SuppliersForOpeningsResponse.fromJson(Map<String, dynamic> json) {
    return SuppliersForOpeningsResponse(
      result: json['result'] != null
          ? (json['result'] as List).map((item) => Supplier.fromJson(item)).toList()
          : null,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result?.map((item) => item.toJson()).toList(),
      'errors': errors,
    };
  }
}