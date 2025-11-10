import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_history_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class IncomingDocumentHistoryEvent {}

class FetchIncomingDocumentHistory extends IncomingDocumentHistoryEvent {
  final int documentId;

  FetchIncomingDocumentHistory(this.documentId);
}

// States
abstract class IncomingDocumentHistoryState {}

class IncomingDocumentHistoryInitial extends IncomingDocumentHistoryState {}

class IncomingDocumentHistoryLoading extends IncomingDocumentHistoryState {}

class IncomingDocumentHistoryLoaded extends IncomingDocumentHistoryState {
  final List<IncomingDocumentHistory> history;

  IncomingDocumentHistoryLoaded(this.history);
}

class IncomingDocumentHistoryError extends IncomingDocumentHistoryState {
  final String message;

  IncomingDocumentHistoryError(this.message);
}

// BLoC
class IncomingDocumentHistoryBloc
    extends Bloc<IncomingDocumentHistoryEvent, IncomingDocumentHistoryState> {
  final ApiService apiService;

  IncomingDocumentHistoryBloc(this.apiService) : super(IncomingDocumentHistoryInitial()) {
    on<FetchIncomingDocumentHistory>(_onFetchHistory);
  }

  Future<void> _onFetchHistory(
    FetchIncomingDocumentHistory event,
    Emitter<IncomingDocumentHistoryState> emit,
  ) async {
    emit(IncomingDocumentHistoryLoading());
    try {
      final response = await apiService.getIncomingDocumentHistory(event.documentId);
      emit(IncomingDocumentHistoryLoaded(response.history ?? []));
    } catch (e) {
      emit(IncomingDocumentHistoryError(e.toString()));
    }
  }
}