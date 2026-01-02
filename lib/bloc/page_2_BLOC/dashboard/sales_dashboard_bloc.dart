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

    // Wave 1 & 2: Load both in parallel, but emit progressively
    on<LoadPriorityData>((event, emit) async {
      debugPrint("📊 Starting parallel data loading...");
      emit(SalesDashboardLoading());

      // Helper function to safely load data and catch errors
      Future<T?> safeLoad<T>(Future<T> Function() loader, String errorKey) async {
        try {
          return await loader();
        } catch (e) {
          debugPrint("❌ Error loading $errorKey: $e");
          return null;
        }
      }

      // Запускаем обе волны параллельно с обработкой ошибок
      final wave1Results = await Future.wait([
        safeLoad(() => apiService.getSalesDashboardTopPart(), 'topPart'),
        safeLoad(() => apiService.getTopSellingGoodsDashboard(), 'topSelling'),
        safeLoad(() => apiService.getIlliquidGoods(), 'illiquidGoods'),
      ]);

      final wave2Results = await Future.wait([
        safeLoad(() => apiService.getNetProfitData(), 'netProfit'),
        safeLoad(() => apiService.getOrderDashboard(), 'orderDashboard'),
        safeLoad(() => apiService.getExpenseStructure(), 'expenseStructure'),
        safeLoad(() => apiService.getProfitability(), 'profitability'),
        safeLoad(() => apiService.getSalesDynamics(), 'salesDynamics'),
      ]);

      // Collect errors
      final Map<String, String> graphErrors = {};
      
      final salesDashboardTopResponse = wave1Results[0] as DashboardTopPart?;
      final topSellingData = wave1Results[1] as List<AllTopSellingData>?;
      final illiquidGoodsData = wave1Results[2] as IlliquidGoodsResponse?;

      final netProfitData = wave2Results[0] as List<AllNetProfitData>?;
      final orderDashboardData = wave2Results[1] as List<AllOrdersData>?;
      final expenseStructureData = wave2Results[2] as List<AllExpensesData>?;
      final profitabilityData = wave2Results[3] as List<AllProfitabilityData>?;
      final salesData = wave2Results[4] as List<AllSalesDynamicsData>?;

      // Track errors
      if (salesDashboardTopResponse == null) graphErrors['topPart'] = 'Ошибка загрузки';
      if (topSellingData == null) graphErrors['topSelling'] = 'Ошибка загрузки';
      if (illiquidGoodsData == null) graphErrors['illiquidGoods'] = 'Ошибка загрузки';
      if (netProfitData == null) graphErrors['netProfit'] = 'Ошибка загрузки';
      if (orderDashboardData == null) graphErrors['orderDashboard'] = 'Ошибка загрузки';
      if (expenseStructureData == null) graphErrors['expenseStructure'] = 'Ошибка загрузки';
      if (profitabilityData == null) graphErrors['profitability'] = 'Ошибка загрузки';
      if (salesData == null) graphErrors['salesDynamics'] = 'Ошибка загрузки';

      // Проверяем, есть ли хотя бы минимальные данные для показа
      if (salesDashboardTopResponse == null && topSellingData == null && illiquidGoodsData == null) {
        debugPrint("❌ All Wave 1 data failed to load");
        emit(SalesDashboardError("Не удалось загрузить данные дашборда"));
        return;
      }

      debugPrint("✅ Wave 1: Priority data loaded (some may have failed)");

      // Сразу показываем пользователю Wave 1 данные (используем значения по умолчанию для null)
      emit(SalesDashboardPriorityLoaded(
        salesDashboardTopPart: salesDashboardTopResponse ?? DashboardTopPart(result: null, errors: null),
        topSellingData: topSellingData ?? [],
        illiquidGoodsData: illiquidGoodsData ?? IlliquidGoodsResponse(result: null, errors: null),
        graphErrors: graphErrors,
      ));

      // Показываем индикатор загрузки Wave 2
      emit(SalesDashboardLoadingSecondary(
        salesDashboardTopPart: salesDashboardTopResponse ?? DashboardTopPart(result: null, errors: null),
        topSellingData: topSellingData ?? [],
        illiquidGoodsData: illiquidGoodsData ?? IlliquidGoodsResponse(result: null, errors: null),
        graphErrors: graphErrors,
      ));

      debugPrint("✅ Wave 2: Secondary data loaded (some may have failed)");

      // Показываем все данные
      emit(SalesDashboardFullyLoaded(
        salesDashboardTopPart: salesDashboardTopResponse ?? DashboardTopPart(result: null, errors: null),
        topSellingData: topSellingData ?? [],
        illiquidGoodsData: illiquidGoodsData ?? IlliquidGoodsResponse(result: null, errors: null),
        netProfitData: netProfitData ?? [],
        orderDashboardData: orderDashboardData ?? [],
        expenseStructureData: expenseStructureData ?? [],
        profitabilityData: profitabilityData ?? [],
        salesData: salesData ?? [],
        graphErrors: graphErrors,
      ));
    });

    // Wave 2: Load secondary data (fallback for manual trigger)
    on<LoadSecondaryData>((event, emit) async {
      debugPrint("📊 Wave 2: Loading secondary dashboard data (manual)...");

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
        graphErrors: currentState.graphErrors,
      ));

      // Helper function to safely load data and catch errors
      Future<T?> safeLoad<T>(Future<T> Function() loader, String errorKey) async {
        try {
          return await loader();
        } catch (e) {
          debugPrint("❌ Error loading $errorKey: $e");
          return null;
        }
      }

      // Load remaining data in parallel (Wave 2) with error handling
      final results = await Future.wait([
        safeLoad(() => apiService.getNetProfitData(), 'netProfit'),
        safeLoad(() => apiService.getOrderDashboard(), 'orderDashboard'),
        safeLoad(() => apiService.getExpenseStructure(), 'expenseStructure'),
        safeLoad(() => apiService.getProfitability(), 'profitability'),
        safeLoad(() => apiService.getSalesDynamics(), 'salesDynamics'),
      ]);

      final netProfitData = results[0] as List<AllNetProfitData>?;
      final orderDashboardData = results[1] as List<AllOrdersData>?;
      final expenseStructureData = results[2] as List<AllExpensesData>?;
      final profitabilityData = results[3] as List<AllProfitabilityData>?;
      final salesData = results[4] as List<AllSalesDynamicsData>?;

      // Merge errors with existing ones
      final graphErrors = Map<String, String>.from(currentState.graphErrors);
      if (netProfitData == null) graphErrors['netProfit'] = 'Ошибка загрузки';
      if (orderDashboardData == null) graphErrors['orderDashboard'] = 'Ошибка загрузки';
      if (expenseStructureData == null) graphErrors['expenseStructure'] = 'Ошибка загрузки';
      if (profitabilityData == null) graphErrors['profitability'] = 'Ошибка загрузки';
      if (salesData == null) graphErrors['salesDynamics'] = 'Ошибка загрузки';

      debugPrint("✅ Wave 2: Secondary data loaded (some may have failed)");

      // Emit complete data
      emit(SalesDashboardFullyLoaded(
        salesDashboardTopPart: currentState.salesDashboardTopPart,
        topSellingData: currentState.topSellingData,
        illiquidGoodsData: currentState.illiquidGoodsData,
        netProfitData: netProfitData ?? [],
        orderDashboardData: orderDashboardData ?? [],
        expenseStructureData: expenseStructureData ?? [],
        profitabilityData: profitabilityData ?? [],
        salesData: salesData ?? [],
        graphErrors: graphErrors,
      ));
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

    // Reload order quantity data for specific period
    on<ReloadOrderQuantityData>((event, emit) async {
      debugPrint("🔄 Reloading order quantity data for period: ${event.period.name}");
      
      try {
        final currentState = state;
        
        // Загружаем данные для нового периода
        final newPeriodData = await apiService.getOrderDashboardForPeriod(event.period);
        
        // Обновляем только если состояние SalesDashboardFullyLoaded
        if (currentState is SalesDashboardFullyLoaded) {
          final updatedOrderDashboardData = _updateOrderDashboardData(
            currentState.orderDashboardData, 
            newPeriodData,
          );
          
          emit(SalesDashboardFullyLoaded(
            salesDashboardTopPart: currentState.salesDashboardTopPart,
            topSellingData: currentState.topSellingData,
            illiquidGoodsData: currentState.illiquidGoodsData,
            salesData: currentState.salesData,
            netProfitData: currentState.netProfitData,
            orderDashboardData: updatedOrderDashboardData,
            expenseStructureData: currentState.expenseStructureData,
            profitabilityData: currentState.profitabilityData,
          ));
        }
        
        debugPrint("✅ Order quantity data reloaded for period: ${event.period.name}");
      } catch (e) {
        debugPrint("❌ Error reloading order quantity data for period ${event.period.name}: $e");
        // Не показываем ошибку пользователю, просто логируем
      }
    });

    // Reload net profit data for specific period
    on<ReloadNetProfitData>((event, emit) async {
      debugPrint("🔄 Reloading net profit data for period: ${event.period.name}");
      
      try {
        final currentState = state;
        
        // Загружаем данные для нового периода
        final newPeriodData = await apiService.getNetProfitDataForPeriod(event.period);
        
        // Обновляем только если состояние SalesDashboardFullyLoaded
        if (currentState is SalesDashboardFullyLoaded) {
          final updatedNetProfitData = _updateNetProfitData(
            currentState.netProfitData, 
            newPeriodData,
          );
          
          emit(SalesDashboardFullyLoaded(
            salesDashboardTopPart: currentState.salesDashboardTopPart,
            topSellingData: currentState.topSellingData,
            illiquidGoodsData: currentState.illiquidGoodsData,
            salesData: currentState.salesData,
            netProfitData: updatedNetProfitData,
            orderDashboardData: currentState.orderDashboardData,
            expenseStructureData: currentState.expenseStructureData,
            profitabilityData: currentState.profitabilityData,
          ));
        }
        
        debugPrint("✅ Net profit data reloaded for period: ${event.period.name}");
      } catch (e) {
        debugPrint("❌ Error reloading net profit data for period ${event.period.name}: $e");
        // Не показываем ошибку пользователю, просто логируем
      }
    });

    // Reload expense structure data for specific period
    on<ReloadExpenseStructureData>((event, emit) async {
      debugPrint("🔄 Reloading expense structure data for period: ${event.period.name}");
      
      try {
        final currentState = state;
        
        // Загружаем данные для нового периода
        final newPeriodData = await apiService.getExpenseStructureForPeriod(event.period);
        
        // Обновляем только если состояние SalesDashboardFullyLoaded
        if (currentState is SalesDashboardFullyLoaded) {
          final updatedExpenseStructureData = _updateExpenseStructureData(
            currentState.expenseStructureData, 
            newPeriodData,
          );
          
          emit(SalesDashboardFullyLoaded(
            salesDashboardTopPart: currentState.salesDashboardTopPart,
            topSellingData: currentState.topSellingData,
            illiquidGoodsData: currentState.illiquidGoodsData,
            salesData: currentState.salesData,
            netProfitData: currentState.netProfitData,
            orderDashboardData: currentState.orderDashboardData,
            expenseStructureData: updatedExpenseStructureData,
            profitabilityData: currentState.profitabilityData,
          ));
        }
        
        debugPrint("✅ Expense structure data reloaded for period: ${event.period.name}");
      } catch (e) {
        debugPrint("❌ Error reloading expense structure data for period ${event.period.name}: $e");
        // Не показываем ошибку пользователю, просто логируем
      }
    });

    // Start loading on initialization after all updates are implemented
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

  /// Обновляет список orderDashboardData новыми данными для периода
  List<AllOrdersData> _updateOrderDashboardData(
    List<AllOrdersData> currentData,
    AllOrdersData newData,
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

  /// Обновляет список netProfitData новыми данными для периода
  List<AllNetProfitData> _updateNetProfitData(
    List<AllNetProfitData> currentData,
    AllNetProfitData newData,
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

  /// Обновляет список expenseStructureData новыми данными для периода
  List<AllExpensesData> _updateExpenseStructureData(
    List<AllExpensesData> currentData,
    AllExpensesData newData,
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