import 'package:crm_task_manager/models/dashboard_model.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final List<ChartData> chartData;

  DashboardLoaded({
    required this.stats,
    required this.chartData,
    
  });
}
  class LeadConversionDataLoaded extends DashboardState {
    final LeadConversion leadConversionData;

    LeadConversionDataLoaded({required this.leadConversionData});
    
  }

class DashboardError extends DashboardState {
  final String message;
  
  DashboardError({required this.message});
}
