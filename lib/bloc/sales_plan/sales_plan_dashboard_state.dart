import 'package:crm_task_manager/models/sales_plan/sales_plan_dashboard_item.dart';
import 'package:equatable/equatable.dart';

abstract class SalesPlanDashboardState extends Equatable {
  const SalesPlanDashboardState();

  @override
  List<Object?> get props => [];
}

class SalesPlanDashboardInitial extends SalesPlanDashboardState {}

class SalesPlanDashboardLoading extends SalesPlanDashboardState {}

class SalesPlanDashboardLoaded extends SalesPlanDashboardState {
  final List<SalesPlanDashboardItem> items;

  const SalesPlanDashboardLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class SalesPlanDashboardError extends SalesPlanDashboardState {
  final String message;

  const SalesPlanDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
