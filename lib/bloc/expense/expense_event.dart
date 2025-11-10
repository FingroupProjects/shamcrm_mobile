part of 'expense_bloc.dart';

sealed class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class FetchExpenses extends ExpenseEvent {
  final String? query;

  const FetchExpenses({this.query});

  @override
  List<Object?> get props => [query];
}

class LoadMoreExpenses extends ExpenseEvent {
  const LoadMoreExpenses();
}

class RefreshExpenses extends ExpenseEvent {
  const RefreshExpenses();
}

class SearchExpenses extends ExpenseEvent {
  final String? query;

  const SearchExpenses({this.query});

  @override
  List<Object?> get props => [query];
}

class DeleteExpense extends ExpenseEvent {
  final int id;

  const DeleteExpense(this.id);

  @override
  List<Object?> get props => [id];
}
