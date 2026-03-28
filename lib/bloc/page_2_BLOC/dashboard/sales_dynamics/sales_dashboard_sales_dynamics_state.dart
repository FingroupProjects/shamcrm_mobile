part of 'sales_dashboard_sales_dynamics_bloc.dart';

sealed class SalesDashboardSalesDynamicsState extends Equatable {
  const SalesDashboardSalesDynamicsState();
}

final class SalesDashboardSalesDynamicsInitial extends SalesDashboardSalesDynamicsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardSalesDynamicsLoading extends SalesDashboardSalesDynamicsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardSalesDynamicsLoaded extends SalesDashboardSalesDynamicsState {
  final SalesResponse data;

  const SalesDashboardSalesDynamicsLoaded({
    required this.data,
  });

  @override
  List<Object> get props => [data];
}

final class SalesDashboardSalesDynamicsError extends SalesDashboardSalesDynamicsState {
  final String message;

  const SalesDashboardSalesDynamicsError({required this.message});

  @override
  List<Object> get props => [message];
}
