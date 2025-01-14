import 'package:crm_task_manager/models/dashboard_charts_models_manager/lead_chart_model.dart';

abstract class DashboardChartStateManager {}

class DashboardChartInitialManager extends DashboardChartStateManager {}

class DashboardChartLoadingManager extends DashboardChartStateManager {}

class DashboardChartLoadedManager extends DashboardChartStateManager {
  final List<ChartDataManager> chartData;

  DashboardChartLoadedManager({required this.chartData});
}

class DashboardChartErrorManager extends DashboardChartStateManager {
  final String message;

  DashboardChartErrorManager({required this.message});
}
