part of 'edit_money_references_bloc.dart';

class EditMoneyReferencesState extends Equatable {
  const EditMoneyReferencesState({this.message, this.status = EditMoneyReferencesStatus.initial});

  final String? message;
  final EditMoneyReferencesStatus status;

  @override
  List<Object?> get props => [message, status];
}

final class AddMoneyReferencesInitial extends EditMoneyReferencesState {
  @override
  List<Object> get props => [];
}
