part of 'client_return_bloc.dart';

sealed class ClientReturnEvent extends Equatable {
  const ClientReturnEvent();

  @override
  List<Object> get props => [];
}

class FetchClientReturns extends ClientReturnEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status; // 0 или 1 для таба

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

  const DeleteClientReturnDocument(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class CreateClientReturnDocument extends ClientReturnEvent {
  final String date;
  final int storageId;
  final String comment;
  final int counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final int salesFunnelId;
  final bool approve; // Новый параметр

  const CreateClientReturnDocument({
    required this.date,
    required this.storageId,
    required this.comment,
    required this.counterpartyId,
    required this.documentGoods,
    required this.organizationId,
    required this.salesFunnelId,
    this.approve = false, // По умолчанию false
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
    approve, // Добавляем в props
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
    documentId, date, storageId, comment, counterpartyId,
    documentGoods, organizationId, salesFunnelId
  ];
}