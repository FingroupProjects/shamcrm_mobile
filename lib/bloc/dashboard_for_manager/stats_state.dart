import 'package:crm_task_manager/models/dashboard_charts_models_manager/user_task_model.dart';

abstract class UserStatsState {}

class UserStatsInitial extends UserStatsState {}

class UserStatsLoading extends UserStatsState {}

class UserStatsLoaded extends UserStatsState {
  final UserTaskCompletionManager stats;

  UserStatsLoaded({required this.stats});
}

class UserStatsError extends UserStatsState {
  final String message;

  UserStatsError({required this.message});
}
