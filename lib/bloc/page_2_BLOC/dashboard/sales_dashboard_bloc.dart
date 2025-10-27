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
        final salesData = results[4] as List<AllSalesDynamicsData>;

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

    // Reload top selling data for specific period
    on<ReloadTopSellingData>((event, emit) async {
      debugPrint("🔄 Reloading top selling data for period: ${event.period.name}");
      
      try {
        final currentState = state;
        
        // Загружаем данные для нового периода
        final newPeriodData = await apiService.getTopSellingGoodsForPeriod(event.period);
        
        // Обновляем в зависимости от текущего состояния
        if (currentState is SalesDashboardFullyLoaded) {
          final updatedTopSellingData = _updateTopSellingData(
            currentState.topSellingData, 
            newPeriodData,
          );
          
          emit(SalesDashboardFullyLoaded(
            salesDashboardTopPart: currentState.salesDashboardTopPart,
            topSellingData: updatedTopSellingData,
            illiquidGoodsData: currentState.illiquidGoodsData,
            salesData: currentState.salesData,
            netProfitData: currentState.netProfitData,
            orderDashboardData: currentState.orderDashboardData,
            expenseStructureData: currentState.expenseStructureData,
            profitabilityData: currentState.profitabilityData,
          ));
        } else if (currentState is SalesDashboardPriorityLoaded) {
          final updatedTopSellingData = _updateTopSellingData(
            currentState.topSellingData, 
            newPeriodData,
          );
          
          emit(SalesDashboardPriorityLoaded(
            salesDashboardTopPart: currentState.salesDashboardTopPart,
            topSellingData: updatedTopSellingData,
            illiquidGoodsData: currentState.illiquidGoodsData,
          ));
        } else if (currentState is SalesDashboardLoaded) {
          final updatedTopSellingData = _updateTopSellingData(
            currentState.topSellingData, 
            newPeriodData,
          );
          
          emit(SalesDashboardLoaded(
            salesDashboardTopPart: currentState.salesDashboardTopPart,
            salesData: currentState.salesData,
            netProfitData: currentState.netProfitData,
            orderDashboardData: currentState.orderDashboardData,
            expenseStructureData: currentState.expenseStructureData,
            profitabilityData: currentState.profitabilityData,
            topSellingData: updatedTopSellingData,
            illiquidGoodsData: currentState.illiquidGoodsData,
          ));
        }
        
        debugPrint("✅ Top selling data reloaded for period: ${event.period.name}");
      } catch (e) {
        debugPrint("❌ Error reloading top selling data for period ${event.period.name}: $e");
        // Не показываем ошибку пользователю, просто логируем
      }
    });

    // Reload sales dynamics data for specific period
    on<ReloadSalesDynamicsData>((event, emit) async {
      debugPrint("🔄 Reloading sales dynamics data for period: ${event.period.name}");
      
      try {
        final currentState = state;
        
        // Загружаем данные для нового периода
        final newPeriodData = await apiService.getSalesDynamicsForPeriod(event.period);
        
        // Обновляем только если состояние SalesDashboardFullyLoaded
        if (currentState is SalesDashboardFullyLoaded) {
          final updatedSalesDynamicsData = _updateSalesDynamicsData(
            currentState.salesData, 
            newPeriodData,
          );
          
          emit(SalesDashboardFullyLoaded(
            salesDashboardTopPart: currentState.salesDashboardTopPart,
            topSellingData: currentState.topSellingData,
            illiquidGoodsData: currentState.illiquidGoodsData,
            salesData: updatedSalesDynamicsData,
            netProfitData: currentState.netProfitData,
            orderDashboardData: currentState.orderDashboardData,
            expenseStructureData: currentState.expenseStructureData,
            profitabilityData: currentState.profitabilityData,
          ));
        }
        
        debugPrint("✅ Sales dynamics data reloaded for period: ${event.period.name}");
      } catch (e) {
        debugPrint("❌ Error reloading sales dynamics data for period ${event.period.name}: $e");
        // Не показываем ошибку пользователю, просто логируем
      }
    });

    // Reload profitability data for specific period
    on<ReloadProfitabilityData>((event, emit) async {
      debugPrint("🔄 Reloading profitability data for period: ${event.period.name}");
      
      try {
        final currentState = state;
        
        // Загружаем данные для нового периода
        final newPeriodData = await apiService.getProfitabilityForPeriod(event.period);
        
        // Обновляем только если состояние SalesDashboardFullyLoaded
        if (currentState is SalesDashboardFullyLoaded) {
          final updatedProfitabilityData = _updateProfitabilityData(
            currentState.profitabilityData, 
            newPeriodData,
          );
          
          emit(SalesDashboardFullyLoaded(
            salesDashboardTopPart: currentState.salesDashboardTopPart,
            topSellingData: currentState.topSellingData,
            illiquidGoodsData: currentState.illiquidGoodsData,
            salesData: currentState.salesData,
            netProfitData: currentState.netProfitData,
            orderDashboardData: currentState.orderDashboardData,
            expenseStructureData: currentState.expenseStructureData,
            profitabilityData: updatedProfitabilityData,
          ));
        }
        
        debugPrint("✅ Profitability data reloaded for period: ${event.period.name}");
      } catch (e) {
        debugPrint("❌ Error reloading profitability data for period ${event.period.name}: $e");
        // Не показываем ошибку пользователю, просто логируем
      }
    });

    // Start loading on initialization
    add(LoadPriorityData());
  }

  /// Обновляет список topSellingData новыми данными для периода
  List<AllTopSellingData> _updateTopSellingData(
    List<AllTopSellingData> currentData,
    AllTopSellingData newData,
  ) {
    final updatedList = [...currentData];
    final index = updatedList.indexWhere((item) => item.period == newData.period);
    
    if (index != -1) {
      // Заменяем существующие данные
      updatedList[index] = newData;
    } else {
      // Добавляем новые данные
      updatedList.add(newData);
    }
    
    return updatedList;
  }

  /// Обновляет список salesDynamicsData новыми данными для периода
  List<AllSalesDynamicsData> _updateSalesDynamicsData(
    List<AllSalesDynamicsData> currentData,
    AllSalesDynamicsData newData,
  ) {
    final updatedList = [...currentData];
    final index = updatedList.indexWhere((item) => item.period == newData.period);
    
    if (index != -1) {
      // Заменяем существующие данные
      updatedList[index] = newData;
    } else {
      // Добавляем новые данные
      updatedList.add(newData);
    }
    
    return updatedList;
  }

  /// Обновляет список profitabilityData новыми данными для периода
  List<AllProfitabilityData> _updateProfitabilityData(
    List<AllProfitabilityData> currentData,
    AllProfitabilityData newData,
  ) {
    final updatedList = [...currentData];
    final index = updatedList.indexWhere((item) => item.period == newData.period);
    
    if (index != -1) {
      // Заменяем существующие данные
      updatedList[index] = newData;
    } else {
      // Добавляем новые данные
      updatedList.add(newData);
    }
    
    return updatedList;
  }
}