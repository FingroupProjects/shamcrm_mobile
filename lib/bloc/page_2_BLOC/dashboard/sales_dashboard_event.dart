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

/// Reload top selling data for specific period
class ReloadTopSellingData extends SalesDashboardEvent {
  final TopSellingTimePeriod period;
  
  const ReloadTopSellingData(this.period);
  
  @override
  List<Object> get props => [period];
}

/// Reload sales dynamics data for specific period
class ReloadSalesDynamicsData extends SalesDashboardEvent {
  final SalesDynamicsTimePeriod period;
  
  const ReloadSalesDynamicsData(this.period);
  
  @override
  List<Object> get props => [period];
}

/// Reload profitability data for specific period
class ReloadProfitabilityData extends SalesDashboardEvent {
  final ProfitabilityTimePeriod period;
  
  const ReloadProfitabilityData(this.period);
  
  @override
  List<Object> get props => [period];
}

/// Reload order quantity data for specific period
class ReloadOrderQuantityData extends SalesDashboardEvent {
  final OrderTimePeriod period;
  
  const ReloadOrderQuantityData(this.period);
  
  @override
  List<Object> get props => [period];
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