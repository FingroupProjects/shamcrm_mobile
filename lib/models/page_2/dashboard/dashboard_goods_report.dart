
// Data classes for JSON deserialization
class ResultDashboardGoodsReport {
  final List<DashboardGoods> data;
  final Pagination pagination;

  ResultDashboardGoodsReport({required this.data, required this.pagination});

  factory ResultDashboardGoodsReport.fromJson(Map<String, dynamic> json) {
    return ResultDashboardGoodsReport(
      data: (json['data'] as List).map((i) => DashboardGoods.fromJson(i)).toList(),
      pagination: Pagination.fromJson(json['pagination']),
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
      total: json['total'],
      count: json['count'],
      per_page: json['per_page'],
      current_page: json['current_page'],
      total_pages: json['total_pages'],
    );
  }
}

class DashboardGoods {
  final int id;
  final String article;
  final String name;
  final String category;
  final String quantity;
  final String daysWithoutMovement;
  final String sum;

  DashboardGoods({
    required this.id,
    required this.article,
    required this.name,
    required this.category,
    required this.quantity,
    required this.daysWithoutMovement,
    required this.sum,
  });

  factory DashboardGoods.fromJson(Map<String, dynamic> json) {
    return DashboardGoods(
      id: json['id'],
      article: json['article'],
      name: json['name'],
      category: json['category'],
      quantity: json['quantity'],
      daysWithoutMovement: json['days_without_movement'],
      sum: json['sum'],
    );
  }
}
