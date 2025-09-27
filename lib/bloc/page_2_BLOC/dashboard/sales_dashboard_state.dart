part of 'sales_dashboard_bloc.dart';

sealed class SalesDashboardState extends Equatable {
  const SalesDashboardState();
}

final class SalesDashboardInitial extends SalesDashboardState {
  @override
  List<Object> get props => [];
}
