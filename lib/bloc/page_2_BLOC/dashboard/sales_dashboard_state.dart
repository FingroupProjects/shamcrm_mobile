part of 'sales_dashboard_bloc.dart';

sealed class SalesDashboardState extends Equatable {
  const SalesDashboardState();

  @override
  List<Object?> get props => [];
}

class SalesDashboardInitial extends SalesDashboardState {}

class SalesDashboardLoading extends SalesDashboardState {}

/// Wave 1 loaded - show priority data immediately
class SalesDashboardPriorityLoaded extends SalesDashboardState {
  final DashboardTopPart salesDashboardTopPart;
  final List<AllTopSellingData> topSellingData;
  final IlliquidGoodsResponse illiquidGoodsData;
  final Map<String, String> graphErrors;

  const SalesDashboardPriorityLoaded({
    required this.salesDashboardTopPart,
    required this.topSellingData,
    required this.illiquidGoodsData,
    this.graphErrors = const {},
  });

  @override
  List<Object?> get props => [
    salesDashboardTopPart,
    topSellingData,
    illiquidGoodsData,
    graphErrors,
  ];
}

/// Wave 2 loading - show Wave 1 data + loading indicators for Wave 2
class SalesDashboardLoadingSecondary extends SalesDashboardState {
  final DashboardTopPart salesDashboardTopPart;
  final List<AllTopSellingData> topSellingData;
  final IlliquidGoodsResponse illiquidGoodsData;
  final Map<String, String> graphErrors;

  const SalesDashboardLoadingSecondary({
    required this.salesDashboardTopPart,
    required this.topSellingData,
    required this.illiquidGoodsData,
    this.graphErrors = const {},
  });

  @override
  List<Object?> get props => [
    salesDashboardTopPart,
    topSellingData,
    illiquidGoodsData,
    graphErrors,
  ];
}

/// All data loaded - complete dashboard
class SalesDashboardFullyLoaded extends SalesDashboardState {
  final DashboardTopPart salesDashboardTopPart;
  final List<AllTopSellingData> topSellingData;
  final IlliquidGoodsResponse illiquidGoodsData;
  final List<AllSalesDynamicsData> salesData;
  final List<AllNetProfitData> netProfitData;
  final List<AllOrdersData> orderDashboardData;
  final List<AllExpensesData> expenseStructureData;
  final List<AllProfitabilityData> profitabilityData;
  final Map<String, String> graphErrors;

  const SalesDashboardFullyLoaded({
    required this.salesDashboardTopPart,
    required this.topSellingData,
    required this.illiquidGoodsData,
    required this.salesData,
    required this.netProfitData,
    required this.orderDashboardData,
    required this.expenseStructureData,
    required this.profitabilityData,
    this.graphErrors = const {},
  });

  @override
  List<Object?> get props => [
    salesDashboardTopPart,
    topSellingData,
    illiquidGoodsData,
    salesData,
    netProfitData,
    orderDashboardData,
    expenseStructureData,
    profitabilityData,
    graphErrors,
  ];
}

/// Legacy state for backward compatibility
class SalesDashboardLoaded extends SalesDashboardState {
  final DashboardTopPart? salesDashboardTopPart;
  final List<AllSalesDynamicsData>? salesData;
  final List<AllNetProfitData> netProfitData;
  final List<AllOrdersData> orderDashboardData;
  final List<AllExpensesData> expenseStructureData;
  final List<AllProfitabilityData> profitabilityData;
  final List<AllTopSellingData> topSellingData;
  final IlliquidGoodsResponse illiquidGoodsData;

  const SalesDashboardLoaded({
    required this.salesDashboardTopPart,
    required this.salesData,
    required this.netProfitData,
    required this.orderDashboardData,
    required this.expenseStructureData,
    required this.profitabilityData,
    required this.topSellingData,
    required this.illiquidGoodsData,
  });

  @override
  List<Object?> get props => [
    salesDashboardTopPart,
    salesData,
    netProfitData,
    orderDashboardData,
    expenseStructureData,
    profitabilityData,
    topSellingData,
    illiquidGoodsData,
  ];
}

class SalesDashboardError extends SalesDashboardState {
  final String message;

  const SalesDashboardError(this.message);

  @override
  List<Object> get props => [message];
}