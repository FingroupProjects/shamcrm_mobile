part of 'sales_dashboard_goods_expiration_bloc.dart';

sealed class SalesDashboardGoodsExpirationState extends Equatable {
  const SalesDashboardGoodsExpirationState();
}

final class SalesDashboardGoodsExpirationInitial
    extends SalesDashboardGoodsExpirationState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardGoodsExpirationLoading
    extends SalesDashboardGoodsExpirationState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardGoodsExpirationLoaded
    extends SalesDashboardGoodsExpirationState {
  final List<GoodsExpirationItem> items;
  final Pagination pagination;
  final bool hasReachedMax;
  final Map<String, dynamic>? filter;
  final String? search;

  const SalesDashboardGoodsExpirationLoaded({
    required this.items,
    required this.pagination,
    required this.hasReachedMax,
    this.filter,
    this.search,
  });

  @override
  List<Object?> get props => [items, pagination, hasReachedMax, filter, search];
}

final class SalesDashboardGoodsExpirationError
    extends SalesDashboardGoodsExpirationState {
  final String message;

  const SalesDashboardGoodsExpirationError({required this.message});

  @override
  List<Object> get props => [message];
}

final class SalesDashboardGoodsExpirationPaginationError
    extends SalesDashboardGoodsExpirationState {
  final String message;

  const SalesDashboardGoodsExpirationPaginationError({required this.message});

  @override
  List<Object> get props => [message];
}
