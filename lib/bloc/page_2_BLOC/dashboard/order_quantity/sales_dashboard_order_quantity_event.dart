part of 'sales_dashboard_order_quantity_bloc.dart';

sealed class SalesDashboardOrderQuantityEvent extends Equatable {
  const SalesDashboardOrderQuantityEvent();
}

class LoadOrderQuantityReport extends SalesDashboardOrderQuantityEvent {
  final String? search;
  final Map<String, dynamic>? filter;

  const LoadOrderQuantityReport({
    this.search,
    this.filter,
  });

  @override
  List<Object> get props => [search ?? '', filter ?? {}];
}
