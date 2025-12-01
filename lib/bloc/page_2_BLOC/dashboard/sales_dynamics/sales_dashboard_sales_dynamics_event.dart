part of 'sales_dashboard_sales_dynamics_bloc.dart';

sealed class SalesDashboardSalesDynamicsEvent extends Equatable {
  const SalesDashboardSalesDynamicsEvent();
}

class LoadSalesDynamicsReport extends SalesDashboardSalesDynamicsEvent {
  final String? search;
  final Map<String, dynamic>? filter;

  const LoadSalesDynamicsReport({
    this.search,
    this.filter,
  });

  @override
  List<Object> get props => [search ?? '', filter ?? {}];
}
