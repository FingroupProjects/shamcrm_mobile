import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/deal/deal_model.dart';
import 'package:crm_task_manager/models/workday/workday_status_model.dart';
import 'package:crm_task_manager/offline/core/offline_module.dart';
import 'package:crm_task_manager/offline/core/offline_runtime.dart';
import 'package:crm_task_manager/offline/core/request_priority.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'deal_event.dart';
import 'deal_state.dart';

class DealBloc extends Bloc<DealEvent, DealState> {
  final ApiService apiService;
  bool allDealsFetched = false;
  bool isFetching = false;
  Map<int, int> _dealCounts = {};
  Map<int, int> get dealCountsSnapshot => Map<int, int>.from(_dealCounts);
  FetchDeals? _activeFetchDealsEvent;
  FetchDeals? _queuedFetchDealsEvent;
  FetchMoreDeals? _queuedFetchMoreDealsEvent;
  int? _currentTabStatusId;
  int? _lastCompletedFetchStatusId;

  int? get lastCompletedFetchStatusId => _lastCompletedFetchStatusId;
  int? get currentTabStatusId => _currentTabStatusId;
  String? _currentQuery;
  List<int>? _currentManagerIds;
  List<int>? _currentRegionsIds;
  int? _currentRegionId;
  List<int>? _currentCityIds;
  List<int>? _currentExecutorIds;
  List<int>? _currentSources;
  int? _currentStatusId;
  DateTime? _currentFromDate;
  DateTime? _currentToDate;
  List<int>? _currentLeadIds;
  bool? _currentHasTasks;
  bool? _currentWithoutNotices;
  bool? _currentOverdueNotices;
  List<int>? _currentLeadStatuses;
  List<int>? _currentReasonForRefusalIds;
  int? _currentDaysWithoutActivity;
  List<Map<String, dynamic>>? _currentDirectoryValues;
  List<String>? _currentNames;
  Map<String, List<String>>? _currentCustomFieldFilters;
  int? currentSalesFunnelId;

  DealBloc(this.apiService) : super(DealInitial()) {
    on<FetchDealStatuses>(_fetchDealStatuses);
    on<FetchDealStatusesWithFilters>(_fetchDealStatusesWithFilters);
    on<FetchDeals>(_fetchDeals);
    on<CreateDeal>(_createDeal);
    on<FetchMoreDeals>(_fetchMoreDeals);
    on<CreateDealStatus>(_createDealStatus);
    on<UpdateDeal>(_updateDeal);
    on<DeleteDeal>(_deleteDeal);
    on<DeleteDealStatuses>(_deleteDealStatuses);
    on<UpdateDealStatusEdit>(_updateDealStatusEdit);
    on<FetchDealStatus>(_fetchDealStatus);
    on<DealCreatedFromSocket>(_onDealCreatedFromSocket);
  }

  bool _isWorkdayAccessError(Object error) => error is WorkdayAccessException;

  bool get _hasActiveFilters {
    final bool listsOrQuery = (_currentQuery != null &&
            _currentQuery!.isNotEmpty) ||
        (_currentManagerIds != null && _currentManagerIds!.isNotEmpty) ||
        (_currentRegionsIds != null && _currentRegionsIds!.isNotEmpty) ||
        (_currentRegionId != null) ||
        (_currentCityIds != null && _currentCityIds!.isNotEmpty) ||
        (_currentExecutorIds != null && _currentExecutorIds!.isNotEmpty) ||
        (_currentSources != null && _currentSources!.isNotEmpty) ||
        (_currentLeadIds != null && _currentLeadIds!.isNotEmpty) ||
        (_currentLeadStatuses != null && _currentLeadStatuses!.isNotEmpty) ||
        (_currentReasonForRefusalIds != null &&
            _currentReasonForRefusalIds!.isNotEmpty) ||
        (_currentDirectoryValues != null &&
            _currentDirectoryValues!.isNotEmpty) ||
        (_currentCustomFieldFilters != null &&
            _currentCustomFieldFilters!.isNotEmpty) ||
        (_currentNames != null && _currentNames!.isNotEmpty);

    final bool flagsOrDates = (_currentStatusId != null) ||
        (_currentFromDate != null) ||
        (_currentToDate != null) ||
        (_currentHasTasks == true) ||
        (_currentWithoutNotices == true) ||
        (_currentOverdueNotices == true) ||
        (_currentDaysWithoutActivity != null);

    return listsOrQuery || flagsOrDates;
  }

  bool _sameFetchDealsRequest(FetchDeals? a, FetchDeals? b) {
    if (a == null || b == null) return false;

    return a.statusId == b.statusId &&
        a.query == b.query &&
        listEquals(a.managerIds, b.managerIds) &&
        listEquals(a.regionsIds, b.regionsIds) &&
        a.regionId == b.regionId &&
        listEquals(a.cityIds, b.cityIds) &&
        listEquals(a.executorIds, b.executorIds) &&
        listEquals(a.sources, b.sources) &&
        listEquals(a.leadIds, b.leadIds) &&
        a.statusIds == b.statusIds &&
        a.fromDate == b.fromDate &&
        a.toDate == b.toDate &&
        a.daysWithoutActivity == b.daysWithoutActivity &&
        a.hasTasks == b.hasTasks &&
        a.withoutNotices == b.withoutNotices &&
        a.overdueNotices == b.overdueNotices &&
        listEquals(a.leadStatuses, b.leadStatuses) &&
        listEquals(a.reasonForRefusalIds, b.reasonForRefusalIds) &&
        a.salesFunnelId == b.salesFunnelId &&
        listEquals(a.names, b.names) &&
        listEquals(a.directoryValues, b.directoryValues) &&
        mapEquals(a.customFieldFilters, b.customFieldFilters);
  }

