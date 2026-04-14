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
  final int currentPage;
  final int totalPages;
  final bool hasReachedMax;

  const SalesDashboardDebtorsLoaded({
    required this.result,
    required this.currentPage,
    required this.totalPages,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [result, currentPage, totalPages, hasReachedMax];
}

final class SalesDashboardDebtorsError extends SalesDashboardDebtorsState {
  final String message;

  const SalesDashboardDebtorsError({required this.message});

  @override
  List<Object> get props => [message];
}
