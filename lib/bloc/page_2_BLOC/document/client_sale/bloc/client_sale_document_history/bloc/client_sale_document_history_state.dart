part of 'client_sale_document_history_bloc.dart';

sealed class ClientSaleDocumentHistoryState extends Equatable {
  const ClientSaleDocumentHistoryState();

  @override
  List<Object> get props => [];
}

final class ClientSaleDocumentHistoryInitial
    extends ClientSaleDocumentHistoryState {}

final class ClientSaleDocumentHistoryLoading
    extends ClientSaleDocumentHistoryState {}

final class ClientSaleDocumentHistoryLoaded
    extends ClientSaleDocumentHistoryState {
  final List<IncomingDocumentHistory> history;

  const ClientSaleDocumentHistoryLoaded(this.history);

  @override
  List<Object> get props => [history];
}

final class ClientSaleDocumentHistoryError
    extends ClientSaleDocumentHistoryState {
  final String message;

  const ClientSaleDocumentHistoryError(this.message);

  @override
  List<Object> get props => [message];
}
