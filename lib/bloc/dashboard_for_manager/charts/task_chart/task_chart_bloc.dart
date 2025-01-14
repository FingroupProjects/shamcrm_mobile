import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardTaskChartBlocManager
    extends Bloc<DashboardTaskChartEventManager, DashboardTaskChartStateManager> {
  final ApiService _apiService;

  DashboardTaskChartBlocManager(this._apiService)
      : super(DashboardTaskChartInitialManager()) {
    on<LoadTaskChartDataManager>(_onLoadTaskChartData);
  }

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
      // Проверяем, были ли уже загружены данные
      if (state is DashboardTaskChartLoadedManager) {
        // Если данные уже загружены, не загружаем их снова
        return;
      }

      emit(DashboardTaskChartLoadingManager());

      // Check for internet connection
      if (await _checkInternetConnection()) {
        final taskChartData = await _apiService.getTaskChartDataManager();
        emit(DashboardTaskChartLoadedManager(taskChartData: taskChartData));
      } else {
        emit(DashboardTaskChartErrorManager(message: 'Ошибка подключения к интернету.'));
      }
    } catch (e) {
      emit(DashboardTaskChartErrorManager(message: e.toString()));
    }
  }
}
