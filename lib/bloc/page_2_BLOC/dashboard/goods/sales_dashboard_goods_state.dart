part of 'sales_dashboard_goods_bloc.dart';

sealed class SalesDashboardGoodsState extends Equatable {
  const SalesDashboardGoodsState();
}

final class SalesDashboardProductsInitial extends SalesDashboardGoodsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardGoodsLoading extends SalesDashboardGoodsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardGoodsLoaded extends SalesDashboardGoodsState {
  final List<DashboardGoods> goods;
  final Pagination pagination;

  const SalesDashboardGoodsLoaded({
    required this.goods,
    required this.pagination,
  });

  @override
  List<Object> get props => [goods, pagination];
}

final class SalesDashboardGoodsError extends SalesDashboardGoodsState {
  final String message;

  const SalesDashboardGoodsError({required this.message});

  @override
  List<Object> get props => [message];
}
