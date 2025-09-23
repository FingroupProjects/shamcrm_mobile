part of 'client_sale_bloc.dart';

sealed class ClientSaleEvent extends Equatable {
  const ClientSaleEvent();

  @override
  List<Object> get props => [];
}

class FetchClientSales extends ClientSaleEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status; // 0 или 1 для таба

  const FetchClientSales({
    this.forceRefresh = false,
    this.filters,
    this.status,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0];
}

class DeleteClientSalesDocument extends ClientSaleEvent {
  final int documentId;

  const DeleteClientSalesDocument(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class CreateClientSalesDocument extends ClientSaleEvent {
  final String date;
  final int storageId;
  final String comment;
  final int counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final int salesFunnelId;
  final bool approve; // Новый параметр

  const CreateClientSalesDocument({
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

class UpdateClientSalesDocument extends ClientSaleEvent {
  final int documentId;
  final String date;
  final int storageId;
  final String comment;
  final int counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final int salesFunnelId;

  const UpdateClientSalesDocument({
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