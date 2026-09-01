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
  final bool hasReachedMax;
  final String totalSum;
  final Map<String, dynamic>? filter;
  final String? search;

  const SalesDashboardGoodsLoaded({
    required this.goods,
    required this.pagination,
    required this.hasReachedMax,
    required this.totalSum,
    this.filter,
    this.search,
  });

  @override
  List<Object?> get props =>
      [goods, pagination, hasReachedMax, totalSum, filter, search];
}

final class SalesDashboardGoodsError extends SalesDashboardGoodsState {
  final String message;

  const SalesDashboardGoodsError({required this.message});

  @override
  List<Object> get props => [message];
}

final class SalesDashboardGoodsPaginationError extends SalesDashboardGoodsState {
  final String message;
  final List<DashboardGoods> goods;
  final Pagination pagination;
  final bool hasReachedMax;
  final String totalSum;
  final Map<String, dynamic>? filter;
  final String? search;

  const SalesDashboardGoodsPaginationError({
    required this.message,
    required this.goods,
    required this.pagination,
    required this.hasReachedMax,
    required this.totalSum,
    this.filter,
    this.search,
  });

  @override
  List<Object?> get props => [
        message,
        goods,
        pagination,
        hasReachedMax,
        totalSum,
        filter,
        search,
      ];
}