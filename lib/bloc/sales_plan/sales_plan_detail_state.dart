import 'package:crm_task_manager/models/sales_plan/sales_plan_leaderboard.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:equatable/equatable.dart';

abstract class SalesPlanDetailState extends Equatable {
  const SalesPlanDetailState();

  @override
  List<Object?> get props => [];
}

class SalesPlanDetailInitial extends SalesPlanDetailState {}

class SalesPlanDetailLoading extends SalesPlanDetailState {}

class SalesPlanDetailLoaded extends SalesPlanDetailState {
  final SalesPlan plan;
  final List<SalesPlanLeaderboardItem> hierarchyFromLeaderboard;
  final List<SalesPlan> dailyArchive;
  final bool archiveLoading;

  const SalesPlanDetailLoaded({
    required this.plan,
    this.hierarchyFromLeaderboard = const [],
    this.dailyArchive = const [],
    this.archiveLoading = false,
  });

  SalesPlanDetailLoaded copyWith({
    SalesPlan? plan,
    List<SalesPlanLeaderboardItem>? hierarchyFromLeaderboard,
    List<SalesPlan>? dailyArchive,
    bool? archiveLoading,
  }) {
    return SalesPlanDetailLoaded(
      plan: plan ?? this.plan,
      hierarchyFromLeaderboard:
          hierarchyFromLeaderboard ?? this.hierarchyFromLeaderboard,
      dailyArchive: dailyArchive ?? this.dailyArchive,
      archiveLoading: archiveLoading ?? this.archiveLoading,
    );
  }

  @override
  List<Object?> get props =>
      [plan, hierarchyFromLeaderboard, dailyArchive, archiveLoading];
}

class SalesPlanDetailError extends SalesPlanDetailState {
  final String message;

  const SalesPlanDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
