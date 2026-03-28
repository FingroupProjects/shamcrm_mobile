part of 'sales_dashboard_profitability_bloc.dart';

sealed class SalesDashboardProfitabilityState extends Equatable {
  const SalesDashboardProfitabilityState();
}

final class SalesDashboardProfitabilityInitial extends SalesDashboardProfitabilityState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardProfitabilityLoading extends SalesDashboardProfitabilityState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardProfitabilityLoaded extends SalesDashboardProfitabilityState {
  final ProfitabilityResponse data;

  const SalesDashboardProfitabilityLoaded({
    required this.data,
  });

  @override
  List<Object> get props => [data];
}

final class SalesDashboardProfitabilityError extends SalesDashboardProfitabilityState {
  final String message;

  const SalesDashboardProfitabilityError({required this.message});

  @override
  List<Object> get props => [message];
}
