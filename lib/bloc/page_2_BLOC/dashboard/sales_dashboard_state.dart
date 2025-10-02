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
  final NetProfitResponse netProfitData;

  const SalesDashboardLoaded({
    this.salesDashboardTopPart,
    // this.expenseStructure,
    this.salesData,
    required this.netProfitData,
  });

  @override
  List<Object?> get props => [
        salesDashboardTopPart,
        // expenseStructure,
        salesData,
        netProfitData,
      ];
}

class SalesDashboardError extends SalesDashboardState {
  final String message;

  const SalesDashboardError(this.message);

  @override
  List<Object> get props => [message];
}
