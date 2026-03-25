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
  final int? articleId;
  final String comment;
  final int? cashRegisterId;
  final int? senderCashRegisterId;
  final int? supplierId;
  final int? employeeId;
  final String? month;
  final double? exchangeRate;

  UpdateMoneyOutcome({
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
    this.employeeId,
    this.month,
    this.exchangeRate,
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
        employeeId ?? 0,
        month ?? '',
        exchangeRate ?? -1,
      ];
}

class DeleteMoneyOutcome extends MoneyOutcomeEvent {
  final Document document;

  const DeleteMoneyOutcome(this.document);

  @override
  List<Object> get props => [document];
}

class RestoreMoneyOutcome extends MoneyOutcomeEvent {
  final int documentId;

  const RestoreMoneyOutcome(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class CreateMoneyOutcome extends MoneyOutcomeEvent {
  final String date;
  final num amount;
  final String operationType;
  final String movementType = "RKO";
  final int? leadId;
  final int? articleId;
  final String comment;
  final int? cashRegisterId;
  final int? senderCashRegisterId;
  final int? supplierId;
  final int? employeeId;
  final String? month;
  final bool approve;
  final double? exchangeRate;

  CreateMoneyOutcome({
    required this.date,
    required this.amount,
    this.leadId,
    this.articleId,
    required this.comment,
    required this.operationType,
    this.cashRegisterId,
    this.senderCashRegisterId,
    this.supplierId,
    this.employeeId,
    this.month,
    required this.approve,
    this.exchangeRate,
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
        employeeId ?? 0,
        month ?? '',
        approve,
        exchangeRate ?? -1,
      ];
}

class MassApproveMoneyOutcomeDocuments extends MoneyOutcomeEvent {
  @override
  List<Object> get props => [];
}

class MassDisapproveMoneyOutcomeDocuments extends MoneyOutcomeEvent {
  @override
  List<Object> get props => [];
}

class MassDeleteMoneyOutcomeDocuments extends MoneyOutcomeEvent {
  @override
  List<Object> get props => [];
}

class MassRestoreMoneyOutcomeDocuments extends MoneyOutcomeEvent {
  @override
  List<Object> get props => [];
}

class ToggleApproveOneMoneyOutcomeDocument extends MoneyOutcomeEvent {
  final int documentId;
  final bool approve;

  const ToggleApproveOneMoneyOutcomeDocument(this.documentId, this.approve);

  @override
  List<Object> get props => [documentId, approve];
}

class UpdateThenToggleOneMoneyOutcomeDocument extends MoneyOutcomeEvent {
  final int id;
  final String date;
  final num amount;
  final String operationType;
  final String movementType = "RKO";
  final int? leadId;
  final int? articleId;
  final String comment;
  final int? cashRegisterId;
  final int? senderCashRegisterId;
  final int? supplierId;
  final int? employeeId;
  final String? month;
  final bool approve;
  final double? exchangeRate;

  UpdateThenToggleOneMoneyOutcomeDocument({
    required this.id,
    required this.date,
    required this.amount,
    this.leadId,
    this.articleId,
    required this.comment,
    required this.operationType,
    this.cashRegisterId,
    this.senderCashRegisterId,
    this.supplierId,
    this.employeeId,
    this.month,
    required this.approve,
    this.exchangeRate,
  });

  @override
  List<Object> get props => [
        id,
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
        employeeId ?? 0,
        month ?? '',
        approve,
        exchangeRate ?? -1,
      ];
}

class RemoveLocalFromList extends MoneyOutcomeEvent {
  final int documentId;

  const RemoveLocalFromList(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class SelectDocument extends MoneyOutcomeEvent {
  final Document document;

  const SelectDocument(this.document);

  @override
  List<Object> get props => [document];
}

class UnselectAllDocuments extends MoneyOutcomeEvent {
  @override
  List<Object> get props => [];
}
