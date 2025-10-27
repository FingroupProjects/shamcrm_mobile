part of 'sales_dashboard_bloc.dart';

sealed class SalesDashboardEvent extends Equatable {
  const SalesDashboardEvent();
}

/// Load critical data first (Wave 1)
class LoadPriorityData extends SalesDashboardEvent {
  @override
  List<Object> get props => [];
}

/// Load secondary data in background (Wave 2)
class LoadSecondaryData extends SalesDashboardEvent {
  @override
  List<Object> get props => [];
}

/// Reload everything (for pull-to-refresh)
class ReloadAllData extends SalesDashboardEvent {
  @override
  List<Object> get props => [];
}

/// Legacy event for backward compatibility
class LoadInitialData extends SalesDashboardEvent {
  @override
  List<Object> get props => [];
}

class ReloadInitialData extends SalesDashboardEvent {
  @override
  List<Object> get props => [];
}