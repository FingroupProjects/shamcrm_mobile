import 'package:crm_task_manager/models/page_2/dashboard/net_profit_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/order_dashboard_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../api/service/api_service.dart';
import '../../../models/page_2/dashboard/dashboard_top.dart';
import '../../../models/page_2/dashboard/expense_structure.dart';
import '../../../models/page_2/dashboard/illiquids_model.dart';
import '../../../models/page_2/dashboard/profitability_dashboard_model.dart';
import '../../../models/page_2/dashboard/sales_model.dart';
import '../../../models/page_2/dashboard/top_selling_model.dart';

part 'sales_dashboard_event.dart';

part 'sales_dashboard_state.dart';

class SalesDashboardBloc extends Bloc<SalesDashboardEvent, SalesDashboardState> {
  final apiService = ApiService();

  SalesDashboardBloc() : super(SalesDashboardInitial()) {
    on<LoadInitialData>((event, emit) async {
      debugPrint("Loading initial sales dashboard data...");
      emit(SalesDashboardLoading());

      final results = await Future.wait([
        apiService.getSalesDashboardTopPart(),
        apiService.getSalesDynamics(),
        apiService.getNetProfitData(),
        apiService.getOrderDashboard(),
        apiService.getExpenseStructure(),
        apiService.getProfitability(),
        apiService.getTopSellingGoodsDashboard(),
        apiService.getIlliquidGoods(),
      ]);

      final salesDashboardTopResponse = results[0] as DashboardTopPart;
      final salesData = results[1] as SalesResponse;
      final netProfitData = results[2] as List<AllNetProfitData>;
      final orderDashboardData = results[3] as List<AllOrdersData>;
      final expenseStructureData = results[4] as List<AllExpensesData>;
      final profitabilityData = results[5] as List<AllProfitabilityData>;
      final topSellingData = results[6] as List<AllTopSellingData>;
      final illiquidGoodsData = results[7] as IlliquidGoodsResponse;

      emit(SalesDashboardLoaded(
        salesDashboardTopPart: salesDashboardTopResponse,
        salesData: salesData,
        netProfitData: netProfitData,
        orderDashboardData: orderDashboardData,
        expenseStructureData: expenseStructureData,
        profitabilityData: profitabilityData,
        topSellingData: topSellingData,
        illiquidGoodsData: illiquidGoodsData,
      ));
    });

    on<ReloadInitialData>((event, emit) {
      debugPrint("Reloading sales dashboard data...");
      emit(SalesDashboardLoading());
      add(LoadInitialData());
    });

    add(LoadInitialData());
  }
}
