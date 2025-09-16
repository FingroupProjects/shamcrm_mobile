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
  final int documentId;
  final DateTime date;
  final int? storageId;
  final String? comment;
  final int? counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int? organizationId;
  final int? salesFunnelId;
  final double amount;
  final String? description;

  const UpdateMoneyIncome({
    required this.documentId,
    required this.date,
    this.storageId,
    this.comment,
    this.counterpartyId,
    required this.documentGoods,
    this.organizationId,
    this.salesFunnelId,
    required this.amount,
    this.description,
  });

  @override
  List<Object?> get props => [
    documentId,
    date,
    storageId,
    comment,
    counterpartyId,
    documentGoods,
    organizationId,
    salesFunnelId,
    amount,
    description,
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
  final int leadId;
  final String comment;

  CreateMoneyIncome({
    required this.date,
    required this.amount,
    required this.leadId,
    required this.comment,
    required this.operationType,
  });

  @override
  List<Object> get props => [
        date,
        amount,
        operationType,
        movementType,
        leadId,
        comment,
      ];
}
