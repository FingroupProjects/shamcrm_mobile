part of 'sales_dashboard_reconciliation_act_bloc.dart';

sealed class SalesDashboardReconciliationActEvent extends Equatable {
  const SalesDashboardReconciliationActEvent();
}

class LoadReconciliationActReport extends SalesDashboardReconciliationActEvent {
  const LoadReconciliationActReport({
    this.page = 1,
    this.perPage = 20,
    this.search,
    this.filter,
  });

  final int page;
  final int perPage;
  final String? search;
  final Map<String, dynamic>? filter;

  @override
  List<Object?> get props => [page, perPage, search, filter];
}