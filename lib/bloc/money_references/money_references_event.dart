part of 'money_references_bloc.dart';

sealed class MoneyReferencesEvent extends Equatable {
  const MoneyReferencesEvent();
}

class FetchCashRegisters extends MoneyReferencesEvent {
  const FetchCashRegisters();

  @override
  List<Object?> get props => [];
}
