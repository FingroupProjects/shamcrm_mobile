import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'deal_history_event.dart';
import 'deal_history_state.dart';

class DealHistoryBloc extends Bloc<DealHistoryEvent, DealHistoryState> {
  final ApiService apiService;

  DealHistoryBloc(this.apiService) : super(DealHistoryInitial()) {
    on<FetchDealHistory>((event, emit) async {
      emit(DealHistoryLoading());
      try {
        final dealHistory = await apiService.getDealHistory(event.dealId);
        emit(DealHistoryLoaded(dealHistory));
      } catch (e) {
        emit(DealHistoryError('Ошибка при загрузке истории сделки'));
      }
    });
  }
}