  Future<void> _fetchDealStatus(
      FetchDealStatus event, Emitter<DealState> emit) async {
    emit(DealLoading());
    try {
      final dealStatus = await apiService.getDealStatus(event.dealStatusId);
      emit(DealStatusLoaded(dealStatus));
    } catch (e) {
      emit(DealError('Failed to fetch deal status: ${e.toString()}'));
    }
  }

  Future<void> _fetchDeals(FetchDeals event, Emitter<DealState> emit) async {
    if (isFetching) {
      if (_sameFetchDealsRequest(_activeFetchDealsEvent, event) ||
          _sameFetchDealsRequest(_queuedFetchDealsEvent, event)) {
        debugPrint(
            '⏭️ DealBloc: _fetchDeals - Duplicate request ignored for status ${event.statusId}');
        return;
      }

      debugPrint(
          '⚠️ DealBloc: _fetchDeals - Already fetching, queueing latest request for status ${event.statusId}');
      _queuedFetchDealsEvent = event;
      return;
    }

    isFetching = true;
    _activeFetchDealsEvent = event;
    _queuedFetchDealsEvent = null;

    debugPrint('🔍 DealBloc: _fetchDeals - START');
    debugPrint('🔍 DealBloc: statusId=${event.statusId}');
    debugPrint('🔍 DealBloc: salesFunnelId=${event.salesFunnelId}');

    try {
      // Сохраняем параметры текущего запроса
      _currentTabStatusId = event.statusId;
      _currentQuery = event.query;
      _currentManagerIds = event.managerIds;
      _currentRegionsIds = event.regionsIds;
      _currentRegionId = event.regionId;
      _currentCityIds = event.cityIds;
      _currentExecutorIds = event.executorIds;
      _currentSources = event.sources;
      _currentStatusId = event.statusIds;
      _currentFromDate = event.fromDate;
      _currentToDate = event.toDate;
      _currentLeadIds = event.leadIds;
      _currentHasTasks = event.hasTasks;
      _currentWithoutNotices = event.withoutNotices;
      _currentOverdueNotices = event.overdueNotices;
      _currentLeadStatuses = event.leadStatuses;
      _currentReasonForRefusalIds = event.reasonForRefusalIds;
      _currentDaysWithoutActivity = event.daysWithoutActivity;
      _currentDirectoryValues = event.directoryValues;
      _currentNames = event.names;
      _currentCustomFieldFilters = event.customFieldFilters;

      // Восстанавливаем постоянные счетчики только для отсутствующих статусов.
      // Нельзя безусловно перезаписывать _dealCounts, иначе свежие значения
      // из FetchDealStatuses будут затираться старыми числами из persistent cache.
      final allPersistentCounts = await DealCache.getPersistentDealCounts();
      for (String statusIdStr in allPersistentCounts.keys) {
        int statusId = int.parse(statusIdStr);
        int count = allPersistentCounts[statusIdStr] ?? 0;
        _dealCounts.putIfAbsent(statusId, () => count);
      }

      debugPrint('✅ DealBloc: Restored persistent counts: $_dealCounts');

      List<Deal> deals = [];

      // Попытка загрузить из кэша
      deals = await DealCache.getDealsForStatus(event.statusId);
      if (deals.isNotEmpty) {
        debugPrint(
            '✅ DealBloc: _fetchDeals - Emitting ${deals.length} cached deals for status ${event.statusId}');
        emit(DealDataLoaded(deals,
            currentPage: 1,
            dealCounts: Map.from(_dealCounts),
            isLoadingMore: false));
        _lastCompletedFetchStatusId = event.statusId;
      } else {
        final currentState = state;
        final bool showsRequestedStatus = currentState is DealDataLoaded &&
            currentState.deals.any((deal) => deal.statusId == event.statusId);

        if (!showsRequestedStatus) {
          debugPrint(
              '⏳ DealBloc: _fetchDeals - No cache for status ${event.statusId}, showing loader');
          emit(DealLoading());
        }
      }

      if (await _checkInternetConnection()) {
        debugPrint('📡 DealBloc: Internet available, fetching from API');

        deals = await apiService.getDeals(
          event.statusId,
          page: 1,
          perPage: 20,
          search: event.query,
          managers: event.managerIds,
          regions: event.regionsIds,
          regionId: event.regionId,
          cityIds: event.cityIds,
          executorIds: event.executorIds,
          sources: event.sources,
          statuses: event.statusIds,
          fromDate: event.fromDate,
          toDate: event.toDate,
          leads: event.leadIds,
          hasTasks: event.hasTasks,
          withoutNotices: event.withoutNotices,
          overdueNotices: event.overdueNotices,
          leadStatuses: event.leadStatuses,
          reasonForRefusalIds: event.reasonForRefusalIds,
          daysWithoutActivity: event.daysWithoutActivity,
          directoryValues: event.directoryValues,
          names: event.names,
          salesFunnelId: event.salesFunnelId,
          customFieldFilters: event.customFieldFilters,
        );

        debugPrint(
            '✅ DealBloc: Fetched ${deals.length} deals from API for status ${event.statusId}');

        // КЛЮЧЕВОЙ МОМЕНТ: Берём реальный счётчик из _dealCounts
        final int? realTotalCount = _dealCounts[event.statusId];

        debugPrint(
            '🔍 DealBloc: Real total count for status ${event.statusId}: $realTotalCount');

        // Кэшируем сделки с РЕАЛЬНЫМ общим счётчиком
        await DealCache.cacheDealsForStatus(
          event.statusId,
          deals,
          updatePersistentCount: true,
          actualTotalCount: realTotalCount,
        );

        debugPrint(
            '✅ DealBloc: Cached ${deals.length} deals for status ${event.statusId}');
      } else {
        debugPrint('❌ DealBloc: No internet connection');
      }

      allDealsFetched = deals.isEmpty;

      debugPrint(
          '✅ DealBloc: _fetchDeals - Emitting DealDataLoaded with ${deals.length} deals');
      debugPrint('✅ DealBloc: Final dealCounts: $_dealCounts');

      emit(DealDataLoaded(deals,
          currentPage: 1,
          dealCounts: Map.from(_dealCounts),
          isLoadingMore: false));
      _lastCompletedFetchStatusId = event.statusId;
    } catch (e) {
      if (_isWorkdayAccessError(e)) {
        return;
      }
      debugPrint('❌ DealBloc: _fetchDeals - Error: $e');
      emit(DealError('Не удалось загрузить данные!'));
    } finally {
      isFetching = false;
      _activeFetchDealsEvent = null;
      debugPrint('🏁 DealBloc: _fetchDeals - FINISHED');

      final queuedFetchDeals = _queuedFetchDealsEvent;
      _queuedFetchDealsEvent = null;

      if (queuedFetchDeals != null) {
        debugPrint(
            '🔁 DealBloc: _fetchDeals - Running queued FetchDeals for status ${queuedFetchDeals.statusId}');
        add(queuedFetchDeals);
        return;
      }

      final queuedFetchMoreDeals = _queuedFetchMoreDealsEvent;
      _queuedFetchMoreDealsEvent = null;

      if (queuedFetchMoreDeals != null) {
        debugPrint(
            '🔁 DealBloc: _fetchDeals - Running queued FetchMoreDeals for status ${queuedFetchMoreDeals.statusId}, page ${queuedFetchMoreDeals.currentPage}');
        add(queuedFetchMoreDeals);
      }
    }
  }

