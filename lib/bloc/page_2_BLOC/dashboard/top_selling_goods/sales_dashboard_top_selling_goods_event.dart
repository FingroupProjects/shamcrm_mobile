part of 'sales_dashboard_top_selling_goods_bloc.dart';

sealed class SalesDashboardTopSellingGoodsEvent extends Equatable {
  const SalesDashboardTopSellingGoodsEvent();
}

class LoadTopSellingGoodsReport extends SalesDashboardTopSellingGoodsEvent {

  const LoadTopSellingGoodsReport();

  @override
  List<Object> get props => [];
}
