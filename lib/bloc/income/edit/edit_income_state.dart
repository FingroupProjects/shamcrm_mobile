part of 'edit_income_bloc.dart';

class EditIncomeState extends Equatable {
  const EditIncomeState({this.message, this.status = EditIncomeStatus.initial});

  final String? message;
  final EditIncomeStatus status;

  @override
  List<Object?> get props => [message, status];
}
