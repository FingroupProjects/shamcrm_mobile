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
  final SalesResponse? salesData;
  final List<AllNetProfitData> netProfitData;
  final List<AllOrdersData> orderDashboardData;
  final List<AllExpensesData> expenseStructureData;

  const SalesDashboardLoaded({
    this.salesDashboardTopPart,
    this.salesData,
    required this.netProfitData,
    required this.orderDashboardData,
    required this.expenseStructureData,
  });

  @override
  List<Object?> get props => [
        salesDashboardTopPart,
        salesData,
        netProfitData,
        orderDashboardData,
      ];
}

class SalesDashboardError extends SalesDashboardState {
  final String message;

  const SalesDashboardError(this.message);

  @override
  List<Object> get props => [message];
}
