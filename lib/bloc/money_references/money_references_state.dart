part of 'money_references_bloc.dart';

class MoneyReferencesState extends Equatable {
  MoneyReferencesState({
    this.status = MoneyReferencesStatus.initial, // Make it a parameter with default value
    this.cashRegisters,
    this.errorMessage
  });

  final MoneyReferencesStatus status; // Remove the hardcoded assignment
  final List<CashRegisterModel>? cashRegisters;
  final String? errorMessage;

  var message;

  @override
  List<Object?> get props => [status, cashRegisters, errorMessage];

  MoneyReferencesState copyWith({
    MoneyReferencesStatus? status,
    List<CashRegisterModel>? cashRegisters,
    String? errorMessage
  }) {
    return MoneyReferencesState(
      status: status ?? this.status, // Include status in copyWith
      cashRegisters: cashRegisters ?? this.cashRegisters,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}