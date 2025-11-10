part of 'money_bloc.dart';

sealed class MoneyState extends Equatable {
  const MoneyState();
}

final class MoneyInitial extends MoneyState {
  @override
  List<Object> get props => [];
}
