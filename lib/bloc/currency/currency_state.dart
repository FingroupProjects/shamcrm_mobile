import 'package:crm_task_manager/models/currency_model.dart';
import 'package:equatable/equatable.dart';

abstract class CurrencyState extends Equatable {
  const CurrencyState();

  @override
  List<Object> get props => [];
}

class CurrencyInitial extends CurrencyState {}

class CurrencyLoading extends CurrencyState {}

class CurrencyLoaded extends CurrencyState {
  final List<Currency> currencies;

  const CurrencyLoaded(this.currencies);

  @override
  List<Object> get props => [currencies];
}

class CurrencyError extends CurrencyState {
  final String message;

  const CurrencyError(this.message);

  @override
  List<Object> get props => [message];
}
