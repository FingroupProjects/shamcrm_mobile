part of 'sales_dashboard_debtors_bloc.dart';

sealed class SalesDashboardDebtorsEvent extends Equatable {
  const SalesDashboardDebtorsEvent();
}

class LoadDebtorsReport extends SalesDashboardDebtorsEvent {

  final Map<String, dynamic>? filter;
  final String? search;

  const LoadDebtorsReport({this. filter, this.search});

  @override
  List<Object?> get props => [filter, search];
}
