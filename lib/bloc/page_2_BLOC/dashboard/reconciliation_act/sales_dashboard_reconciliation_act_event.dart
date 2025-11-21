part of 'sales_dashboard_reconciliation_act_bloc.dart';

sealed class SalesDashboardReconciliationActEvent extends Equatable {
  const SalesDashboardReconciliationActEvent();
}

class LoadReconciliationActReport extends SalesDashboardReconciliationActEvent {
  const LoadReconciliationActReport({
    this.search,
    this.filter,
  });

  final String? search;
  final Map<String, dynamic>? filter;

  @override
  List<Object> get props => [search ?? '', filter ?? {}];
}