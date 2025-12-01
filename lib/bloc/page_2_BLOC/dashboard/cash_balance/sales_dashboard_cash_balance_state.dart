part of 'sales_dashboard_cash_balance_bloc.dart';

sealed class SalesDashboardCashBalanceState extends Equatable {
  const SalesDashboardCashBalanceState();
}

final class SalesDashboardProductsInitial extends SalesDashboardCashBalanceState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardCashBalanceLoading extends SalesDashboardCashBalanceState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardCashBalanceLoaded extends SalesDashboardCashBalanceState {
  final CashBalanceResponse data;

  const SalesDashboardCashBalanceLoaded({
    required this.data,
  });

  @override
  List<Object> get props => [data];
}

final class SalesDashboardCashBalanceError extends SalesDashboardCashBalanceState {
  final String message;

  const SalesDashboardCashBalanceError({required this.message});

  @override
  List<Object> get props => [message];
}
