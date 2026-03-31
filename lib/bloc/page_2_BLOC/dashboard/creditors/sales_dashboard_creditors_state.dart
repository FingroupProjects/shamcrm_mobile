part of 'sales_dashboard_creditors_bloc.dart';

sealed class SalesDashboardCreditorsState extends Equatable {
  const SalesDashboardCreditorsState();
}

final class SalesDashboardCreditorsInitial
    extends SalesDashboardCreditorsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardCreditorsLoading
    extends SalesDashboardCreditorsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardCreditorsLoaded extends SalesDashboardCreditorsState {
  final CreditorsResponse result;
  final int currentPage;
  final int totalPages;
  final bool hasReachedMax;

  const SalesDashboardCreditorsLoaded({
    required this.result,
    required this.currentPage,
    required this.totalPages,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [result, currentPage, totalPages, hasReachedMax];
}

final class SalesDashboardCreditorsError extends SalesDashboardCreditorsState {
  final String message;

  const SalesDashboardCreditorsError({required this.message});

  @override
  List<Object> get props => [message];
}
