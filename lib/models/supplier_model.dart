class Supplier {
  final int id;
  final String name;
  final String phone;
  final dynamic inn;
  final String? note;
  final String createdAt;
  final String updatedAt;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.inn,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      inn: json['inn'],
      note: json['note'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
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
}

class SupplierPagination {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  SupplierPagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory SupplierPagination.fromJson(Map<String, dynamic> json) {
    return SupplierPagination(
      total: json['total'] ?? 0,
      count: json['count'] ?? 0,
      perPage: json['per_page'] ?? 0,
      currentPage: json['current_page'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'count': count,
      'per_page': perPage,
      'current_page': currentPage,
      'total_pages': totalPages,
    };
  }
}

class SupplierResponse {
  final List<Supplier> suppliers;
  final SupplierPagination pagination;

  SupplierResponse({
    required this.suppliers,
    required this.pagination,
  });

  factory SupplierResponse.fromJson(Map<String, dynamic> json) {
    return SupplierResponse(
      suppliers: (json['data'] as List<dynamic>?)
              ?.map((e) => Supplier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? SupplierPagination.fromJson(json['pagination'])
          : SupplierPagination(
              total: 0, count: 0, perPage: 0, currentPage: 0, totalPages: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': suppliers.map((e) => e.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}
