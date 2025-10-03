class ResultDashboardGoodsReport {
  final List<DashboardGoods> data;
  final Pagination pagination;

  ResultDashboardGoodsReport({required this.data, required this.pagination});

  factory ResultDashboardGoodsReport.fromJson(Map<String, dynamic> json) {
    return ResultDashboardGoodsReport(
      data: (json['data'] as List?)?.map((i) => DashboardGoods.fromJson(i)).toList() ?? [],
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class Pagination {
  final int total;
  final int count;
  final int per_page;
  final int current_page;
  final int total_pages;

  Pagination({
    required this.total,
    required this.count,
    required this.per_page,
    required this.current_page,
    required this.total_pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int,
      count: json['count'] as int,
      per_page: json['per_page'] as int,
      current_page: json['current_page'] as int,
      total_pages: json['total_pages'] as int,
    );
  }
}

class DashboardGoods {
  final int id;
  final int? goodVariantId; // New field
  final String name;
  final String category;
  final String totalQuantity; // Renamed from quantity
  final List<Storage> storages; // New field for storages array
  final String daysWithoutMovement;
  final String sum;

  DashboardGoods({
    required this.id,
    this.goodVariantId,
    required this.name,
    required this.category,
    required this.totalQuantity,
    required this.storages,
    required this.daysWithoutMovement,
    required this.sum,
  });

  factory DashboardGoods.fromJson(Map<String, dynamic> json) {
    return DashboardGoods(
      id: json['id'] as int,
      goodVariantId: json['good_variant_id'] as int?,
      name: json['name'] as String,
      category: json['category'] as String,
      totalQuantity: json['total_quantity'] as String,
      storages: (json['storages'] as List?)?.map((i) => Storage.fromJson(i)).toList() ?? [],
      daysWithoutMovement: json['days_without_movement'] as String,
      sum: json['sum'] as String,
    );
  }
}

class Storage {
  final int id;
  final String name;
  final String quantity;

  Storage({
    required this.id,
    required this.name,
    required this.quantity,
  });

  factory Storage.fromJson(Map<String, dynamic> json) {
    return Storage(
      id: json['id'] as int,
      name: json['name'] as String,
      quantity: json['quantity'] as String,
    );
  }
}