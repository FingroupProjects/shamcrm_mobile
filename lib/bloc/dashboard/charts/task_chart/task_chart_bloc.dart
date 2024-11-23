
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

  Future<void> _onLoadTaskChartData(
    LoadTaskChartData event,
    Emitter<DashboardTaskChartState> emit,
  ) async {
    try {
      emit(DashboardTaskChartLoading());
      final taskChartData = await _apiService.getTaskChartData();
      emit(DashboardTaskChartLoaded(taskChartData: taskChartData));
    } catch (e) {
      emit(DashboardTaskChartError(message: e.toString()));
    }
  }
}
