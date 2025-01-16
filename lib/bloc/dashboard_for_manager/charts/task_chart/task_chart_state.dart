
import 'package:crm_task_manager/models/dashboard_charts_models_manager/task_chart_model.dart';

abstract class DashboardTaskChartStateManager {}

class DashboardTaskChartInitialManager extends DashboardTaskChartStateManager {}

class DashboardTaskChartLoadingManager extends DashboardTaskChartStateManager {}

class DashboardTaskChartLoadedManager extends DashboardTaskChartStateManager {
  final TaskChartManager taskChartData;

  DashboardTaskChartLoadedManager({required this.taskChartData});
}

class DashboardTaskChartErrorManager extends DashboardTaskChartStateManager {
  final String message;

  DashboardTaskChartErrorManager({required this.message});
}

class DashboardTaskChartAlreadyLoadedManager extends DashboardTaskChartStateManager {
  final TaskChartManager taskChartData;

  DashboardTaskChartAlreadyLoadedManager({required this.taskChartData});
}
