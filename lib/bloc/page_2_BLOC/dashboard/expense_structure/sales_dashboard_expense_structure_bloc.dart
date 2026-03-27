import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/expense_structure_content.dart';

part 'sales_dashboard_expense_structure_event.dart';
part 'sales_dashboard_expense_structure_state.dart';

class SalesDashboardExpenseStructureBloc extends Bloc<SalesDashboardExpenseStructureEvent, SalesDashboardExpenseStructureState> {
  final apiService = ApiService();

  SalesDashboardExpenseStructureBloc() : super(SalesDashboardExpenseStructureInitial()) {
    on<LoadExpenseStructureReport>((event, emit) async {
      // try {
        emit(SalesDashboardExpenseStructureLoading());

        debugPrint("Fetching expense structure report: filter=${event.filter}, search=${event.search}");

        final response = await apiService.getExpenseStructureByFilter(
          event.filter,
          event.search,
        );
        
        emit(SalesDashboardExpenseStructureLoaded(data: response));
      // } catch (e) {
      //   emit(SalesDashboardExpenseStructureError(
      //     message: e.toString().replaceAll('Exception: ', ''),
      //   ));
      // }
    });
  }
}
