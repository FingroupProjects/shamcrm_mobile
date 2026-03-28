import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/act_of_reconciliation_model.dart';

part 'sales_dashboard_reconciliation_act_event.dart';
part 'sales_dashboard_reconciliation_act_state.dart';

class SalesDashboardReconciliationActBloc extends Bloc<SalesDashboardReconciliationActEvent, SalesDashboardReconciliationActState> {
  final apiService = ApiService();

  SalesDashboardReconciliationActBloc() : super(SalesDashboardReconciliationActInitial()) {
    on<LoadReconciliationActReport>((event, emit) async {
      // try {
        emit(SalesDashboardReconciliationActLoading());

        debugPrint("Event Filter: ${event.filter}");
        if (event.filter == null) {
          debugPrint("Filter is null, exiting.");
          return;
        }

        if (event.filter!['lead_id'] == null && event.filter!['supplier_id'] == null) {
          debugPrint("Both lead_id and supplier_id are null, exiting.");
          return;
        }

        var type = event.filter!['lead_id'] != null ? 'lead_id' : 'supplier_id';

        debugPrint("Type: $type");
        debugPrint("ID: ${event.filter![type]}");

        final response = await apiService.getReconciliationAct(
          search: event.search,
          filters: event.filter,
        );
        emit(SalesDashboardReconciliationActLoaded(data: response));
      // } catch (e) {
      //   emit(SalesDashboardReconciliationActError(
      //     message: e.toString().replaceAll('Exception: ', ''),
      //   ));
      // }
    });
  }
}
