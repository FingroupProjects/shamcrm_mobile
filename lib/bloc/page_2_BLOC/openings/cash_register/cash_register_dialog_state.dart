import '../../../../models/page_2/openings/cash_register_openings_model.dart';

abstract class CashRegisterDialogState {}

class CashRegisterDialogInitial extends CashRegisterDialogState {}

class CashRegisterDialogLoading extends CashRegisterDialogState {}

class CashRegisterDialogLoaded extends CashRegisterDialogState {
  final List<CashRegister> cashRegisters;

  CashRegisterDialogLoaded({required this.cashRegisters});
}

class CashRegisterDialogError extends CashRegisterDialogState {
  final String message;

  CashRegisterDialogError({required this.message});
}

