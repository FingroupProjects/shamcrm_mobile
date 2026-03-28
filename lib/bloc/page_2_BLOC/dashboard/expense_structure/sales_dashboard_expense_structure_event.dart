part of 'sales_dashboard_expense_structure_bloc.dart';

sealed class SalesDashboardExpenseStructureEvent extends Equatable {
  const SalesDashboardExpenseStructureEvent();
}

class LoadExpenseStructureReport extends SalesDashboardExpenseStructureEvent {
  final String? search;
  final Map<String, dynamic>? filter;

  const LoadExpenseStructureReport({
    this.search,
    this.filter,
  });

  @override
  List<Object> get props => [search ?? '', filter ?? {}];
}
