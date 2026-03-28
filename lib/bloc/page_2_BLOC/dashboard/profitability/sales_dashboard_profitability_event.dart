part of 'sales_dashboard_profitability_bloc.dart';

sealed class SalesDashboardProfitabilityEvent extends Equatable {
  const SalesDashboardProfitabilityEvent();
}

class LoadProfitabilityReport extends SalesDashboardProfitabilityEvent {
  final String? search;
  final Map<String, dynamic>? filter;

  const LoadProfitabilityReport({
    this.search,
    this.filter,
  });

  @override
  List<Object> get props => [search ?? '', filter ?? {}];
}
