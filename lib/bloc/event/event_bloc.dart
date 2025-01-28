import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final ApiService apiService;

  EventBloc(this.apiService) : super(EventInitial()) {
    on<FetchEvents>(_getEvents);
  }

  Future<void> _getEvents(FetchEvents event, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      final events = await apiService.getEvents();
      emit(EventLoaded(events));
    } catch (e) {
      emit(EventError('Не удалось загрузить события: $e'));
    }
  }
}
