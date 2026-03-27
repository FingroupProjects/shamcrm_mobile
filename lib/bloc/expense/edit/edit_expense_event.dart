part of 'edit_expense_bloc.dart';

sealed class EditExpenseEvent extends Equatable {
  const EditExpenseEvent();
}

class SubmitEditExpense extends EditExpenseEvent {
  final AddExpenseModel data;
  final int? id;

  const SubmitEditExpense({required this.data, this.id});

  @override
  List<Object?> get props => [data, id];
}
