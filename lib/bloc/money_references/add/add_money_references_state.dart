part of 'add_money_references_bloc.dart';

class AddMoneyReferencesState extends Equatable {
  const AddMoneyReferencesState(
      {this.message, this.status = AddMoneyReferencesStatus.initial});

  final String? message;
  final AddMoneyReferencesStatus status;

  @override
  List<Object?> get props => [message, status];
}

final class AddMoneyReferencesInitial extends AddMoneyReferencesState {
  @override
  List<Object> get props => [];
}
