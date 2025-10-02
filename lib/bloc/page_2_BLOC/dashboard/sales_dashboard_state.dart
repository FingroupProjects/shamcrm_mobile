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
  final NetProfitResponse netProfitData;
  final List<AllOrdersData> orderDashboardData;

  const SalesDashboardLoaded({
    this.salesDashboardTopPart,
    this.salesData,
    required this.netProfitData,
    required this.orderDashboardData,
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
