// States
import 'package:crm_task_manager/models/dashboard_charts_models/process_speed%20_model.dart';

abstract class ProcessSpeedState {}

class ProcessSpeedInitial extends ProcessSpeedState {}

class ProcessSpeedLoading extends ProcessSpeedState {}

class ProcessSpeedLoaded extends ProcessSpeedState {
  final ProcessSpeed processSpeedData;

  ProcessSpeedLoaded({required this.processSpeedData});
}

class ProcessSpeedError extends ProcessSpeedState {
  final String message;

  ProcessSpeedError({required this.message});
}
