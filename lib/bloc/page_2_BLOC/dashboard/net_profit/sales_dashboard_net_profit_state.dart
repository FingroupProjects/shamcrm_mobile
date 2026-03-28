part of 'sales_dashboard_net_profit_bloc.dart';

sealed class SalesDashboardNetProfitState extends Equatable {
  const SalesDashboardNetProfitState();
}

final class SalesDashboardNetProfitInitial extends SalesDashboardNetProfitState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardNetProfitLoading extends SalesDashboardNetProfitState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardNetProfitLoaded extends SalesDashboardNetProfitState {
  final NetProfitResponse data;

  const SalesDashboardNetProfitLoaded({
    required this.data,
  });

  @override
  List<Object> get props => [data];
}

final class SalesDashboardNetProfitError extends SalesDashboardNetProfitState {
  final String message;

  const SalesDashboardNetProfitError({required this.message});

  @override
  List<Object> get props => [message];
}
