import 'package:crm_task_manager/models/dashboard_charts_models/deal_state_model.dart';


abstract class DealStatsState {}

class DealStatsInitial extends DealStatsState {}

class DealStatsLoading extends DealStatsState {}

class DealStatsLoaded extends DealStatsState {
  final DealStatsResponse dealStatsData;

  DealStatsLoaded({required this.dealStatsData});
}

class DealStatsError extends DealStatsState {
  final String message;

  DealStatsError({required this.message});
}
