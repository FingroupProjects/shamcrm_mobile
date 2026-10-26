part of 'sales_dashboard_reconciliation_act_bloc.dart';

sealed class SalesDashboardReconciliationActState extends Equatable {
  const SalesDashboardReconciliationActState();
}

final class SalesDashboardReconciliationActInitial extends SalesDashboardReconciliationActState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardReconciliationActLoading extends SalesDashboardReconciliationActState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardReconciliationActLoaded extends SalesDashboardReconciliationActState {
  final ActOfReconciliationResponse data;
  final int currentPage;
  final int totalPages;
  final bool hasReachedMax;

  const SalesDashboardReconciliationActLoaded({
    required this.data,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasReachedMax = false,
  });

  @override
  List<Object> get props => [data, currentPage, totalPages, hasReachedMax];
}

final class SalesDashboardReconciliationActError extends SalesDashboardReconciliationActState {
  final String message;

  const SalesDashboardReconciliationActError({required this.message});

  @override
  List<Object> get props => [message];
}
