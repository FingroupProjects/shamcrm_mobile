import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/models/event/event_model.dart';
import 'package:crm_task_manager/screens/event/event_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final ApiService apiService;
  bool allEventsFetched = false;
  bool isFetching = false;
  Map<int, int> _eventCounts = {};
  String? _currentQuery;
  List<int>? _currentManagerIds;
  // Текущий интервал списка: past, today, tomorrow, upcoming.
  String _currentDateType = EventDateType.today;
  int? _currentSalesFunnelId;
  final Map<String, int> _dateTotals = {};
  int _fetchGeneration = 0;
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
    final generation = ++_fetchGeneration;

    final dateType = (event.dateType != null && event.dateType!.isNotEmpty)
        ? event.dateType!
        : _currentDateType;

    debugPrint('🔍 EventBloc: _onFetchEvents - START');
    debugPrint('🔍 EventBloc: dateType=$dateType');
    debugPrint('🔍 EventBloc: salesFunnelId=${event.salesFunnelId}');

    try {
      if (state is! EventDataLoaded) {
        emit(EventLoading(isFirstFetch: true));
      }

      // Сохраняем параметры текущего запроса, чтобы подгрузка страниц
      // оставалась в том же интервале и с теми же фильтрами.
      _currentQuery = event.query;
      _currentManagerIds = event.managerIds;
      _currentDateType = dateType;
      if (event.salesFunnelId != null) {
        _currentSalesFunnelId = event.salesFunnelId;
      }
      _currentFromDate = event.fromDate;
      _currentToDate = event.toDate;
      _currentNoticefromDate = event.noticefromDate;
      _currentNoticetoDate = event.noticetoDate;

      if (await _checkInternetConnection()) {
        debugPrint('📡 EventBloc: Internet available, fetching from API');

        final page = await apiService.getEvents(
          page: 1,
          perPage: _perPage,
          search: event.query,
          managers: event.managerIds,
          dateType: dateType,
          fromDate: event.fromDate,
          toDate: event.toDate,
          noticefromDate: event.noticefromDate,
          noticetoDate: event.noticetoDate,
          salesFunnelId: event.salesFunnelId ?? _currentSalesFunnelId,
        );

        debugPrint(
            '✅ EventBloc: Fetched ${page.events.length}/${page.total} events for $dateType');

        _dateTotals[dateType] = page.total;
        emit(EventDataLoaded(
          events: page.events,
          currentPage: 1,
          hasReachedEnd:
              page.events.length < _perPage || page.events.length >= page.total,
          eventCounts: Map.from(_eventCounts),
          total: page.total,
          dateType: dateType,
          dateTotals: Map.from(_dateTotals),
        ));
      } else {
        debugPrint('❌ EventBloc: No internet connection');
      }

    } catch (e) {
      debugPrint('❌ EventBloc: _onFetchEvents - Error: $e');
      emit(EventError('Не удалось загрузить события: $e'));
    } finally {
      // Не снимаем флаг чужого запроса, если вкладку уже переключили.
      if (_fetchGeneration == generation) {
        isFetching = false;
      }
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

        // Следующая страница того же интервала и тех же фильтров.
        final nextPage = currentState.currentPage + 1;
        final dateType = event.dateType ?? _currentDateType;
        final page = await apiService.getEvents(
          page: nextPage,
          perPage: _perPage,
          search: event.query ?? _currentQuery,
          managers: event.managerIds ?? _currentManagerIds,
          dateType: dateType,
          fromDate: _currentFromDate,
          toDate: _currentToDate,
          noticefromDate: _currentNoticefromDate,
          noticetoDate: _currentNoticetoDate,
          salesFunnelId: _currentSalesFunnelId,
        );

        if (page.events.isEmpty) {
          emit(currentState.copyWith(hasReachedEnd: true));
          return;
        }

        final merged = [...currentState.events, ...page.events];
        emit(currentState.copyWith(
          events: merged,
          currentPage: nextPage,
          hasReachedEnd:
              page.events.length < _perPage || merged.length >= page.total,
          total: page.total,
          dateType: dateType,
          dateTotals: Map.from(_dateTotals),
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
      timeFrom: event.timeFrom,
      timeTo: event.timeTo,
      sendNotification: event.sendNotification,
      sendSms: event.sendSms,
      users: event.users,
      filePaths: event.filePaths, // Передаем файлы
    );

    if (result['success']) {
      emit(EventSuccess(
          event.localizations.translate('notice_created_successfully')));
      add(FetchEvents(dateType: _currentDateType));
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
        timeFrom: event.timeFrom,
        timeTo: event.timeTo,
        sendNotification: event.sendNotification,
        sendSms: event.sendSms,
        users: event.users,
        filePaths: event.filePaths, // Передаем новые файлы
      existingFiles: event.existingFiles, // Передаем существующие файлы
      );

      if (result['success']) {
        emit(EventUpdateSuccess(
            event.localizations.translate('')));
        add(FetchEvents(dateType: _currentDateType));
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
        add(FetchEvents(dateType: _currentDateType));
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
      add(FetchEvents(dateType: _currentDateType));
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
    final generation = ++_fetchGeneration;
    isFetching = true;

    emit(EventLoading(isFirstFetch: true));

    try {
      final dateType = (event.dateType != null && event.dateType!.isNotEmpty)
          ? event.dateType!
          : _currentDateType;

      // Фильтры менеджера и дат накладываются на текущий интервал.
      _currentQuery = null;
      _currentManagerIds = event.managerIds;
      _currentDateType = dateType;
      if (event.salesFunnelId != null) {
        _currentSalesFunnelId = event.salesFunnelId;
      }
      _currentFromDate = event.fromDate;
      _currentToDate = event.toDate;
      _currentNoticefromDate = event.noticefromDate;
      _currentNoticetoDate = event.noticetoDate;

      debugPrint('✅ EventBloc: Filters saved, dateType=$dateType');
      _dateTotals.clear();

      final page = await apiService.getEvents(
        page: 1,
        perPage: _perPage,
        managers: event.managerIds,
        dateType: dateType,
        fromDate: event.fromDate,
        toDate: event.toDate,
        noticefromDate: event.noticefromDate,
        noticetoDate: event.noticetoDate,
        salesFunnelId: event.salesFunnelId ?? _currentSalesFunnelId,
      );

      debugPrint(
          '✅ EventBloc: Loaded ${page.events.length}/${page.total} filtered events');

      _dateTotals[dateType] = page.total;
      emit(EventDataLoaded(
        events: page.events,
        currentPage: 1,
        hasReachedEnd:
            page.events.length < _perPage || page.events.length >= page.total,
        eventCounts: Map.from(_eventCounts),
        total: page.total,
        dateType: dateType,
        dateTotals: Map.from(_dateTotals),
      ));

    } catch (e) {
      debugPrint('❌ EventBloc: _onFetchEventsWithFilters - Error: $e');
      emit(EventError('Не удалось загрузить события с фильтрами: $e'));
    } finally {
      if (_fetchGeneration == generation) {
        isFetching = false;
      }
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
    _currentDateType = EventDateType.today;
    _currentSalesFunnelId = null;
    _dateTotals.clear();
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
