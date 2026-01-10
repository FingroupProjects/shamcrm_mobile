import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final ApiService apiService;
  bool allEventsFetched = false;

  static const int _perPage = 20;

  EventBloc(this.apiService) : super(EventInitial()) {
    on<FetchEvents>(_onFetchEvents);
    on<FetchMoreEvents>(_onFetchMoreEvents);
    on<CreateNotice>(_createNotice);
    on<UpdateNotice>(_updateNotice);
    on<DeleteNotice>(_deleteNotice);
    on<FinishNotice>(_finishNotice);
  }
Future<void> _onFetchEvents(
    FetchEvents event,
    Emitter<EventState> emit,
  ) async {
    try {
      // Only show loading indicator for initial fetch
      emit(EventLoading(isFirstFetch: true));

      final events = await apiService.getEvents(
        page: 1, 
        perPage: _perPage,
        search: event.query,
        managers: event.managerIds,
        statuses: event.statusIds,
        fromDate: event.fromDate,
        toDate: event.toDate,
        noticefromDate: event.noticefromDate,
        noticetoDate: event.noticetoDate,
        salesFunnelId: event.salesFunnelId, // Передаем новый параметр
      );

      emit(EventDataLoaded(
        events: events,
        currentPage: 1,
        hasReachedEnd: events.length < _perPage,
      ));
    } catch (e) {
      emit(EventError('Не удалось загрузить события: $e'));
    }
  }

  Future<void> _onFetchMoreEvents(
    FetchMoreEvents event,
    Emitter<EventState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is EventDataLoaded) {
        if (currentState.hasReachedEnd) return;

        // Keep existing events visible while loading more
        final nextPage = currentState.currentPage + 1;
        final newEvents = await apiService.getEvents(
          page: nextPage,
          perPage: _perPage,
          search: event.query,
          managers: event.managerIds,
        );

        if (newEvents.isEmpty) {
          emit(currentState.copyWith(hasReachedEnd: true));
          return;
        }

        emit(EventDataLoaded(
          events: [...currentState.events, ...newEvents],
          currentPage: nextPage,
          hasReachedEnd: newEvents.length < _perPage,
        ));
      }
    } catch (e) {
      // Keep existing events visible on error
      if (state is EventDataLoaded) {
        emit(EventError('Ошибка загрузки дополнительных событий: $e'));
      }
    }
  }
Future<void> _createNotice(CreateNotice event, Emitter<EventState> emit) async {
  emit(EventLoading());
  try {
    final result = await apiService.createNotice(
      title: event.title,
      body: event.body,
      leadId: event.leadId,
      date: event.date,
      sendNotification: event.sendNotification,
      users: event.users,
      filePaths: event.filePaths, // Передаем файлы
    );

    if (result['success']) {
      emit(EventSuccess(
          event.localizations.translate('notice_created_successfully')));
      add(FetchEvents());
    } else {
      emit(EventError(event.localizations.translate(result['message'])));
    }
  } catch (e) {
    emit(EventError(event.localizations.translate('error_notice_create')));
  }
}
  Future<void> _updateNotice(
      UpdateNotice event, Emitter<EventState> emit) async {
    emit(EventUpdateLoading());
    try {
      final result = await apiService.updateNotice(
        noticeId: event.noticeId,
        title: event.title,
        body: event.body,
        leadId: event.leadId,
        date: event.date,
        sendNotification: event.sendNotification,
        users: event.users,
        filePaths: event.filePaths, // Передаем новые файлы
      existingFiles: event.existingFiles, // Передаем существующие файлы
      );

      if (result['success']) {
        emit(EventUpdateSuccess(
            event.localizations.translate('')));
        add(FetchEvents());
      } else {
        emit(
            EventUpdateError(event.localizations.translate(result['message'])));
      }
    } catch (e) {
      emit(EventUpdateError(
          event.localizations.translate('error_notice_update')));
    }
  }

  Future<void> _deleteNotice(
      DeleteNotice event, Emitter<EventState> emit) async {
    emit(EventLoading());

    try {
      final response = await apiService.deleteNotice(event.noticeId);
      if (response['result'] == 'Success') {
        emit(EventSuccess(
            event.localizations.translate('notice_deleted_successfully')));
        add(FetchEvents());
      } else {
        emit(EventError(event.localizations.translate('error_delete_notice')));
      }
    } catch (e) {
      emit(EventError(event.localizations.translate('error_delete_notice')));
    }
  }

Future<void> _finishNotice(
    FinishNotice event, Emitter<EventState> emit) async {
  emit(EventLoading());

  try {
    final response = await apiService.finishNotice(event.noticeId, event.conclusion);
    if (response['result'] == 'Success') {
      emit(EventSuccess(
          event.localizations.translate('notice_finished_successfully')));
      add(FetchEvents());
    } else {
      emit(EventError(event.localizations.translate('error_finish_notice')));
    }
  } catch (e) {
    emit(EventError(event.localizations.translate('error_finish_notice')));
  }
}}