  Future<void> _fetchDealStatuses(
      FetchDealStatuses event, Emitter<DealState> emit) async {
    emit(DealLoading());

    try {
      List<DealStatus> response;
      final previousTabStatusId = _currentTabStatusId;

      // При forceRefresh = true делаем РАДИКАЛЬНУЮ перезагрузку
      if (event.forceRefresh) {
        if (!await _checkInternetConnection()) {
          emit(DealError('Нет подключения к интернету для обновления данных'));
          return;
        }

        // РАДИКАЛЬНАЯ очистка всех локальных данных блока
        _dealCounts.clear();
        allDealsFetched = false;
        isFetching = false;

        // Сбрасываем все параметры фильтрации
        _currentQuery = null;
        _currentManagerIds = null;
        _currentRegionsIds = null;
        _currentRegionId = null;
        _currentCityIds = null;
        _currentExecutorIds = null;
        _currentSources = null;
        _currentStatusId = null;
        _currentFromDate = null;
        _currentToDate = null;
        _currentLeadIds = null;
        _currentHasTasks = null;
        _currentWithoutNotices = null;
        _currentOverdueNotices = null;
        _currentLeadStatuses = null;
        _currentReasonForRefusalIds = null;
        _currentDaysWithoutActivity = null;
        _currentDirectoryValues = null;
        _currentNames = null;
        _currentCustomFieldFilters = null;

        // Загружаем статусы с сервера
        currentSalesFunnelId = event.salesFunnelId;
        response = await apiService.getDealStatuses(
            salesFunnelId: event.salesFunnelId, bypassCache: true);

        // КРИТИЧНО: Проверяем, не переключил ли пользователь воронку, пока мы ждали ответа
        if (event.salesFunnelId != currentSalesFunnelId) {
          debugPrint(
              '⚠️ DealBloc: _fetchDealStatuses (forceRefresh) - Funnel changed, ignoring result');
          return;
        }

        // ПОЛНОСТЬЮ перезаписываем кэш новыми данными
        await DealCache.clearEverything();
        await DealCache.cacheDealStatuses(response
            .map((status) => {
                  'id': status.id,
                  'title': status.title,
                  'deals_count': status.dealsCount ?? 0,
                  'is_unassembled': status.isUnassembled,
                })
            .toList());

        // Устанавливаем новые счетчики ТОЛЬКО из свежих данных API
        for (var status in response) {
          final count = status.dealsCount ?? 0;
          _dealCounts[status.id] = count;
          await DealCache.setPersistentDealCount(status.id, count);
        }
      } else {
        // Стандартная логика для обычной загрузки
        if (!await _checkInternetConnection()) {
          final cachedStatuses = await DealCache.getDealStatuses();
          if (cachedStatuses.isNotEmpty) {
            // Восстанавливаем счетчики из кэша
            _dealCounts.clear();
            final allPersistentCounts =
                await DealCache.getPersistentDealCounts();
            for (String statusIdStr in allPersistentCounts.keys) {
              int statusId = int.parse(statusIdStr);
              int count = allPersistentCounts[statusIdStr] ?? 0;
              _dealCounts[statusId] = count;
            }

            // Создаём минимальные DealStatus объекты для отображения
            final List<DealStatus> minimalStatuses =
                cachedStatuses.map((status) {
              final statusId = status['id'] as int;
              final count = _dealCounts[statusId] ?? 0;
              return DealStatus(
                id: statusId,
                title: status['title'] as String,
                color: '#000000',
                dealsCount: count,
                isSuccess: false,
                isFailure: false,
                isUnassembled: status['is_unassembled'] == true,
                showOnMainPage: false,
              );
            }).toList();

            emit(
                DealLoaded(minimalStatuses, dealCounts: Map.from(_dealCounts)));
          } else {
            emit(DealError(
                'Нет подключения к интернету и нет кэшированных данных'));
          }
          return;
        }

        // ВСЕГДА загружаем с API для получения актуальных счётчиков
        currentSalesFunnelId = event.salesFunnelId;
        response = await apiService.getDealStatuses(
            salesFunnelId: event.salesFunnelId, bypassCache: true);

        // КРИТИЧНО: Проверяем, не переключил ли пользователь воронку, пока мы ждали ответа
        if (event.salesFunnelId != currentSalesFunnelId) {
          debugPrint(
              '⚠️ DealBloc: _fetchDealStatuses - Funnel changed, ignoring result');
          return;
        }

        if (response.isEmpty) {
          debugPrint("DealBloc: API returned empty statuses array");
          emit(DealLoaded([], dealCounts: {}));
          return;
        }

        await DealCache.cacheDealStatuses(response
            .map((status) => {
                  'id': status.id,
                  'title': status.title,
                  'deals_count': status.dealsCount ?? 0,
                  'is_unassembled': status.isUnassembled,
                })
            .toList());

        // Устанавливаем счетчики из свежих данных API
        _dealCounts.clear();
        for (var status in response) {
          final count = status.dealsCount ?? 0;
          _dealCounts[status.id] = count;
          await DealCache.setPersistentDealCount(status.id, count);
        }
      }

      emit(DealLoaded(response, dealCounts: Map.from(_dealCounts)));

      if (response.isNotEmpty && !_hasActiveFilters) {
        final targetStatusId =
            response.any((status) => status.id == previousTabStatusId)
                ? previousTabStatusId!
                : response.first.id;
        _currentTabStatusId = targetStatusId;
        add(FetchDeals(
          targetStatusId,
          salesFunnelId: event.salesFunnelId,
        ));
      }
    } catch (e) {
      if (_isWorkdayAccessError(e)) {
        return;
      }
      debugPrint('❌ DealBloc: _fetchDealStatuses - Error: $e');
      emit(DealError('Не удалось загрузить статусы: $e'));
    }
  }

