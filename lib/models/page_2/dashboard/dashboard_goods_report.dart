import 'package:crm_task_manager/utils/safe_converters.dart';
import '../../../utils/global_fun.dart';

class ResultDashboardGoodsReport {
  final List<DashboardGoods> data;
  final Pagination pagination;

  ResultDashboardGoodsReport({required this.data, required this.pagination});

  factory ResultDashboardGoodsReport.fromJson(Map<String, dynamic> json) {
    return ResultDashboardGoodsReport(
      data: SafeConverters.toList(json['data'])
          .map((item) => DashboardGoods.fromJson(SafeConverters.toMap(item)))
          .toList(),
      pagination: Pagination.fromJson(SafeConverters.toMap(json['pagination'])),
    );
  }
}

class DashboardGoodsReportTotal {
  final String totalSum;

  DashboardGoodsReportTotal({required this.totalSum});

  factory DashboardGoodsReportTotal.fromJson(Map<String, dynamic> json) {
    return DashboardGoodsReportTotal(
      totalSum: parseNumberToString(json['total_sum'], nullValue: '0'),
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
      total: SafeConverters.toInt(json['total']),
      count: SafeConverters.toInt(json['count']),
      per_page: SafeConverters.toInt(json['per_page']),
      current_page: SafeConverters.toInt(json['current_page']),
      total_pages: SafeConverters.toInt(json['total_pages']),
    );
  }
}

class DashboardGoods {
  final int id;
  final int? goodVariantId; // New field
  final String name;
  final String category;
  final String totalQuantity; // Renamed from quantity
  final String price;
  final String totalSum;
  final List<Storage> storages; // New field for storages array

  DashboardGoods({
    required this.id,
    this.goodVariantId,
    required this.name,
    required this.category,
    required this.totalQuantity,
    required this.price,
    required this.totalSum,
    required this.storages,
  });

  factory DashboardGoods.fromJson(Map<String, dynamic> json) {
    return DashboardGoods(
      id: SafeConverters.toInt(json['id']),
      goodVariantId: SafeConverters.toIntOrNull(json['good_variant_id']),
      name: SafeConverters.toSafeString(json['name']),
      category: SafeConverters.toSafeString(json['category']),
      totalQuantity: SafeConverters.toSafeString(json['total_quantity'], defaultValue: '0'),
      price: parseNumberToString(json['price'], nullValue: '0'),
      totalSum: parseNumberToString(json['total_sum'], nullValue: '0'),
      storages: SafeConverters.toList(json['storages'])
          .map((item) => Storage.fromJson(SafeConverters.toMap(item)))
          .toList(),
    );
  }
}

class Storage {
  final int id;
  final String name;
  final String quantity;
  final String price;
  final String sum;

  Storage({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.sum,
  });

  factory Storage.fromJson(Map<String, dynamic> json) {
    return Storage(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      quantity: parseNumberToString(json['quantity'], nullValue: '0'),
      price: parseNumberToString(json['price'], nullValue: '0'),
      sum: parseNumberToString(json['sum'], nullValue: '0'),
    );
  }
}
