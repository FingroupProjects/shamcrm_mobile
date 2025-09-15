part of 'add_money_references_bloc.dart';

sealed class AddMoneyReferencesEvent extends Equatable {
  const AddMoneyReferencesEvent();
}

class SubmitAddMoneyReference extends AddMoneyReferencesEvent {
  final AddMoneyReferenceModel data;

  const SubmitAddMoneyReference({required this.data});

  @override
  List<Object?> get props => [data];
}