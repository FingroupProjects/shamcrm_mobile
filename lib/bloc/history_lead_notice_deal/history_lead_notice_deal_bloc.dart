import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_event.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryLeadsBloc extends Bloc<HistoryEvent, HistoryState> {
  final ApiService apiService;

  HistoryLeadsBloc(this.apiService) : super(HistoryInitial()) {
    on<FetchLeadHistory>(_onFetchLeadHistory);
    on<FetchNoticeHistory>(_onFetchNoticeHistory);
    on<FetchDealHistory>(_onFetchDealHistory);
  }

  Future<void> _onFetchLeadHistory(
    FetchLeadHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final history = await apiService.getLeadHistory(event.leadId);
      emit(LeadHistoryLoaded(history));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> _onFetchNoticeHistory(
    FetchNoticeHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final history = await apiService.getNoticeHistory(event.leadId);
      emit(NoticeHistoryLoaded(history));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

    Future<void> _onFetchDealHistory(
    FetchDealHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final history = await apiService.getDealHistoryLead(event.leadId);
      emit(DealHistoryLoaded(history));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
}