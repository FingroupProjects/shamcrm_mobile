part of 'sales_dashboard_manufacture_goods_bloc.dart';

sealed class SalesDashboardManufactureGoodsEvent extends Equatable {
  const SalesDashboardManufactureGoodsEvent();
}

class LoadManufactureGoodsReport extends SalesDashboardManufactureGoodsEvent {
  final int page;
  final int perPage;
  final Map<String, dynamic>? filter;
  final String? search;

  const LoadManufactureGoodsReport({
    this.page = 1,
    this.perPage = 20,
    this.filter,
    this.search,
  });

  @override
  List<Object?> get props => [page, perPage, filter, search];
}
