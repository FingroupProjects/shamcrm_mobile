part of 'sales_dashboard_creditors_bloc.dart';

sealed class SalesDashboardCreditorsEvent extends Equatable {
  const SalesDashboardCreditorsEvent();
}

class LoadCreditorsReport extends SalesDashboardCreditorsEvent {
  final Map<String, dynamic>? filter;
  final String? search;
  

  const LoadCreditorsReport({this. filter, this.search});

  @override
  List<Object?> get props => [filter, search];
}
