part of 'sales_dashboard_top_selling_goods_bloc.dart';

sealed class SalesDashboardTopSellingGoodsEvent extends Equatable {
  const SalesDashboardTopSellingGoodsEvent();
}

class LoadTopSellingGoodsReport extends SalesDashboardTopSellingGoodsEvent {

  final Map<String, dynamic>? filter;
  final String? search;

  const LoadTopSellingGoodsReport({this. filter, this.search});

  @override
  List<Object> get props => [filter ?? {}, search ?? ''];
}
