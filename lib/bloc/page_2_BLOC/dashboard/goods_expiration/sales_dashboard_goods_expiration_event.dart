part of 'sales_dashboard_goods_expiration_bloc.dart';

sealed class SalesDashboardGoodsExpirationEvent extends Equatable {
  const SalesDashboardGoodsExpirationEvent();
}

class LoadGoodsExpirationReport extends SalesDashboardGoodsExpirationEvent {
  final int page;
  final int perPage;
  final String? search;
  final Map<String, dynamic>? filter;

  const LoadGoodsExpirationReport({
    this.page = 1,
    this.perPage = 20,
    this.search,
    this.filter,
  });

  @override
  List<Object> get props => [page, perPage, search ?? '', filter ?? {}];
}
