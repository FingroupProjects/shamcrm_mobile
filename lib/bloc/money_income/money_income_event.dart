part of 'money_income_bloc.dart';

sealed class MoneyIncomeEvent extends Equatable {
  const MoneyIncomeEvent();
}

class FetchMoneyIncome extends MoneyIncomeEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final String? search;

  const FetchMoneyIncome({
    this.forceRefresh = false,
    this.filters,
    this.search,
  });

  @override
  List<Object?> get props => [forceRefresh, filters, search];
}

class UpdateMoneyIncome extends MoneyIncomeEvent {
  final int? id;
  final String date;
  final num amount;
  final String operationType;
  final String movementType = "PKO";
  final int? leadId;
  final int? articleId;
  final String comment;
  final String? cashRegisterId;
  final String? senderCashRegisterId;
  final int? supplierId;

  UpdateMoneyIncome({
    this.id,
    required this.date,
    required this.amount,
    this.leadId,
    this.articleId,
    required this.comment,
    required this.operationType,
    this.cashRegisterId,
    this.senderCashRegisterId,
    this.supplierId,
  });

  @override
  List<Object> get props => [
    id ?? 0,
    date,
    amount,
    operationType,
    movementType,
    leadId ?? 0,
    articleId ?? 0,
    comment,
    cashRegisterId ?? '',
    senderCashRegisterId ?? '',
    supplierId ?? 0,
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
  final int? articleId;
  final String comment;
  final String? cashRegisterId;
  final String? senderCashRegisterId;
  final int? supplierId;

  CreateMoneyIncome({
    required this.date,
    required this.amount,
    this.leadId,
    this.articleId,
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
        articleId ?? 0,
        comment,
        cashRegisterId ?? '',
        senderCashRegisterId ?? '',
        supplierId ?? 0,
      ];
}


class MassApproveMoneyIncomeDocuments extends MoneyIncomeEvent {

  @override
  List<Object> get props => [];
}

class MassDisapproveMoneyIncomeDocuments extends MoneyIncomeEvent {

  @override
  List<Object> get props => [];
}

class MassDeleteMoneyIncomeDocuments extends MoneyIncomeEvent {

  @override
  List<Object> get props => [];
}

class MassRestoreMoneyIncomeDocuments extends MoneyIncomeEvent {

  @override
  List<Object> get props => [];
}

class ToggleApproveOneMoneyIncomeDocument extends MoneyIncomeEvent {
  final int documentId;
  final bool approve;

  const ToggleApproveOneMoneyIncomeDocument(this.documentId, this.approve);

  @override
  List<Object> get props => [documentId, approve];
}

class RemoveLocalFromList extends MoneyIncomeEvent {
  final int documentId;

  const RemoveLocalFromList(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class SelectDocument extends MoneyIncomeEvent {
  final Document document;

  const SelectDocument(this.document);

  @override
  List<Object> get props => [document];
}

class UnselectAllDocuments extends MoneyIncomeEvent {
  @override
  List<Object> get props => [];
}