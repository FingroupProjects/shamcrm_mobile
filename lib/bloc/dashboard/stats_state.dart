import 'package:crm_task_manager/models/dashboard_charts_models/stats_model.dart';

abstract class DashboardStatsState {}

class DashboardStatsInitial extends DashboardStatsState {}

class DashboardStatsLoading extends DashboardStatsState {}

class DashboardStatsLoaded extends DashboardStatsState {
  final DashboardStats stats;

  DashboardStatsLoaded({required this.stats});
}

class DashboardStatsError extends DashboardStatsState {
  final String message;

  DashboardStatsError({required this.message});
}
