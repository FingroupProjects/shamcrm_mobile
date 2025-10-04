part of 'sales_dashboard_goods_bloc.dart';

sealed class SalesDashboardGoodsEvent extends Equatable {
  const SalesDashboardGoodsEvent();
}

class LoadGoodsReport extends SalesDashboardGoodsEvent {
  final int page;
  final int perPage;
  final String? search;
  final Map<String, dynamic>? filter;

  const LoadGoodsReport({
    this.page = 1,
    this.perPage = 20,
    this.search,
    this.filter,
  });

  @override
  List<Object> get props => [page, perPage, search ?? '', filter ?? {}];
}
