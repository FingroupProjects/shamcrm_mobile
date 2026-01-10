import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/creditors_model.dart';

part 'sales_dashboard_creditors_event.dart';
part 'sales_dashboard_creditors_state.dart';

class SalesDashboardCreditorsBloc extends Bloc<SalesDashboardCreditorsEvent, SalesDashboardCreditorsState> {
  final apiService = ApiService();

  SalesDashboardCreditorsBloc() : super(SalesDashboardCreditorsInitial()) {
    on<LoadCreditorsReport>((event, emit) async {
      try {
        emit(SalesDashboardCreditorsLoading());
        final response = await apiService.getCreditorsList(
          filters: event.filter,
          search: event.search,
        );
        emit(SalesDashboardCreditorsLoaded(result: response));
      } catch (e) {
        emit(SalesDashboardCreditorsError(
          message: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    });
  }
}
