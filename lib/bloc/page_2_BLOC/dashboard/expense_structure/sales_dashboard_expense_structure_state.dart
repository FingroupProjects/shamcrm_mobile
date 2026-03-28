part of 'sales_dashboard_expense_structure_bloc.dart';

sealed class SalesDashboardExpenseStructureState extends Equatable {
  const SalesDashboardExpenseStructureState();
}

final class SalesDashboardExpenseStructureInitial extends SalesDashboardExpenseStructureState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardExpenseStructureLoading extends SalesDashboardExpenseStructureState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardExpenseStructureLoaded extends SalesDashboardExpenseStructureState {
  final ExpenseResponse data;

  const SalesDashboardExpenseStructureLoaded({
    required this.data,
  });

  @override
  List<Object> get props => [data];
}

final class SalesDashboardExpenseStructureError extends SalesDashboardExpenseStructureState {
  final String message;

  const SalesDashboardExpenseStructureError({required this.message});

  @override
  List<Object> get props => [message];
}
