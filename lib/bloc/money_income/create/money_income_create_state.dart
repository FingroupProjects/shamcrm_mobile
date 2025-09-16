part of 'money_income_create_bloc.dart';

class MoneyIncomeCreateState extends Equatable {
  const MoneyIncomeCreateState({
    this.status = MoneyIncomeCreateStatus.initial,
    this.cashRegisters = const [],
    this.errorMessage = '',
  });

  final MoneyIncomeCreateStatus status ;
  final List<CashRegisterModel> cashRegisters ;
  final String errorMessage;

  @override
  List<Object?> get props => [];

  MoneyIncomeCreateState copyWith({
    MoneyIncomeCreateStatus? status,
    List<CashRegisterModel>? cashRegisters,
    String? errorMessage,
  }) {
    return MoneyIncomeCreateState();
  }
}