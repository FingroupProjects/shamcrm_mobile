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
  final bool shouldReload;

  const DeleteClientReturnDocument(this.documentId, {this.shouldReload = true});

  @override
  List<Object> get props => [documentId, shouldReload];
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