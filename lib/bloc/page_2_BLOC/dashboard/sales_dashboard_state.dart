part of 'sales_dashboard_bloc.dart';

sealed class SalesDashboardState extends Equatable {
  const SalesDashboardState();

  @override
  List<Object?> get props => [];
}

class SalesDashboardInitial extends SalesDashboardState {}

class SalesDashboardLoading extends SalesDashboardState {}

class SalesDashboardLoaded extends SalesDashboardState {
  final DashboardTopPart? salesDashboardTopPart;
  // final ExpenseDashboard? expenseStructure;
  final SalesResponse? salesData;

  const SalesDashboardLoaded({
    this.salesDashboardTopPart,
    // this.expenseStructure,
    this.salesData,
  });

  @override
  List<Object?> get props => [
        salesDashboardTopPart,
        // expenseStructure,
    salesData,
      ];
}

class SalesDashboardError extends SalesDashboardState {
  final String message;

  const SalesDashboardError(this.message);

  @override
  List<Object> get props => [message];
}
