import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/salary_report_model.dart';

part 'sales_dashboard_salary_report_event.dart';
part 'sales_dashboard_salary_report_state.dart';

class SalesDashboardSalaryReportBloc extends Bloc<
    SalesDashboardSalaryReportEvent, SalesDashboardSalaryReportState> {
  final apiService = ApiService();

  SalesDashboardSalaryReportBloc()
      : super(SalesDashboardSalaryReportInitial()) {
    on<LoadSalaryReport>((event, emit) async {
      try {
        emit(SalesDashboardSalaryReportLoading());
        final response = await apiService.getSalaryReport(
          filters: event.filter,
          search: event.search,
        );
        emit(SalesDashboardSalaryReportLoaded(result: response));
      } catch (e) {
        emit(SalesDashboardSalaryReportError(
          message: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    });
  }
}
