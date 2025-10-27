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

    // Wave 1: Load priority data first
    on<LoadPriorityData>((event, emit) async {
      debugPrint("📊 Wave 1: Loading priority dashboard data...");
      emit(SalesDashboardLoading());

      try {
        // Load critical data in parallel (Wave 1)
        final results = await Future.wait([
          apiService.getSalesDashboardTopPart(),
          apiService.getTopSellingGoodsDashboard(),
          apiService.getIlliquidGoods(),
        ]);

        final salesDashboardTopResponse = results[0] as DashboardTopPart;
        final topSellingData = results[1] as List<AllTopSellingData>;
        final illiquidGoodsData = results[2] as IlliquidGoodsResponse;

        debugPrint("✅ Wave 1: Priority data loaded successfully");

        // Emit priority data immediately
        emit(SalesDashboardPriorityLoaded(
          salesDashboardTopPart: salesDashboardTopResponse,
          topSellingData: topSellingData,
          illiquidGoodsData: illiquidGoodsData,
        ));

        // Automatically trigger Wave 2
        add(LoadSecondaryData());

      } catch (e) {
        debugPrint("❌ Wave 1: Error loading priority data: $e");
        emit(SalesDashboardError("Failed to load dashboard data: $e"));
      }
    });

    // Wave 2: Load secondary data in background
    on<LoadSecondaryData>((event, emit) async {
      debugPrint("📊 Wave 2: Loading secondary dashboard data...");

      // Get current priority data from state
      final currentState = state;
      if (currentState is! SalesDashboardPriorityLoaded) {
        debugPrint("⚠️ Wave 2: Cannot load without Wave 1 data");
        return;
      }

      // Show loading indicator for Wave 2
      emit(SalesDashboardLoadingSecondary(
        salesDashboardTopPart: currentState.salesDashboardTopPart,
        topSellingData: currentState.topSellingData,
        illiquidGoodsData: currentState.illiquidGoodsData,
      ));

      try {
        // Load remaining data in parallel (Wave 2)
        final results = await Future.wait([
          apiService.getNetProfitData(),
          apiService.getOrderDashboard(),
          apiService.getExpenseStructure(),
          apiService.getProfitability(),
          apiService.getSalesDynamics(),
        ]);

        final netProfitData = results[0] as List<AllNetProfitData>;
        final orderDashboardData = results[1] as List<AllOrdersData>;
        final expenseStructureData = results[2] as List<AllExpensesData>;
        final profitabilityData = results[3] as List<AllProfitabilityData>;
        final salesData = results[4] as SalesResponse;

        debugPrint("✅ Wave 2: Secondary data loaded successfully");

        // Emit complete data
        emit(SalesDashboardFullyLoaded(
          salesDashboardTopPart: currentState.salesDashboardTopPart,
          topSellingData: currentState.topSellingData,
          illiquidGoodsData: currentState.illiquidGoodsData,
          netProfitData: netProfitData,
          orderDashboardData: orderDashboardData,
          expenseStructureData: expenseStructureData,
          profitabilityData: profitabilityData,
          salesData: salesData,
        ));

      } catch (e) {
        debugPrint("⚠️ Wave 2: Error loading secondary data: $e");
        // Don't emit error - keep showing Wave 1 data
        // User can retry via pull-to-refresh
      }
    });

    // Reload all data (for pull-to-refresh)
    on<ReloadAllData>((event, emit) {
      debugPrint("🔄 Reloading all dashboard data...");
      add(LoadPriorityData());
    });

    // Legacy support - map to new events
    on<LoadInitialData>((event, emit) {
      add(LoadPriorityData());
    });

    on<ReloadInitialData>((event, emit) {
      add(ReloadAllData());
    });

    // Start loading on initialization
    add(LoadPriorityData());
  }
}