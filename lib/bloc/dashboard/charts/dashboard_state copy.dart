import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/stats_model.dart';

/// Базовый класс для состояний Dashboard
abstract class DashboardState {}

/// Начальное состояние
class DashboardInitial extends DashboardState {}

/// Состояние загрузки данных
class DashboardLoading extends DashboardState {}

/// Состояние, содержащее только статистику Dashboard
class DashboardStatsLoaded extends DashboardState {
  final DashboardStats stats;

  DashboardStatsLoaded({required this.stats});
}

/// Состояние, содержащее только данные графика
class DashboardChartLoaded extends DashboardState {
  final List<ChartData> chartData;

  DashboardChartLoaded({required this.chartData});
}

/// Состояние, содержащее данные конверсии лидов
class LeadConversionDataLoaded extends DashboardState {
  final LeadConversion leadConversionData;

  LeadConversionDataLoaded({required this.leadConversionData});
}

/// Состояние ошибки
class DashboardError extends DashboardState {
  final String message;

  DashboardError({required this.message});
}
