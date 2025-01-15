import 'dart:io';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/lead_chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/lead_chart/chart_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class DashboardChartBlocManager extends Bloc<DashboardChartEventManager, DashboardChartStateManager> {
  final ApiService _apiService;

  DashboardChartBlocManager(this._apiService) : super(DashboardChartInitialManager()) {
    on<LoadLeadChartDataManager>(_onLoadLeadChartDataManager);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _onLoadLeadChartDataManager(
    LoadLeadChartDataManager event,
    Emitter<DashboardChartStateManager> emit,
  ) async {
    try {
      emit(DashboardChartLoadingManager());

      // Check for internet connection
      if (await _checkInternetConnection()) {
        final chartData = await _apiService.getLeadChartManager();
        emit(DashboardChartLoadedManager(chartData: chartData));
      } else {
        emit(DashboardChartErrorManager(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      }
    } catch (e) {
      emit(DashboardChartErrorManager(message: e.toString()));
    }
  }
}
