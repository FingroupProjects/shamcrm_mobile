part of 'cash_desk_bloc.dart';

class CashDeskState extends Equatable {
  CashDeskState({
    this.status = CashDeskStatus.initial, // Make it a parameter with default value
    this.cashRegisters,
    this.errorMessage
  });

  final CashDeskStatus status; // Remove the hardcoded assignment
  final List<CashRegisterModel>? cashRegisters;
  final String? errorMessage;

  var message;

  @override
  List<Object?> get props => [status, cashRegisters, errorMessage];

  CashDeskState copyWith({
    CashDeskStatus? status,
    List<CashRegisterModel>? cashRegisters,
    String? errorMessage
  }) {
    return CashDeskState(
      status: status ?? this.status, // Include status in copyWith
      cashRegisters: cashRegisters ?? this.cashRegisters,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}