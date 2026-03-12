part of 'sales_dashboard_salary_report_bloc.dart';

sealed class SalesDashboardSalaryReportEvent extends Equatable {
  const SalesDashboardSalaryReportEvent();
}

class LoadSalaryReport extends SalesDashboardSalaryReportEvent {
  final Map<String, dynamic>? filter;
  final String? search;

  const LoadSalaryReport({
    this.filter,
    this.search,
  });

  @override
  List<Object?> get props => [filter, search];
}
