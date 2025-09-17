part of 'money_income_bloc.dart';

sealed class MoneyIncomeEvent extends Equatable {
  const MoneyIncomeEvent();
}

class FetchMoneyIncome extends MoneyIncomeEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;

  const FetchMoneyIncome({
    this.forceRefresh = false,
    this.filters,
  });

  @override
  List<Object?> get props => [forceRefresh, filters];
}

class UpdateMoneyIncome extends MoneyIncomeEvent {
  final String date;
  final num amount;
  final String operationType;
  final String movementType = "PKO";
  int? leadId;
  final String comment;
  String? cashRegisterId;
  String? senderCashRegisterId;

  UpdateMoneyIncome({
    required this.date,
    required this.amount,
    this.leadId,
    required this.comment,
    required this.operationType,
    this.cashRegisterId,
    this.senderCashRegisterId,
  });

  @override
  List<Object> get props => [
    date,
    amount,
    operationType,
    movementType,
    leadId ?? 0,
    comment,
    cashRegisterId ?? '',
    senderCashRegisterId ?? '',
  ];
}

class DeleteMoneyIncome extends MoneyIncomeEvent {
  final int documentId;

  const DeleteMoneyIncome(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class RestoreMoneyIncome extends MoneyIncomeEvent {
  final int documentId;

  const RestoreMoneyIncome(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class AddMoneyIncome extends MoneyIncomeEvent {
  @override
  List<Object> get props => [];
}

class CreateMoneyIncome extends MoneyIncomeEvent {
  final String date;
  final num amount;
  final String operationType;
  final String movementType = "PKO";
  int? leadId;
  final String comment;
  String? cashRegisterId;
  String? senderCashRegisterId;

  CreateMoneyIncome({
    required this.date,
    required this.amount,
    this.leadId,
    required this.comment,
    required this.operationType,
    this.cashRegisterId,
    this.senderCashRegisterId,
  });

  @override
  List<Object> get props => [
        date,
        amount,
        operationType,
        movementType,
        leadId ?? 0,
        comment,
        cashRegisterId ?? '',
        senderCashRegisterId ?? '',
      ];
}
