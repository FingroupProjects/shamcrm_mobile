part of 'add_income_bloc.dart';

sealed class AddIncomeEvent extends Equatable {
  const AddIncomeEvent();
}

class SubmitAddIncome extends AddIncomeEvent {
  final AddIncomeModel data;

  const SubmitAddIncome({required this.data});

  @override
  List<Object?> get props => [data];
}
