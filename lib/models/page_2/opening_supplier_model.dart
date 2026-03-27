
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

class Supplier {
  final int? id;
  final String? name;
  final String? phone;
  final int? inn;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Supplier({
    this.id,
    this.name,
    this.phone,
    this.inn,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as int?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      inn: json['inn'] as int?,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
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
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Supplier copyWith({
    int? id,
    String? name,
    String? phone,
    int? inn,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      inn: inn ?? this.inn,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Supplier(id: $id, name: $name, phone: $phone, inn: $inn, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Supplier &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.inn == inn &&
        other.note == note &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    phone.hashCode ^
    inn.hashCode ^
    note.hashCode ^
    createdAt.hashCode ^
    updatedAt.hashCode;
  }
}

// Helper to parse list of suppliers
class SupplierList {
  final List<Supplier> suppliers;

  SupplierList({required this.suppliers});

  factory SupplierList.fromJson(List<dynamic> json) {
    return SupplierList(
      suppliers: json.map((item) => Supplier.fromJson(item)).toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return suppliers.map((supplier) => supplier.toJson()).toList();
  }
}



