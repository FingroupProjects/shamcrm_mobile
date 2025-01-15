import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardTaskChartBloc
    extends Bloc<DashboardTaskChartEvent, DashboardTaskChartState> {
  final ApiService _apiService;

  DashboardTaskChartBloc(this._apiService)
      : super(DashboardTaskChartInitial()) {
    on<LoadTaskChartData>(_onLoadTaskChartData);
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
    LoadTaskChartData event,
    Emitter<DashboardTaskChartState> emit,
  ) async {
    try {
      // Проверяем, были ли уже загружены данные
      if (state is DashboardTaskChartLoaded) {
        // Если данные уже загружены, не загружаем их снова
        return;
      }

      emit(DashboardTaskChartLoading());

      // Check for internet connection
      if (await _checkInternetConnection()) {
        final taskChartData = await _apiService.getTaskChartData();
        emit(DashboardTaskChartLoaded(taskChartData: taskChartData));
      } else {
        emit(DashboardTaskChartError(message: 'Ошибка подключения к интернету.'));
      }
    } catch (e) {
      emit(DashboardTaskChartError(message: e.toString()));
    }
  }
}
