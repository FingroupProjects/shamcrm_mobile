import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/models/event_model.dart';
import 'package:crm_task_manager/screens/event/event_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final ApiService apiService;
  bool allEventsFetched = false;
  bool isFetching = false;
  Map<int, int> _eventCounts = {}; // 1 = активные, 2 = завершённые
  String? _currentQuery;
  List<int>? _currentManagerIds;
  int? _currentStatusIds;
  DateTime? _currentFromDate;
  DateTime? _currentToDate;
  DateTime? _currentNoticefromDate;
  DateTime? _currentNoticetoDate;

  static const int _perPage = 20;

  EventBloc(this.apiService) : super(EventInitial()) {
    on<FetchEvents>(_onFetchEvents);
    on<FetchEventsWithFilters>(_onFetchEventsWithFilters);
    on<FetchMoreEvents>(_onFetchMoreEvents);
    on<CreateNotice>(_createNotice);
    on<UpdateNotice>(_updateNotice);
    on<DeleteNotice>(_deleteNotice);
    on<FinishNotice>(_finishNotice);
  }

  bool get _hasActiveFilters {
    final bool listsOrQuery =
        (_currentQuery != null && _currentQuery!.isNotEmpty) ||
        (_currentManagerIds != null && _currentManagerIds!.isNotEmpty);

    final bool flagsOrDates =
        (_currentStatusIds != null) ||
        (_currentFromDate != null) ||
        (_currentToDate != null) ||
        (_currentNoticefromDate != null) ||
        (_currentNoticetoDate != null);

    return listsOrQuery || flagsOrDates;
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
Future<void> _onFetchEvents(
    FetchEvents event,
    Emitter<EventState> emit,
  ) async {
    if (isFetching) {
      debugPrint('⚠️ EventBloc: _onFetchEvents - Already fetching, skipping');
      return;
    }

    isFetching = true;

    debugPrint('🔍 EventBloc: _onFetchEvents - START');
    debugPrint('🔍 EventBloc: statusIds=${event.statusIds}');
    debugPrint('🔍 EventBloc: salesFunnelId=${event.salesFunnelId}');

    try {
      if (state is! EventDataLoaded) {
        emit(EventLoading(isFirstFetch: true));
      }

      // Сохраняем параметры текущего запроса
      _currentQuery = event.query;
      _currentManagerIds = event.managerIds;
      _currentStatusIds = event.statusIds;
      _currentFromDate = event.fromDate;
      _currentToDate = event.toDate;
      _currentNoticefromDate = event.noticefromDate;
      _currentNoticetoDate = event.noticetoDate;

      // КРИТИЧНО: Восстанавливаем ВСЕ постоянные счетчики
      final allPersistentCounts = await EventCache.getPersistentEventCounts();
      for (String statusIdStr in allPersistentCounts.keys) {
        int statusId = int.parse(statusIdStr);
        int count = allPersistentCounts[statusIdStr] ?? 0;
        _eventCounts[statusId] = count;
      }

      debugPrint('✅ EventBloc: Restored persistent counts: $_eventCounts');

      List<NoticeEvent> events = [];

      if (await _checkInternetConnection()) {
        debugPrint('📡 EventBloc: Internet available, fetching from API');

        events = await apiService.getEvents(
          page: 1, 
          perPage: _perPage,
          search: event.query,
          managers: event.managerIds,
          statuses: event.statusIds,
          fromDate: event.fromDate,
          toDate: event.toDate,
          noticefromDate: event.noticefromDate,
          noticetoDate: event.noticetoDate,
          salesFunnelId: event.salesFunnelId,
        );

        debugPrint('✅ EventBloc: Fetched ${events.length} events from API for status ${event.statusIds}');

        // Сохраняем счётчик
        if (event.statusIds != null) {
          _eventCounts[event.statusIds!] = events.length;
          await EventCache.setPersistentEventCount(event.statusIds!, events.length);
        }

        emit(EventDataLoaded(
          events: events,
          currentPage: 1,
          hasReachedEnd: events.length < _perPage,
          eventCounts: Map.from(_eventCounts),
        ));
      } else {
        debugPrint('❌ EventBloc: No internet connection');
      }

    } catch (e) {
      debugPrint('❌ EventBloc: _onFetchEvents - Error: $e');
      emit(EventError('Не удалось загрузить события: $e'));
    } finally {
      isFetching = false;
      debugPrint('🏁 EventBloc: _onFetchEvents - FINISHED');
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
}

  // ======================== ФИЛЬТРАЦИЯ С ПОДСЧЁТОМ СОБЫТИЙ ========================
  
  Future<void> _onFetchEventsWithFilters(
    FetchEventsWithFilters event,
    Emitter<EventState> emit,
  ) async {
    debugPrint('🔍 EventBloc: _onFetchEventsWithFilters - START');

    emit(EventLoading(isFirstFetch: true));

    try {
      // Сохраняем фильтры
      _currentQuery = null;
      _currentManagerIds = event.managerIds;
      _currentStatusIds = event.statusIds;
      _currentFromDate = event.fromDate;
      _currentToDate = event.toDate;
      _currentNoticefromDate = event.noticefromDate;
      _currentNoticetoDate = event.noticetoDate;

      debugPrint('✅ EventBloc: Filters saved to bloc state');

      // Загружаем события для активных (statusIds = 1)
      final activeEvents = await apiService.getEvents(
        page: 1,
        perPage: _perPage,
        managers: event.managerIds,
        statuses: 1, // Активные
        fromDate: event.fromDate,
        toDate: event.toDate,
        noticefromDate: event.noticefromDate,
        noticetoDate: event.noticetoDate,
        salesFunnelId: event.salesFunnelId,
      );

      // Загружаем события для завершённых (statusIds = 2)
      final completedEvents = await apiService.getEvents(
        page: 1,
        perPage: _perPage,
        managers: event.managerIds,
        statuses: 2, // Завершённые
        fromDate: event.fromDate,
        toDate: event.toDate,
        noticefromDate: event.noticefromDate,
        noticetoDate: event.noticetoDate,
        salesFunnelId: event.salesFunnelId,
      );

      // Обновляем счётчики
      _eventCounts[1] = activeEvents.length;
      _eventCounts[2] = completedEvents.length;
      
      await EventCache.setPersistentEventCount(1, activeEvents.length);
      await EventCache.setPersistentEventCount(2, completedEvents.length);

      debugPrint('✅ EventBloc: Loaded ${activeEvents.length} active and ${completedEvents.length} completed events');

      // Эмитим состояние с событиями для текущего таба (по умолчанию активные)
      final currentStatusId = event.statusIds ?? 1;
      final currentEvents = currentStatusId == 1 ? activeEvents : completedEvents;

      emit(EventDataLoaded(
        events: currentEvents,
        currentPage: 1,
        hasReachedEnd: currentEvents.length < _perPage,
        eventCounts: Map.from(_eventCounts),
      ));

    } catch (e) {
      debugPrint('❌ EventBloc: _onFetchEventsWithFilters - Error: $e');
      emit(EventError('Не удалось загрузить события с фильтрами: $e'));
    }
  }

  // ======================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ========================
  
  /// РАДИКАЛЬНАЯ очистка - удаляет ВСЕ данные и сбрасывает состояние блока
  Future<void> clearAllCountsAndCache() async {
    _eventCounts.clear();
    allEventsFetched = false;
    isFetching = false;
    
    _currentQuery = null;
    _currentManagerIds = null;
    _currentStatusIds = null;
    _currentFromDate = null;
    _currentToDate = null;
    _currentNoticefromDate = null;
    _currentNoticetoDate = null;
    
    await EventCache.clearEverything();
  }

  /// Дополнительный метод для принудительного сброса всех счетчиков
  Future<void> resetAllCounters() async {
    _eventCounts.clear();
    await EventCache.clearPersistentCounts();
  }
}