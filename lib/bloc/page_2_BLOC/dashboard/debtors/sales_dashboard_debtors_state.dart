part of 'sales_dashboard_debtors_bloc.dart';

sealed class SalesDashboardDebtorsState extends Equatable {
  const SalesDashboardDebtorsState();
}

final class SalesDashboardDebtorsInitial extends SalesDashboardDebtorsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardDebtorsLoading extends SalesDashboardDebtorsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardDebtorsLoaded extends SalesDashboardDebtorsState {
  final DebtorsResponse result;

  const SalesDashboardDebtorsLoaded({
    required this.result,
  });

  @override
  List<Object> get props => [result];
}

final class SalesDashboardDebtorsError extends SalesDashboardDebtorsState {
  final String message;

  const SalesDashboardDebtorsError({required this.message});

  @override
  List<Object> get props => [message];
}
