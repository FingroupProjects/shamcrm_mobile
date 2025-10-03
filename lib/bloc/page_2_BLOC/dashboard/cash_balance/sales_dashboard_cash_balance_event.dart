part of 'sales_dashboard_cash_balance_bloc.dart';

sealed class SalesDashboardCashBalanceEvent extends Equatable {
  const SalesDashboardCashBalanceEvent();
}

class LoadCashBalanceReport extends SalesDashboardCashBalanceEvent {
  final int page;
  final int perPage;

  const LoadCashBalanceReport({
    this.page = 1,
    this.perPage = 20,
  });

  @override
  List<Object> get props => [page, perPage];
}
