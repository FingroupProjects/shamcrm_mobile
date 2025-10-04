part of 'sales_dashboard_cash_balance_bloc.dart';

sealed class SalesDashboardCashBalanceEvent extends Equatable {
  const SalesDashboardCashBalanceEvent();
}

class LoadCashBalanceReport extends SalesDashboardCashBalanceEvent {
  final int page;
  final int perPage;
  final Map<String, dynamic>? filter;
  final String? search;

  const LoadCashBalanceReport({
    this.page = 1,
    this.perPage = 20,
    this.filter,
    this.search,
  });

  @override
  List<Object> get props => [page, perPage, filter ?? {}, search ?? ''];
}
