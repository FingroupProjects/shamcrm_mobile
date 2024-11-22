import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';


class DashboardChartBloc extends Bloc<DashboardChartEvent, DashboardChartState> {
  final ApiService _apiService;

  DashboardChartBloc(this._apiService) : super(DashboardChartInitial()) {
    on<LoadLeadChartData>(_onLoadLeadChartData);
  }

  Future<void> _onLoadLeadChartData(
    LoadLeadChartData event,
    Emitter<DashboardChartState> emit,
  ) async {
    try {
      emit(DashboardChartLoading());
      final chartData = await _apiService.getLeadChart();
      emit(DashboardChartLoaded(chartData: chartData));
    } catch (e) {
      emit(DashboardChartError(message: e.toString()));
    }
  }
}
