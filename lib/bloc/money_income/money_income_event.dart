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
  final int? id;
  final String date;
  final num amount;
  final String operationType;
  final String movementType = "PKO";
  final int? leadId;
  final String comment;
  final String? cashRegisterId;
  final String? senderCashRegisterId;
  final int? supplierId;
  final bool approved;

  UpdateMoneyIncome({
    this.id,
    required this.date,
    required this.amount,
    this.leadId,
    required this.comment,
    required this.operationType,
    this.cashRegisterId,
    this.senderCashRegisterId,
    this.supplierId,
    required this.approved,
  });

  @override
  List<Object> get props => [
    id ?? 0,
    date,
    amount,
    operationType,
    movementType,
    leadId ?? 0,
    comment,
    cashRegisterId ?? '',
    senderCashRegisterId ?? '',
    supplierId ?? 0,
    approved,
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
  final int? leadId;
  final String comment;
  final String? cashRegisterId;
  final String? senderCashRegisterId;
  final int? supplierId;

  CreateMoneyIncome({
    required this.date,
    required this.amount,
    this.leadId,
    required this.comment,
    required this.operationType,
    this.cashRegisterId,
    this.senderCashRegisterId,
    this.supplierId,
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
        supplierId ?? 0,
      ];
}
