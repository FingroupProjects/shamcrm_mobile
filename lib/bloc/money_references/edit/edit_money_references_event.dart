part of 'edit_money_references_bloc.dart';

sealed class EditMoneyReferencesEvent extends Equatable {
  const EditMoneyReferencesEvent();
}

class SubmitEditMoneyReference extends EditMoneyReferencesEvent {
  final AddMoneyReferenceModel data;
  final int? id;

  const SubmitEditMoneyReference({required this.data, this.id});

  @override
  List<Object?> get props => [data, id];
}