  Future<void> _onDealCreatedFromSocket(
    DealCreatedFromSocket event,
    Emitter<DealState> emit,
  ) async {
    if (event.hasActiveFilters) {
      if (event.activeStatusId != null) {
        add(FetchDeals(
          event.activeStatusId!,
          query: _currentQuery,
          managerIds: _currentManagerIds,
          regionsIds: _currentRegionsIds,
          regionId: _currentRegionId,
          cityIds: _currentCityIds,
          executorIds: _currentExecutorIds,
          sources: _currentSources,
          leadIds: _currentLeadIds,
          statusIds: _currentStatusId,
          fromDate: _currentFromDate,
          toDate: _currentToDate,
          daysWithoutActivity: _currentDaysWithoutActivity,
          hasTasks: _currentHasTasks,
          withoutNotices: _currentWithoutNotices,
          overdueNotices: _currentOverdueNotices,
          leadStatuses: _currentLeadStatuses,
          reasonForRefusalIds: _currentReasonForRefusalIds,
          salesFunnelId: currentSalesFunnelId,
          directoryValues: _currentDirectoryValues,
          names: _currentNames,
          customFieldFilters: _currentCustomFieldFilters,
        ));
      }
      return;
    }

    final newCount = (_dealCounts[event.deal.statusId] ?? 0) + 1;
    _dealCounts[event.deal.statusId] = newCount;

    await DealCache.incrementDealCount(event.deal.statusId);
    await DealCache.insertOrUpdateDealForStatus(
        event.deal.statusId, event.deal);

    if (state is DealLoaded) {
      final currentState = state as DealLoaded;
      emit(currentState.copyWith(dealCounts: Map<int, int>.from(_dealCounts)));
      return;
    }

    if (state is DealDataLoaded) {
      final currentState = state as DealDataLoaded;
      final updatedDeals = List<Deal>.from(currentState.deals)
        ..removeWhere((deal) => deal.id == event.deal.id);

      if (event.activeStatusId == event.deal.statusId) {
        updatedDeals.insert(0, event.deal);
      }

      emit(currentState.copyWith(
        deals: updatedDeals,
        currentPage: 1,
        dealCounts: Map<int, int>.from(_dealCounts),
      ));
    }
  }

