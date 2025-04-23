import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarBlocEvent, CalendarBlocState> {
  final ApiService apiService;

  CalendarBloc(this.apiService) : super(CalendarInitial()) {
    on<FetchCalendarEvents>(_onFetchCalendarEvents);
  }

  Future<void> _onFetchCalendarEvents(
    FetchCalendarEvents event,
    Emitter<CalendarBlocState> emit,
  ) async {
    emit(CalendarLoading());
    try {
      final events = await apiService.getCalendarEventsByMonth(event.month);
      emit(CalendarLoaded(events, DateTime(event.year, event.month, 4)));
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }
}