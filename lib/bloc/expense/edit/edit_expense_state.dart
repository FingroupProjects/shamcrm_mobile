part of 'edit_expense_bloc.dart';

class EditExpenseState extends Equatable {
  const EditExpenseState({this.message, this.status = EditExpenseStatus.initial});

  final String? message;
  final EditExpenseStatus status;

  @override
  List<Object?> get props => [message, status];
}