  Future<void> _fetchMoreDeals(
      FetchMoreDeals event, Emitter<DealState> emit) async {
    if (allDealsFetched) return;

    if (isFetching) {
      debugPrint(
          '⚠️ DealBloc: _fetchMoreDeals - Already fetching, queueing request for status ${event.statusId}, page ${event.currentPage}');
      _queuedFetchMoreDealsEvent = event;
      return;
    }

    isFetching = true;
    _queuedFetchMoreDealsEvent = null;

    if (!await _checkInternetConnection()) {
      isFetching = false;
      emit(DealError('Нет подключения к интернету'));
      return;
    }

    try {
      if (state is DealDataLoaded) {
        final currentState = state as DealDataLoaded;
        if (!currentState.isLoadingMore) {
          emit(currentState.copyWith(isLoadingMore: true));
        }
      }

      final pageStatusId = _currentTabStatusId ?? event.statusId;
      final statusFilterForNextPage = _hasActiveFilters ? pageStatusId : null;

      final deals = await apiService.getDeals(
        statusFilterForNextPage == null ? pageStatusId : null,
        page: event.currentPage + 1,
        perPage: 20,
        search: _currentQuery,
        managers: _currentManagerIds,
        regions: _currentRegionsIds,
        regionId: _currentRegionId,
        cityIds: _currentCityIds,
        executorIds: _currentExecutorIds,
        sources: _currentSources,
        statuses: statusFilterForNextPage,
        fromDate: _currentFromDate,
        toDate: _currentToDate,
        leads: _currentLeadIds,
        hasTasks: _currentHasTasks,
        withoutNotices: _currentWithoutNotices,
        overdueNotices: _currentOverdueNotices,
        leadStatuses: _currentLeadStatuses,
        reasonForRefusalIds: _currentReasonForRefusalIds,
        daysWithoutActivity: _currentDaysWithoutActivity,
        directoryValues: _currentDirectoryValues,
        names: _currentNames,
        salesFunnelId: currentSalesFunnelId,
        customFieldFilters: _currentCustomFieldFilters,
      );

      if (deals.isEmpty) {
        allDealsFetched = true;
        if (state is DealDataLoaded) {
          final currentState = state as DealDataLoaded;
          emit(currentState.copyWith(isLoadingMore: false));
        }
        return;
      }

      if (state is DealDataLoaded) {
        final currentState = state as DealDataLoaded;
        emit(currentState.merge(deals));
      }
    } catch (e) {
      emit(DealError('Не удалось загрузить дополнительные сделки!'));
    } finally {
      isFetching = false;

      final queuedFetchDeals = _queuedFetchDealsEvent;
      _queuedFetchDealsEvent = null;

      if (queuedFetchDeals != null) {
        debugPrint(
            '🔁 DealBloc: _fetchMoreDeals - Running queued FetchDeals for status ${queuedFetchDeals.statusId}');
        add(queuedFetchDeals);
        return;
      }

      final queuedFetchMoreDeals = _queuedFetchMoreDealsEvent;
      _queuedFetchMoreDealsEvent = null;

      if (queuedFetchMoreDeals != null) {
        debugPrint(
            '🔁 DealBloc: _fetchMoreDeals - Running queued FetchMoreDeals for status ${queuedFetchMoreDeals.statusId}, page ${queuedFetchMoreDeals.currentPage}');
        add(queuedFetchMoreDeals);
      }
    }
  }

  Future<void> _createDealStatus(
      CreateDealStatus event, Emitter<DealState> emit) async {
    emit(DealLoading());

    if (!await _checkInternetConnection()) {
      emit(DealError(event.localizations.translate('no_internet_connection')));
      return;
    }

    try {
      final result = await apiService.createDealStatus(
        event.title,
        event.color,
        event.day,
        event.notificationMessage,
        event.showOnMainPage,
        event.isSuccess,
        event.isFailure,
        event.isUnassembled,
        event.userIds,
        event.changeStatusUserIds, // ✅ НОВОЕ
      );

      if (result['success']) {
        emit(DealSuccess(result['message']));
        add(FetchDealStatuses());
      } else {
        emit(DealError(result['message']));
      }
    } catch (e) {
      emit(
          DealError(event.localizations.translate('error_delete_status_deal')));
    }
  }

  Future<void> _createDeal(CreateDeal event, Emitter<DealState> emit) async {
    emit(DealLoading());
    if (!await _checkInternetConnection()) {
      if (event.files != null && event.files!.isNotEmpty) {
        emit(DealError(
            'Офлайн-очередь для вложений будет доведена в phase 2. Сейчас офлайн поддерживаются только текстовые операции.'));
        return;
      }
      await OfflineRuntime.instance.outboxService.enqueue(
        id: 'deal_create_${DateTime.now().millisecondsSinceEpoch}',
        module: OfflineModule.deal,
        entityType: 'deal',
        entityId: 'local_${DateTime.now().millisecondsSinceEpoch}',
        operationType: 'create',
        payload: {
          'name': event.name,
          'dealStatusId': event.dealStatusId,
          'managerId': event.managerId,
          'startDate': event.startDate?.toIso8601String(),
          'endDate': event.endDate?.toIso8601String(),
          'sum': event.sum,
          'description': event.description,
          'dealtypeId': event.dealtypeId,
          'leadId': event.leadId,
          'customFields': event.customFields,
          'directoryValues': event.directoryValues,
          'userIds': event.userIds,
        },
        idempotencyKey: 'deal-create-${DateTime.now().millisecondsSinceEpoch}',
        priority: RequestPriority.high,
      );
      emit(DealSuccess(
          'Сделка принята локально и поставлена в outbox для синхронизации.'));
      return;
    }
    try {
      final result = await apiService.createDeal(
        name: event.name,
        dealStatusId: event.dealStatusId,
        managerId: event.managerId,
        startDate: event.startDate,
        endDate: event.endDate,
        sum: event.sum,
        description: event.description,
        dealtypeId: event.dealtypeId,
        leadId: event.leadId,
        customFields: event.customFields,
        directoryValues: event.directoryValues,
        files: event.files,
        userIds: event.userIds,
      );
      if (result['success']) {
        emit(DealSuccess(
            event.localizations.translate('deal_created_successfully')));
      } else {
        emit(DealError(event.localizations.translate(result['message'])));
      }
    } catch (e) {
      emit(DealError(
          event.localizations.translate('error_deal_create_successfully')));
    }
  }

