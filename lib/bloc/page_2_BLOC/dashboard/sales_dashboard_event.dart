part of 'sales_dashboard_bloc.dart';

sealed class SalesDashboardEvent extends Equatable {
  const SalesDashboardEvent();
}

class LoadInitialData extends SalesDashboardEvent {
  @override
  List<Object> get props => [];
}
