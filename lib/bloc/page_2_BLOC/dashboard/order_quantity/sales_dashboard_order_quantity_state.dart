part of 'sales_dashboard_order_quantity_bloc.dart';

sealed class SalesDashboardOrderQuantityState extends Equatable {
  const SalesDashboardOrderQuantityState();
}

final class SalesDashboardOrderQuantityInitial extends SalesDashboardOrderQuantityState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardOrderQuantityLoading extends SalesDashboardOrderQuantityState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardOrderQuantityLoaded extends SalesDashboardOrderQuantityState {
  final OrderQuantityContent data;

  const SalesDashboardOrderQuantityLoaded({
    required this.data,
  });

  @override
  List<Object> get props => [data];
}

final class SalesDashboardOrderQuantityError extends SalesDashboardOrderQuantityState {
  final String message;

  const SalesDashboardOrderQuantityError({required this.message});

  @override
  List<Object> get props => [message];
}