  Future<void> _updateDeal(UpdateDeal event, Emitter<DealState> emit) async {
    emit(DealLoading());

    if (!await _checkInternetConnection()) {
      if (event.files != null && event.files!.isNotEmpty) {
        emit(DealError(
            'Офлайн-очередь для вложений будет доведена в phase 2. Сейчас офлайн поддерживаются только текстовые операции.'));
        return;
      }
      await OfflineRuntime.instance.outboxService.enqueue(
        id: 'deal_update_${event.dealId}_${DateTime.now().millisecondsSinceEpoch}',
        module: OfflineModule.deal,
        entityType: 'deal',
        entityId: event.dealId.toString(),
        operationType: 'update',
        payload: {
          'dealId': event.dealId,
          'name': event.name,
          'dealStatusId': event.dealStatusId,
          'managerId': event.managerId,
          'startDate': event.startDate?.toIso8601String(),
          'endDate': event.endDate?.toIso8601String(),
          'sum': event.sum,
          'description': event.description,
          'dealtypeId': event.dealtypeId,
          'leadId': event.leadId,
          'customFields': event.customFields,
          'directoryValues': event.directoryValues,
          'dealStatusIds': event.dealStatusIds,
          'existingFiles': event.existingFiles,
          'userIds': event.userIds,
          'reasonForRefusalId': event.reasonForRefusalId,
          'reasonForRefusal': event.reasonForRefusal,
        },
        idempotencyKey:
            'deal-update-${event.dealId}-${DateTime.now().millisecondsSinceEpoch}',
        priority: RequestPriority.high,
      );
      emit(DealSuccess(
          'Изменения сделки приняты локально и поставлены в очередь.'));
      return;
    }

    try {
      final result = await apiService.updateDeal(
        dealId: event.dealId,
        name: event.name,
        dealStatusId: event.dealStatusId,
        managerId: event.managerId,
        startDate: event.startDate,
        endDate: event.endDate,
        sum: event.sum ?? '',
        description: event.description,
        dealtypeId: event.dealtypeId,
        leadId: event.leadId,
        customFields: event.customFields,
        directoryValues: event.directoryValues,
        files: event.files,
        dealStatusIds: event.dealStatusIds,
        existingFiles: event.existingFiles,
        userIds: event.userIds, // ✅ НОВОЕ: передаем userIds
        reasonForRefusalId: event.reasonForRefusalId,
        reasonForRefusal: event.reasonForRefusal,
      );

      if (result['success']) {
        emit(DealSuccess(
            event.localizations.translate('deal_updated_successfully')));
      } else {
        emit(DealError(result['message']));
      }
    } catch (e) {
      emit(DealError(event.localizations.translate('error_deal_update')));
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _deleteDeal(DeleteDeal event, Emitter<DealState> emit) async {
    emit(DealLoading());

    try {
      final response = await apiService.deleteDeal(event.dealId);
      if (response['result'] == 'Success') {
        emit(DealDeleted(
            event.localizations.translate('deal_delete_successfully')));
      } else {
        emit(DealError(event.localizations.translate('error_delete_deal')));
      }
    } catch (e) {
      emit(DealError(event.localizations.translate('error_delete_deal')));
    }
  }

  Future<void> _deleteDealStatuses(
      DeleteDealStatuses event, Emitter<DealState> emit) async {
    emit(DealLoading());

    try {
      if (event.dealStatusId == 0) {
        emit(DealError('Некорректный статус для удаления'));
        return;
      }

      final response = await apiService.deleteDealStatuses(event.dealStatusId);
      if (response['result'] == 'Success') {
        emit(DealDeleted(
            event.localizations.translate('status_deal_delete_successfully')));
      } else {
        emit(DealError(
            event.localizations.translate('error_status_deal_delete')));
      }
    } catch (e) {
      emit(
          DealError(event.localizations.translate('error_status_deal_delete')));
    }
  }

  Future<void> _updateDealStatusEdit(
      UpdateDealStatusEdit event, Emitter<DealState> emit) async {
    emit(DealLoading());

    try {
      final response = await apiService.updateDealStatusEdit(
        event.dealStatusId,
        event.title,
        event.day,
        event.isSuccess,
        event.isFailure,
        event.isUnassembled,
        event.notificationMessage,
        event.showOnMainPage,
        event.userIds,
        event.changeStatusUserIds,
      );

      if (response['result'] == 'Success') {
        emit(DealStatusUpdatedEdit(
            event.localizations.translate('status_updated_successfully')));
      } else {
        emit(DealError(event.localizations.translate('error_update_status')));
      }
    } catch (e) {
      emit(DealError(event.localizations.translate('error_update_status')));
    }
  }

  // ======================== ФИЛЬТРАЦИЯ СО СТАТУСАМИ ========================

  Future<void> _fetchDealStatusesWithFilters(
    FetchDealStatusesWithFilters event,
    Emitter<DealState> emit,
  ) async {
    debugPrint('🔍 DealBloc: _fetchDealStatusesWithFilters - START');
    debugPrint(
        '🔍 DealBloc: requested funnel=${event.salesFunnelId}, statusIds=${event.statusIds}, managerIds=${event.managerIds}, preferredStatusId=${event.preferredStatusId}');

    emit(DealLoading());

    try {
      final requestedFunnelId = event.salesFunnelId;
      currentSalesFunnelId = requestedFunnelId;
      debugPrint(
          '🧭 DealBloc: currentSalesFunnelId updated to $currentSalesFunnelId before filtered request');

      debugPrint(
          '🧹 DealBloc: clearing in-memory state before filtered statuses request');
      _dealCounts.clear();
      allDealsFetched = false;
      isFetching = false;

      // 1. Получаем ВСЕ статусы (метод getDealStatuses не поддерживает фильтры)
      // Фильтры применяются только при загрузке сделок
      final statuses = await apiService.getDealStatuses(
        salesFunnelId: event.salesFunnelId,
        managers: event.managerIds,
        regions: event.regionsIds,
        regionId: event.regionId,
        cityIds: event.cityIds,
        executorIds: event.executorIds,
        sources: event.sources,
        leads: event.leadIds,
        statuses: event.statusIds,
        fromDate: event.fromDate,
        toDate: event.toDate,
        daysWithoutActivity: event.daysWithoutActivity,
        hasTasks: event.hasTasks,
        withoutNotices: event.withoutNotices,
        overdueNotices: event.overdueNotices,
        leadStatuses: event.leadStatuses,
        reasonForRefusalIds: event.reasonForRefusalIds,
        directoryValues: event.directoryValues,
        names: event.names,
        bypassCache: true,
      );

      // КРИТИЧНО: Проверяем, не переключил ли пользователь воронку, пока мы ждали ответа
      if (requestedFunnelId != currentSalesFunnelId) {
        debugPrint(
            '⚠️ DealBloc: _fetchDealStatusesWithFilters - Funnel changed during request, ignoring stale result. requested=$requestedFunnelId current=$currentSalesFunnelId');
        return;
      }

      debugPrint('✅ DealBloc: Got ${statuses.length} statuses');
      debugPrint(
          '✅ DealBloc: filtered status ids=${statuses.map((e) => e.id).toList()}');

      // 2. Обновляем счётчики только в памяти.
      // Фильтрованные значения нельзя сохранять в persistent cache,
      // иначе после очистки фильтра останутся неверные counts.
      _dealCounts.clear();
      for (var status in statuses) {
        final count = status.dealsCount ?? 0;
        _dealCounts[status.id] = count;
      }

      // 3. Эмитим состояние со статусами
      emit(DealLoaded(statuses, dealCounts: Map.from(_dealCounts)));

      // 4. СОХРАНЯЕМ ФИЛЬТРЫ В БЛОКЕ
      if (statuses.isNotEmpty) {
        // Сохраняем фильтры для последующих запросов
        _currentQuery = null;
        _currentManagerIds = event.managerIds;
        _currentRegionsIds = event.regionsIds;
        _currentRegionId = event.regionId;
        _currentCityIds = event.cityIds;
        _currentExecutorIds = event.executorIds;
        _currentSources = event.sources;
        _currentLeadIds = event.leadIds;
        _currentStatusId = event.statusIds;
        _currentFromDate = event.fromDate;
        _currentToDate = event.toDate;
        _currentHasTasks = event.hasTasks;
        _currentWithoutNotices = event.withoutNotices;
        _currentOverdueNotices = event.overdueNotices;
        _currentLeadStatuses = event.leadStatuses;
        _currentReasonForRefusalIds = event.reasonForRefusalIds;
        _currentDaysWithoutActivity = event.daysWithoutActivity;
        _currentDirectoryValues = event.directoryValues;
        _currentNames = event.names;
        _currentCustomFieldFilters = event.customFieldFilters;

        final DealStatus targetStatus = statuses.firstWhere(
          (status) => status.id == event.preferredStatusId,
          orElse: () => statuses.first,
        );

        debugPrint('✅ DealBloc: Filters saved to bloc state');
        _currentTabStatusId = targetStatus.id;

        debugPrint(
            '🎯 DealBloc: target status after filtered statuses request = ${targetStatus.id}');

        await _fetchDealsForStatusWithFilters(
          targetStatus.id,
          event.managerIds,
          event.regionsIds,
          event.regionId,
          event.cityIds,
          event.executorIds,
          event.sources,
          event.leadIds,
          event.statusIds,
          event.fromDate,
          event.toDate,
          event.hasTasks,
          event.withoutNotices,
          event.overdueNotices,
          event.daysWithoutActivity,
          event.leadStatuses,
          event.reasonForRefusalIds,
          event.directoryValues,
          event.names,
          event.salesFunnelId,
          event.customFieldFilters,
        );

        final targetDeals = await DealCache.getDealsForStatus(targetStatus.id);
        debugPrint(
            '✅ DealBloc: Target status deals loaded and emitted for status ${targetStatus.id}, count=${targetDeals.length}');

        emit(DealDataLoaded(targetDeals,
            currentPage: 1, dealCounts: Map.from(_dealCounts)));
      }
    } catch (e) {
      debugPrint('❌ DealBloc: _fetchDealStatusesWithFilters - Error: $e');
      emit(DealError('Не удалось загрузить статусы с фильтрами: $e'));
    }
  }

  // Вспомогательный метод для загрузки сделок одного статуса
  Future<void> _fetchDealsForStatusWithFilters(
    int statusId,
    List<int>? managerIds,
    List<int>? regionsIds,
    int? regionId,
    List<int>? cityIds,
    List<int>? executorIds,
    List<int>? sources,
    List<int>? leadIds,
    int? statusIds,
    DateTime? fromDate,
    DateTime? toDate,
    bool? hasTasks,
    bool? withoutNotices,
    bool? overdueNotices,
    int? daysWithoutActivity,
    List<int>? leadStatuses,
    List<int>? reasonForRefusalIds,
    List<Map<String, dynamic>>? directoryValues,
    List<String>? names,
    int? salesFunnelId,
    Map<String, List<String>>? customFieldFilters,
  ) async {
    try {
      if (!await _checkInternetConnection()) {
        debugPrint('⚠️ DealBloc: No internet for status $statusId');
        return;
      }

      debugPrint(
          '🔍 DealBloc: _fetchDealsForStatusWithFilters for status $statusId');

      final deals = await apiService.getDeals(
        null, // dealStatusId = null, используем statuses параметр
        page: 1,
        perPage: 20,
        managers: managerIds,
        regions: regionsIds,
        regionId: regionId,
        cityIds: cityIds,
        executorIds: executorIds,
        sources: sources,
        leads: leadIds,
        statuses: statusId, // ID статуса через параметр statuses
        fromDate: fromDate,
        toDate: toDate,
        hasTasks: hasTasks,
        withoutNotices: withoutNotices,
        overdueNotices: overdueNotices,
        leadStatuses: leadStatuses,
        reasonForRefusalIds: reasonForRefusalIds,
        daysWithoutActivity: daysWithoutActivity,
        directoryValues: directoryValues,
        names: names,
        salesFunnelId: salesFunnelId,
        customFieldFilters: customFieldFilters,
      );

      debugPrint(
          '✅ DealBloc: Fetched ${deals.length} deals for status $statusId WITH FILTERS');

      // Кэшируем с сохранением реального счётчика
      final realCount = _dealCounts[statusId];
      await DealCache.cacheDealsForStatus(
        statusId,
        deals,
        updatePersistentCount: true,
        actualTotalCount: realCount,
      );
    } catch (e) {
      debugPrint('❌ DealBloc: Error fetching deals for status $statusId: $e');
    }
  }

  // ======================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ========================

  /// РАДИКАЛЬНАЯ очистка - удаляет ВСЕ данные и сбрасывает состояние блока
  Future<void> clearAllCountsAndCache() async {
    debugPrint('🧹 DealBloc.clearAllCountsAndCache: START');

    // Очищаем локальные переменные блока
    _dealCounts.clear();
    allDealsFetched = false;
    isFetching = false;
    _activeFetchDealsEvent = null;
    _queuedFetchDealsEvent = null;
    _queuedFetchMoreDealsEvent = null;
    currentSalesFunnelId = null;
    _currentTabStatusId = null;

    // Сбрасываем все текущие параметры фильтрации
    _currentQuery = null;
    _currentManagerIds = null;
    _currentRegionsIds = null;
    _currentSources = null;
    _currentStatusId = null;
    _currentFromDate = null;
    _currentToDate = null;
    _currentLeadIds = null;
    _currentHasTasks = null;
    _currentWithoutNotices = null;
    _currentOverdueNotices = null;
    _currentLeadStatuses = null;
    _currentDaysWithoutActivity = null;
    _currentDirectoryValues = null;
    _currentNames = null;
    _currentCustomFieldFilters = null;

    // Радикальная очистка кэша
    await DealCache.clearEverything();
    debugPrint('🧹 DealBloc.clearAllCountsAndCache: FINISHED');
  }

  /// Дополнительный метод для принудительного сброса всех счетчиков
  Future<void> resetAllCounters() async {
    _dealCounts.clear();
    await DealCache.clearPersistentCounts();
  }

  /// Вызывать перед переходом между табами
  Future<void> _preserveCurrentCounts() async {
    if (_dealCounts.isNotEmpty) {
      for (int statusId in _dealCounts.keys) {
        int currentCount = _dealCounts[statusId] ?? 0;
        await DealCache.setPersistentDealCount(statusId, currentCount);
      }
    }
  }

  /// Метод для восстановления всех счетчиков из постоянного кэша
  Future<void> _restoreAllCounts() async {
    final allPersistentCounts = await DealCache.getPersistentDealCounts();
    _dealCounts.clear();

    for (String statusIdStr in allPersistentCounts.keys) {
      int statusId = int.parse(statusIdStr);
      int count = allPersistentCounts[statusIdStr] ?? 0;
      _dealCounts[statusId] = count;
    }
  }
}
