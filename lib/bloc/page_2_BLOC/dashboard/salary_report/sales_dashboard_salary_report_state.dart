part of 'sales_dashboard_salary_report_bloc.dart';

sealed class SalesDashboardSalaryReportState extends Equatable {
  const SalesDashboardSalaryReportState();
}

final class SalesDashboardSalaryReportInitial
    extends SalesDashboardSalaryReportState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardSalaryReportLoading
    extends SalesDashboardSalaryReportState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardSalaryReportLoaded
    extends SalesDashboardSalaryReportState {
  final SalaryReportResponse result;

  const SalesDashboardSalaryReportLoaded({
    required this.result,
  });

  @override
  List<Object> get props => [result];
}

final class SalesDashboardSalaryReportError
    extends SalesDashboardSalaryReportState {
  final String message;

  const SalesDashboardSalaryReportError({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
