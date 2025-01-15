import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';

abstract class DashboardConversionState {}

class DashboardConversionInitial extends DashboardConversionState {}

class DashboardConversionLoading extends DashboardConversionState {}

class DashboardConversionLoaded extends DashboardConversionState {
  final LeadConversion leadConversionData;

  DashboardConversionLoaded({required this.leadConversionData});
}

class DashboardConversionError extends DashboardConversionState {
  final String message;

  DashboardConversionError({required this.message});
}
