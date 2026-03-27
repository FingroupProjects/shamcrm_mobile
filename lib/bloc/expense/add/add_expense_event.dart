part of 'add_expense_bloc.dart';

sealed class AddExpenseEvent extends Equatable {
  const AddExpenseEvent();
}

class SubmitAddExpense extends AddExpenseEvent {
  final AddExpenseModel data;

  const SubmitAddExpense({required this.data});

  @override
  List<Object?> get props => [data];
}
