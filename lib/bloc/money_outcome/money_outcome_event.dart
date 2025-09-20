part of 'money_outcome_bloc.dart';

sealed class MoneyOutcomeEvent extends Equatable {
  const MoneyOutcomeEvent();
}

class FetchMoneyOutcome extends MoneyOutcomeEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final String? search;

  const FetchMoneyOutcome({
    this.forceRefresh = false,
    this.filters,
    this.search,
  });

  @override
  List<Object?> get props => [forceRefresh, filters, search];
}

class UpdateMoneyOutcome extends MoneyOutcomeEvent {
  final int? id;
  final String date;
  final num amount;
  final String operationType;
  final String movementType = "RKO";
  final int? leadId;
  final String comment;
  final String? cashRegisterId;
  final String? senderCashRegisterId;
  final int? supplierId;
  final bool approved;

  UpdateMoneyOutcome({
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

class DeleteMoneyOutcome extends MoneyOutcomeEvent {
  final int documentId;

  const DeleteMoneyOutcome(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class RestoreMoneyOutcome extends MoneyOutcomeEvent {
  final int documentId;

  const RestoreMoneyOutcome(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class AddMoneyOutcome extends MoneyOutcomeEvent {
  @override
  List<Object> get props => [];
}

class CreateMoneyOutcome extends MoneyOutcomeEvent {
  final String date;
  final num amount;
  final String operationType;
  final String movementType = "RKO";
  final int? leadId;
  final String comment;
  final String? cashRegisterId;
  final String? senderCashRegisterId;
  final int? supplierId;

  CreateMoneyOutcome({
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


class FilterMoneyOutcome extends MoneyOutcomeEvent {
  final Map<String, dynamic> filters;

  FilterMoneyOutcome(this.filters);

  @override
  List<Object> get props => [filters];
}