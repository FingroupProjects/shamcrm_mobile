part of 'money_bloc.dart';

abstract class MoneyEvent extends Equatable {
  const MoneyEvent();
}

class LoadInitialData extends MoneyEvent {
  @override
  List<Object?> get props => [];
}