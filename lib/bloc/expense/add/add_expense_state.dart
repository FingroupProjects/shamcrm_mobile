part of 'add_expense_bloc.dart';

class AddExpenseState extends Equatable {
  const AddExpenseState({this.message, this.status = AddExpenseStatus.initial});

  final String? message;
  final AddExpenseStatus status;

  @override
  List<Object?> get props => [message, status];
}

class AddExpenseInitial extends AddExpenseState {}
