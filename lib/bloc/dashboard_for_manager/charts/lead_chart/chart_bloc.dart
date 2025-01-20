import 'dart:io';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/lead_chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/lead_chart/chart_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/lead_chart_model.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/CACHE/lead_chart_manager_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class DashboardChartBlocManager extends Bloc<DashboardChartEventManager, DashboardChartStateManager> {
  final ApiService _apiService;

  DashboardChartBlocManager(this._apiService) : super(DashboardChartInitialManager()) {
    on<LoadLeadChartDataManager>(_onLoadLeadChartDataManager);
  }

  // Проверка интернет-соединения
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  // Загрузка данных графика лидов (с кешированием)
  Future<void> _onLoadLeadChartDataManager(
    LoadLeadChartDataManager event,
    Emitter<DashboardChartStateManager> emit,
  ) async {
    try {
      emit(DashboardChartLoadingManager()); // Состояние загрузки

      // 1. Проверка наличия кешированных данных
      List<ChartDataManager>? cachedData = await LeadChartCacheHandlerManager.getLeadChartDataManager();

      if (cachedData != null) {
        print("📦 Найдены данные графика в кеше.");
        emit(DashboardChartLoadedManager(chartData: cachedData)); // Отправка данных из кеша
      }

      // 2. Проверка наличия интернет-соединения
      if (await _checkInternetConnection()) {
        print("🌐 Интернет подключен. Получаем данные с сервера...");
        final chartData = await _apiService.getLeadChartManager(); // Получаем данные с сервера

        // Если кешированные данные пусты или данные с сервера отличаются от кешированных, обновляем кеш и UI
        if (cachedData == null || !_areChartDataEqual(chartData, cachedData)) {
          print("✅ Получены новые данные с сервера. Обновляем кеш и UI.");

          // Сохраняем новые данные в кеш
          await LeadChartCacheHandlerManager.saveLeadChartDataManager(chartData);

          // Отправляем новые данные в UI
          emit(DashboardChartLoadedManager(chartData: chartData));
        } else {
          print("🔄 КЛИЕНТЫ Данные с сервера совпадают с кешированными. Обновление не требуется.");
        }
      } else {
        print("🚫 Нет интернет-соединения.");
        if (cachedData == null) {
          emit(DashboardChartErrorManager(message: "Нет данных и нет интернет-соединения.")); // Ошибка при отсутствии данных и соединения
        }
      }
    } catch (e) {
      emit(DashboardChartErrorManager(message: e.toString())); // Отправка ошибки
    }
  }

  // Вспомогательная функция для сравнения данных графика
  bool _areChartDataEqual(List<ChartDataManager> a, List<ChartDataManager> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      // Сравниваем метку, данные (списки) и цвет
      if (a[i].label != b[i].label || 
          !_areDataListsEqual(a[i].data, b[i].data) || 
          a[i].color != b[i].color) {
        return false;
      }
    }
    return true;
  }

  // Вспомогательная функция для сравнения двух списков данных (List<double>)
  bool _areDataListsEqual(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
