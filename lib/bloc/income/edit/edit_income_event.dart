part of 'edit_income_bloc.dart';

sealed class EditIncomeEvent extends Equatable {
  const EditIncomeEvent();
}

class SubmitEditIncome extends EditIncomeEvent {
  final AddIncomeModel data;
  final int? id;

  const SubmitEditIncome({required this.data, this.id});

  @override
  List<Object?> get props => [data, id];
}
