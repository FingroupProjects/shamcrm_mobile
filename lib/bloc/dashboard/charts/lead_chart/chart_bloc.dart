import 'dart:io';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class DashboardChartBloc extends Bloc<DashboardChartEvent, DashboardChartState> {
  final ApiService _apiService;

  DashboardChartBloc(this._apiService) : super(DashboardChartInitial()) {
    on<LoadLeadChartData>(_onLoadLeadChartData);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _onLoadLeadChartData(
    LoadLeadChartData event,
    Emitter<DashboardChartState> emit,
  ) async {
    try {
      emit(DashboardChartLoading());

      // Check for internet connection
      if (await _checkInternetConnection()) {
        final chartData = await _apiService.getLeadChart();
        emit(DashboardChartLoaded(chartData: chartData));
      } else {
        emit(DashboardChartError(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      }
    } catch (e) {
      emit(DashboardChartError(message: e.toString()));
    }
  }
}
