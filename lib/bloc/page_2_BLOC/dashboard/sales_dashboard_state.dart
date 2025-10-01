part of 'sales_dashboard_bloc.dart';

sealed class SalesDashboardState extends Equatable {
  const SalesDashboardState();

  @override
  List<Object?> get props => [];
}

class SalesDashboardInitial extends SalesDashboardState {}

class SalesDashboardLoading extends SalesDashboardState {}

class SalesDashboardLoaded extends SalesDashboardState {
  final DebtorsResponse? debtorsResponse;
  final IlliquidGoodsResponse? illiquidGoodsResponse;
  final CashBalanceResponse? cashBalanceResponse;
  final CreditorsResponse? creditorsResponse;

  const SalesDashboardLoaded({
    this.debtorsResponse,
    this.illiquidGoodsResponse,
    this.cashBalanceResponse,
    this.creditorsResponse,
  });

  @override
  List<Object?> get props => [
    debtorsResponse,
    illiquidGoodsResponse,
    cashBalanceResponse,
    creditorsResponse,
  ];
}

class SalesDashboardError extends SalesDashboardState {
  final String message;

  const SalesDashboardError(this.message);

  @override
  List<Object> get props => [message];
}