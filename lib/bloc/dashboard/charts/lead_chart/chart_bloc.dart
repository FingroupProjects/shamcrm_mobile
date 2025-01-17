import 'dart:io';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_chart_model.dart';
import 'package:crm_task_manager/screens/dashboard/CACHE/lead_chart_cache.dart'; // Импортируйте обработчик кеша

class DashboardChartBloc extends Bloc<DashboardChartEvent, DashboardChartState> {
  final ApiService _apiService;

  DashboardChartBloc(this._apiService) : super(DashboardChartInitial()) {
    on<LoadLeadChartData>(_onLoadLeadChartData);
  }

  // Проверка подключения к интернету
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  // Загрузка данных для графика лидов
  Future<void> _onLoadLeadChartData(
    LoadLeadChartData event,
    Emitter<DashboardChartState> emit,
  ) async {
    try {
      emit(DashboardChartLoading());

      // 1. Показываем данные из кеша, если они есть
      List<ChartData>? cachedData = await LeadChartCacheHandler.getLeadChartData();

      if (cachedData != null) {
        print("📦 Найдены данные графика в кеше.");
        emit(DashboardChartLoaded(chartData: cachedData));
      }

      // 2. Проверка подключения к интернету
      if (await _checkInternetConnection()) {
        print("🌐 Интернет подключен. Получаем данные с сервера...");
        final chartData = await _apiService.getLeadChart();

        // Если данные в кеше равны null или отличаются от данных с сервера, обновляем кэш и UI
        if (cachedData == null || !_areChartDataEqual(chartData, cachedData)) {
          print("✅ Новые данные с сервера. Обновляем кэш и UI.");

          // Сохраняем новые данные в кеш
          await LeadChartCacheHandler.saveLeadChartData(chartData);

          // Отправляем новые данные в UI
          emit(DashboardChartLoaded(chartData: chartData));
        } else {
          print("🔄 КЛИЕНТЫ Данные с сервера совпадают с кешированными. Обновление не требуется.");
        }
      } else {
        print("🚫 Нет подключения к интернету.");
        if (cachedData == null) {
          emit(DashboardChartError(message: "Нет данных и нет подключения к интернету."));
        }
      }
    } catch (e) {
      emit(DashboardChartError(message: e.toString()));
    }
  }

  // Вспомогательная функция для сравнения данных графика
  bool _areChartDataEqual(List<ChartData> a, List<ChartData> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      // Сравниваем label, data (списки) и color
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
