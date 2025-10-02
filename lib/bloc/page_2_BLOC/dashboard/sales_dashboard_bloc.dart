import 'package:crm_task_manager/models/money/expense_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/net_profit_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../api/service/api_service.dart';
import '../../../models/page_2/dashboard/dashboard_top.dart';
import '../../../models/page_2/dashboard/expense_structure.dart';
import '../../../models/page_2/dashboard/sales_model.dart';

part 'sales_dashboard_event.dart';
part 'sales_dashboard_state.dart';

class SalesDashboardBloc extends Bloc<SalesDashboardEvent, SalesDashboardState> {

  final apiService = ApiService();

  SalesDashboardBloc() : super(SalesDashboardInitial()) {
    on<LoadInitialData>((event, emit) async {

        emit(SalesDashboardLoading());

        final results = await Future.wait([
          apiService.getSalesDashboardTopPart(),
          // apiService.getExpenseStructure(),
          apiService.getSalesDynamics(),
          apiService.getNetProfit(),
        ]);

        final salesDashboardTopResponse = results[0] as DashboardTopPart;
        // final expenseStructure = results[1] as ExpenseDashboard;
        final salesData = results[1] as SalesResponse;
        final netProfitData = results[2] as NetProfitResponse;

        emit(SalesDashboardLoaded(
          salesDashboardTopPart: salesDashboardTopResponse,
          // expenseStructure: expenseStructure,
          salesData: salesData,
          netProfitData: netProfitData,
        ));
    });

    add(LoadInitialData());
  }
}
