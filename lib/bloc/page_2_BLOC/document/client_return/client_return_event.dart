part of 'client_return_bloc.dart';

sealed class ClientReturnEvent extends Equatable {
  const ClientReturnEvent();

  @override
  List<Object> get props => [];
}

class FetchClientReturns extends ClientReturnEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status;

  const FetchClientReturns({
    this.forceRefresh = false,
    this.filters,
    this.status,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0];
}

class DeleteClientReturnDocument extends ClientReturnEvent {
  final int documentId;
  final AppLocalizations localizations;
  final bool shouldReload;

  const DeleteClientReturnDocument(this.documentId, this.localizations, {this.shouldReload = true});

  @override
  List<Object> get props => [documentId, localizations, shouldReload];
}

class CreateClientReturnDocument extends ClientReturnEvent {
  final String date;
  final int storageId;
  final String comment;
  final int counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final int salesFunnelId;
  final bool approve;

  const CreateClientReturnDocument({
    required this.date,
    required this.storageId,
    required this.comment,
    required this.counterpartyId,
    required this.documentGoods,
    required this.organizationId,
    required this.salesFunnelId,
    this.approve = false,
  });

  @override
  List<Object> get props => [
        date,
        storageId,
        comment,
        counterpartyId,
        documentGoods,
        organizationId,
        salesFunnelId,
        approve,
      ];
}

class UpdateClientReturnDocument extends ClientReturnEvent {
  final int documentId;
  final String date;
  final int storageId;
  final String comment;
  final int counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final int salesFunnelId;

  const UpdateClientReturnDocument({
    required this.documentId,
    required this.date,
    required this.storageId,
    required this.comment,
    required this.counterpartyId,
    required this.documentGoods,
    required this.organizationId,
    required this.salesFunnelId,
  });

  @override
  List<Object> get props => [
        documentId,
        date,
        storageId,
        comment,
        counterpartyId,
        documentGoods,
        organizationId,
        salesFunnelId
      ];
}

class RestoreClientReturnDocument extends ClientReturnEvent {
  final int documentId;
  final AppLocalizations localizations;

  const RestoreClientReturnDocument(this.documentId, this.localizations);

  @override
  List<Object> get props => [documentId, localizations];
}

// Массовые операции
class MassApproveClientReturnDocuments extends ClientReturnEvent {
  @override
  List<Object> get props => [];
}

class MassDisapproveClientReturnDocuments extends ClientReturnEvent {
  @override
  List<Object> get props => [];
}

class MassDeleteClientReturnDocuments extends ClientReturnEvent {
  @override
  List<Object> get props => [];
}

class MassRestoreClientReturnDocuments extends ClientReturnEvent {
  @override
  List<Object> get props => [];
}

// Выбор документов
class SelectClientReturnDocument extends ClientReturnEvent {
  final IncomingDocument document;

  const SelectClientReturnDocument(this.document);

  @override
  List<Object> get props => [document];
}

class UnselectAllClientReturnDocuments extends ClientReturnEvent {
  @override
  List<Object> get props => [];
}