part of 'sales_dashboard_top_selling_goods_bloc.dart';

sealed class SalesDashboardTopSellingGoodsState extends Equatable {
  const SalesDashboardTopSellingGoodsState();
}

final class SalesDashboardTopSellingProductsInitial extends SalesDashboardTopSellingGoodsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardTopSellingGoodsLoading extends SalesDashboardTopSellingGoodsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardTopSellingGoodsLoaded extends SalesDashboardTopSellingGoodsState {
  final List<TopSellingCardModel> topSellingGoods;

  const SalesDashboardTopSellingGoodsLoaded({
    required this.topSellingGoods,
  });

  @override
  List<Object> get props => [topSellingGoods];
}

final class SalesDashboardTopSellingGoodsError extends SalesDashboardTopSellingGoodsState {
  final String message;

  const SalesDashboardTopSellingGoodsError({required this.message});

  @override
  List<Object> get props => [message];
}
