// bloc/dashboard/projects_chart/project_chart_state.dart
import 'package:crm_task_manager/models/dashboard_charts_models/project_chart_model.dart';

abstract class ProjectChartState {}

class ProjectChartInitial extends ProjectChartState {}

class ProjectChartLoading extends ProjectChartState {}

class ProjectChartLoaded extends ProjectChartState {
  final ProjectChartResponse data;

  ProjectChartLoaded({required this.data});
}

class ProjectChartError extends ProjectChartState {
  final String message;

  ProjectChartError({required this.message});
}