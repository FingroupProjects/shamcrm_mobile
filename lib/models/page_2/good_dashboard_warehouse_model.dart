import 'package:crm_task_manager/utils/safe_converters.dart';

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
    return GoodDashboardWarehouse(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
    );
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
      total: SafeConverters.toInt(json['total']),
      count: SafeConverters.toInt(json['count']),
      perPage: SafeConverters.toInt(json['per_page']),
      currentPage: SafeConverters.toInt(json['current_page']),
      totalPages: SafeConverters.toInt(json['total_pages']),
    );
  }
}
