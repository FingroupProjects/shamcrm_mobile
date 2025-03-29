import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/task_chart_model.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/CACHE/task_chart_manager_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardTaskChartBlocManager
    extends Bloc<DashboardTaskChartEventManager, DashboardTaskChartStateManager> {
  final ApiService _apiService;

  DashboardTaskChartBlocManager(this._apiService)
      : super(DashboardTaskChartInitialManager()) {
    on<LoadTaskChartDataManager>(_onLoadTaskChartData);
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

  Future<void> _onLoadTaskChartData(
    LoadTaskChartDataManager event,
    Emitter<DashboardTaskChartStateManager> emit,
  ) async {
    try {

      // 1. Показываем данные из кэша (если они есть)
      List<double>? cachedData = await TaskChartCacheHandlerManager.getTaskChartDataManager();
      if (cachedData != null) {
        emit(DashboardTaskChartLoadedManager(taskChartData: TaskChartManager(data: cachedData)));
      }

      // 2. Асинхронно проверяем сервер
      if (await _checkInternetConnection()) {

        final taskChartData = await _apiService.getTaskChartDataManager();

        // Если данные с сервера не совпадают с кэшированными, обновляем кэш и UI
        if (cachedData == null || !_areListsEqual(taskChartData.data, cachedData)) {

          // Сохраняем новые данные в кэш
          await TaskChartCacheHandlerManager.saveTaskChartDataManager(taskChartData.data);

          // Обновляем UI
          emit(DashboardTaskChartLoadedManager(taskChartData: taskChartData));
        } else {
        }
      } else {
        if (cachedData == null) {
          emit(DashboardTaskChartErrorManager(message: "Нет данных и отсутствует подключение к интернету."));
        }
      }
    } catch (e) {
      emit(DashboardTaskChartErrorManager(message: e.toString()));
    }
  }

  // Сравнение двух списков данных
  bool _areListsEqual(List<double> a, List<double> b) {
    if (a.length != b.length) return false; // Сравниваем длину списков
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false; // Сравниваем элементы на каждой позиции
    }
    return true;
  }
}
