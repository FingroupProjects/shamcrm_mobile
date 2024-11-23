// bloc/dashboard/projects_chart/project_chart_bloc.dart
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectChartBloc extends Bloc<ProjectChartEvent, ProjectChartState> {
  final ApiService _apiService;

  ProjectChartBloc(this._apiService) : super(ProjectChartInitial()) {
    on<LoadProjectChartData>(_onLoadProjectChartData);
  }

  Future<void> _onLoadProjectChartData(
    LoadProjectChartData event,
    Emitter<ProjectChartState> emit,
  ) async {
    try {
      emit(ProjectChartLoading());
      final projectChartData = await _apiService.getProjectChartData();
      emit(ProjectChartLoaded(data: projectChartData));
    } catch (e) {
      emit(ProjectChartError(message: e.toString()));
    }
  }
}
