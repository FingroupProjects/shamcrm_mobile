import 'package:crm_task_manager/models/dashboard_charts_models/task_chart_model.dart';

abstract class DashboardTaskChartState {}

class DashboardTaskChartInitial extends DashboardTaskChartState {}

class DashboardTaskChartLoading extends DashboardTaskChartState {}

class DashboardTaskChartLoaded extends DashboardTaskChartState {
  final TaskChart taskChartData;

  DashboardTaskChartLoaded({required this.taskChartData});
}

class DashboardTaskChartError extends DashboardTaskChartState {
  final String message;

  DashboardTaskChartError({required this.message});
}

class DashboardTaskChartAlreadyLoaded extends DashboardTaskChartState {
  final TaskChart taskChartData;

  DashboardTaskChartAlreadyLoaded({required this.taskChartData});
}
