import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final ApiService apiService;

  HistoryBloc(this.apiService) : super(HistoryInitial()) {
    on<FetchLeadHistory>((event, emit) async {
      emit(HistoryLoading());
      try {
        final leadHistory = await apiService.getLeadHistory(event.leadId);
        emit(HistoryLoaded(leadHistory));
      } catch (e) {
        emit(HistoryError('Ошибка при загрузке истории лида'));
      }
    });
  }
}
