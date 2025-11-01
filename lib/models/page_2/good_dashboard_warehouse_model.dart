// Response model to hold both data and pagination
class GoodDashboardWarehouseResponse {
  final List<GoodDashboardWarehouse> data;
  final Pagination? pagination;

  GoodDashboardWarehouseResponse({
    required this.data,
    this.pagination,
  });
}

class GoodDashboardWarehouse {
  final int id;
  final String name;

  GoodDashboardWarehouse({
    required this.id,
    required this.name,
  });

  factory GoodDashboardWarehouse.fromJson(Map<String, dynamic> json) {
    try {
      return GoodDashboardWarehouse(
        id: json['id'] as int,
        name: json['name'] as String,
      );
    } catch (e) {
      print('Error parsing GoodDashboardWarehouse: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class Pagination {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  Pagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int,
      count: json['count'] as int,
      perPage: json['per_page'] as int,
      currentPage: json['current_page'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}