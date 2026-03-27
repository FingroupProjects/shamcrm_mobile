import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/debtors_model.dart';

part 'sales_dashboard_debtors_event.dart';
part 'sales_dashboard_debtors_state.dart';

class SalesDashboardDebtorsBloc extends Bloc<SalesDashboardDebtorsEvent, SalesDashboardDebtorsState> {
  final apiService = ApiService();

  SalesDashboardDebtorsBloc() : super(SalesDashboardDebtorsInitial()) {
    on<LoadDebtorsReport>((event, emit) async {
      try {
        emit(SalesDashboardDebtorsLoading());
        final response = await apiService.getDebtorsList(
          filters: event.filter,
          search: event.search,
        );
        emit(SalesDashboardDebtorsLoaded(result: response));
      } catch (e) {
        emit(SalesDashboardDebtorsError(
          message: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    });
  }
}
