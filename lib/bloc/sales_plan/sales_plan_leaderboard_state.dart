import 'package:crm_task_manager/models/sales_plan/sales_plan_leaderboard.dart';
import 'package:equatable/equatable.dart';

abstract class SalesPlanLeaderboardState extends Equatable {
  const SalesPlanLeaderboardState();

  @override
  List<Object?> get props => [];
}

class SalesPlanLeaderboardInitial extends SalesPlanLeaderboardState {}

class SalesPlanLeaderboardLoading extends SalesPlanLeaderboardState {}

class SalesPlanLeaderboardLoaded extends SalesPlanLeaderboardState {
  final List<SalesPlanLeaderboardItem> items;

  const SalesPlanLeaderboardLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class SalesPlanLeaderboardError extends SalesPlanLeaderboardState {
  final String message;

  const SalesPlanLeaderboardError(this.message);

  @override
  List<Object?> get props => [message];
}
