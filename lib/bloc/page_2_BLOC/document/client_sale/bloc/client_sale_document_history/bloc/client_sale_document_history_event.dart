part of 'client_sale_document_history_bloc.dart';

sealed class ClientSaleDocumentHistoryEvent extends Equatable {
  const ClientSaleDocumentHistoryEvent();

  @override
  List<Object> get props => [];
}

final class FetchClientSaleDocumentHistory extends ClientSaleDocumentHistoryEvent {
  final int documentId;

  const FetchClientSaleDocumentHistory(this.documentId);

  @override
  List<Object> get props => [documentId];
}
