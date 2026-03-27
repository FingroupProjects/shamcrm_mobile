part of 'sales_dashboard_net_profit_bloc.dart';

sealed class SalesDashboardNetProfitEvent extends Equatable {
  const SalesDashboardNetProfitEvent();
}

class LoadNetProfitReport extends SalesDashboardNetProfitEvent {
  final String? search;
  final Map<String, dynamic>? filter;

  const LoadNetProfitReport({
    this.search,
    this.filter,
  });

  @override
  List<Object> get props => [search ?? '', filter ?? {}];
}
