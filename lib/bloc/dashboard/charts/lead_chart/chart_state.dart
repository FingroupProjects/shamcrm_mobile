import 'package:crm_task_manager/models/dashboard_charts_models/lead_chart_model.dart';

abstract class DashboardChartState {}

class DashboardChartInitial extends DashboardChartState {}

class DashboardChartLoading extends DashboardChartState {}

class DashboardChartLoaded extends DashboardChartState {
  final List<ChartData> chartData;

  DashboardChartLoaded({required this.chartData});
}

class DashboardChartError extends DashboardChartState {
  final String message;

  DashboardChartError({required this.message});
}
