import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/act_of_reconciliation_model.dart';

part 'sales_dashboard_reconciliation_act_event.dart';
part 'sales_dashboard_reconciliation_act_state.dart';

class SalesDashboardReconciliationActBloc extends Bloc<
    SalesDashboardReconciliationActEvent,
    SalesDashboardReconciliationActState> {
  final apiService = ApiService();

  SalesDashboardReconciliationActBloc()
      : super(SalesDashboardReconciliationActInitial()) {
    on<LoadReconciliationActReport>((event, emit) async {
      try {
        debugPrint("Event Filter: ${event.filter}");
        if (event.filter == null ||
            (event.filter!['lead_id'] == null &&
                event.filter!['supplier_id'] == null)) {
          emit(SalesDashboardReconciliationActLoaded(
            data: ActOfReconciliationResponse(result: const []),
          ));
          return;
        }

        emit(SalesDashboardReconciliationActLoading());
        final response = await apiService.getReconciliationAct(
          search: event.search,
          filters: event.filter,
        );
        emit(SalesDashboardReconciliationActLoaded(data: response));
      } catch (e) {
        emit(SalesDashboardReconciliationActError(
          message: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    });
  }
}
