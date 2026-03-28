part of 'add_income_bloc.dart';

class AddIncomeState extends Equatable {
  const AddIncomeState({this.message, this.status = AddIncomeStatus.initial});

  final String? message;
  final AddIncomeStatus status;

  @override
  List<Object?> get props => [message, status];
}

class AddIncomeInitial extends AddIncomeState {}
