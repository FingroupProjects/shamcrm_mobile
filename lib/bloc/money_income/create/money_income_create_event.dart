part of 'money_income_create_bloc.dart';

abstract class MoneyIncomeCreateEvent extends Equatable {
  const MoneyIncomeCreateEvent();
}

class FetchCashRegisters extends MoneyIncomeCreateEvent {
  @override
  List<Object?> get props => [];
}