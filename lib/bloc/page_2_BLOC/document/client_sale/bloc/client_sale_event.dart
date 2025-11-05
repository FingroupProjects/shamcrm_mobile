part of 'client_sale_bloc.dart';

sealed class ClientSaleEvent extends Equatable {
  const ClientSaleEvent();

  @override
  List<Object> get props => [];
}

class FetchClientSales extends ClientSaleEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status;
  final String? search;

  const FetchClientSales({
    this.forceRefresh = false,
    this.filters,
    this.status,
    this.search,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0, search ?? ''];
}

class DeleteClientSale extends ClientSaleEvent {
  final int documentId;
  final AppLocalizations localizations;
  final bool shouldReload;

  const DeleteClientSale(this.documentId, this.localizations, {this.shouldReload = true});

  @override
  List<Object> get props => [documentId, localizations];
}

class RestoreClientSale extends ClientSaleEvent {
  final int documentId;
  final AppLocalizations localizations;

  const RestoreClientSale(this.documentId, this.localizations);

  @override
  List<Object> get props => [documentId, localizations];
}

class CreateClientSalesDocument extends ClientSaleEvent {
  final String date;
  final int storageId;
  final String comment;
  final int counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final int salesFunnelId;
  final bool approve;

  const CreateClientSalesDocument({
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
  List<Object> get props => [documentId, date, storageId, comment, counterpartyId, documentGoods, organizationId, salesFunnelId];
}

class MassApproveClientSaleDocuments extends ClientSaleEvent {
  @override
  List<Object> get props => [];
}

class MassDisapproveClientSaleDocuments extends ClientSaleEvent {
  @override
  List<Object> get props => [];
}

class MassDeleteClientSaleDocuments extends ClientSaleEvent {
  @override
  List<Object> get props => [];
}

class MassRestoreClientSaleDocuments extends ClientSaleEvent {
  @override
  List<Object> get props => [];
}

class SelectDocument extends ClientSaleEvent {
  final ExpenseDocument document;

  const SelectDocument(this.document);

  @override
  List<Object> get props => [document];
}

class UnselectAllDocuments extends ClientSaleEvent {
  @override
  List<Object> get props => [];
}
