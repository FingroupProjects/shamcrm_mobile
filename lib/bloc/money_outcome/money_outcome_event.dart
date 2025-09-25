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

class DeleteMoneyOutcome extends MoneyOutcomeEvent {
  final Document document;
  final bool reload;

  const DeleteMoneyOutcome(this.document, {this.reload = true});

  @override
  List<Object> get props => [document];
}
//
// class RestoreMoneyOutcome extends MoneyOutcomeEvent {
//   final int documentId;
//
//   const RestoreMoneyOutcome(this.documentId);
//
//   @override
//   List<Object> get props => [documentId];
// }

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
  final bool approve;

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
    required this.approve,
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
    approve,
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