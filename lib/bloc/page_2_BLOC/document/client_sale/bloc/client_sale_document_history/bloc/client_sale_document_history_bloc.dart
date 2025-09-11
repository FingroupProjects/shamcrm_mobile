import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_history_model.dart';
import 'package:equatable/equatable.dart';

part 'client_sale_document_history_event.dart';
part 'client_sale_document_history_state.dart';

class ClientSaleDocumentHistoryBloc extends Bloc<ClientSaleDocumentHistoryEvent,
    ClientSaleDocumentHistoryState> {
  final ApiService apiService;
  ClientSaleDocumentHistoryBloc(this.apiService)
      : super(ClientSaleDocumentHistoryInitial()) {
    on<FetchClientSaleDocumentHistory>(_onFetchClientSaleDocumentHistory);
  }

  Future<void> _onFetchClientSaleDocumentHistory(
    FetchClientSaleDocumentHistory event,
    Emitter<ClientSaleDocumentHistoryState> emit,
  ) async {
    emit(ClientSaleDocumentHistoryLoading());
    try {
      final response =
          await apiService.getIncomingDocumentHistory(event.documentId);
      emit(ClientSaleDocumentHistoryLoaded(response.history ?? []));
    } catch (e) {
      emit(ClientSaleDocumentHistoryError(e.toString()));
    }
  }
}
