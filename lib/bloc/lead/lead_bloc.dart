import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/common/api_exception_model.dart';
import 'package:crm_task_manager/models/lead/lead_model.dart';
import 'package:crm_task_manager/models/workday/workday_status_model.dart';
import 'package:crm_task_manager/offline/core/offline_module.dart';
import 'package:crm_task_manager/offline/core/offline_runtime.dart';
import 'package:crm_task_manager/offline/core/request_priority.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:flutter/cupertino.dart' show debugPrint;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'lead_event.dart';
import 'lead_state.dart';

class LeadBloc extends Bloc<LeadEvent, LeadState> {
  final ApiService apiService;
  bool allLeadsFetched = false;
  Map<int, int> _leadCounts = {};
  String? _currentQuery;
  List<int>? _currentManagerIds;
  List<int>? _currentRegionIds;
  int? _currentRegionId;
  List<int>? _currentCityIds;
  List<int>? _currentSourceIds;
  List<int>? _currentChannelIds;
  List<int>? _currentAdvertisingCampaignIds;
  List<int>? _currentReasonForRefusalIds;
  int? _currentStatusId;
  DateTime? _currentFromDate;
  DateTime? _currentToDate;
  bool? _currentHasSuccessDeals;
  bool? _currentHasInProgressDeals;
  bool? _currentHasFailureDeals;
  bool? _currentHasNotices;
  bool? _currentHasContact;
  bool? _currentHasChat;
  bool? _currentHasNoReplies; // Новый параметр
  bool? _currentHasUnreadMessages; // Новый параметр
  bool? _currentHasDeal;
  bool? _currentHasOrders;
  int? _currentDaysWithoutActivity;
  int? _currentNumberOfDaysDeal;
  int? _currentTabStatusId;
  bool isFetching = false; // Новый флаг
  List<Map<String, dynamic>>? _currentDirectoryValues; // Новый параметр
  Map<String, List<String>>? _currentCustomFieldFilters;
  FetchLeads? _queuedFetchLeadsEvent;
  FetchMoreLeads? _queuedFetchMoreLeadsEvent;
  String? _lastCompletedFetchKey;
  int? _lastCompletedFetchStatusId;

  LeadBloc(this.apiService) : super(LeadInitial()) {
    on<FetchLeadStatuses>(_fetchLeadStatuses);
    on<FetchLeads>(_fetchLeads);
    on<CreateLead>(_createLead);
    on<FetchMoreLeads>(_fetchMoreLeads);
    on<CreateLeadStatus>(_createLeadStatus);
    on<UpdateLead>(_updateLead);
    on<FetchAllLeads>(_fetchAllLeads);
    on<DeleteLead>(_deleteLead);
    on<DeleteLeadStatuses>(_deleteLeadStatuses);
    on<UpdateLeadStatusEdit>(_updateLeadStatusEdit);
    on<FetchLeadStatus>(_fetchLeadStatus);
    on<RestoreCountsFromCache>(_restoreCountsFromCache);
    on<RefreshCurrentStatus>(_refreshCurrentStatus);
    on<FetchLeadStatusesWithFilters>(_fetchLeadStatusesWithFilters);
    on<LeadCreatedFromSocket>(_onLeadCreatedFromSocket);
  }

  bool _isWorkdayAccessError(Object error) => error is WorkdayAccessException;

  bool get _hasActiveFilters {
    final bool listsOrQuery =
        (_currentQuery != null && _currentQuery!.isNotEmpty) ||
            (_currentManagerIds != null && _currentManagerIds!.isNotEmpty) ||
            (_currentRegionIds != null && _currentRegionIds!.isNotEmpty) ||
            (_currentRegionId != null) ||
            (_currentCityIds != null && _currentCityIds!.isNotEmpty) ||
            (_currentSourceIds != null && _currentSourceIds!.isNotEmpty) ||
            (_currentChannelIds != null && _currentChannelIds!.isNotEmpty) ||
            (_currentAdvertisingCampaignIds != null &&
                _currentAdvertisingCampaignIds!.isNotEmpty) ||
            (_currentReasonForRefusalIds != null &&
                _currentReasonForRefusalIds!.isNotEmpty) ||
            (_currentDirectoryValues != null &&
                _currentDirectoryValues!.isNotEmpty) ||
            (_currentCustomFieldFilters != null &&
                _currentCustomFieldFilters!.isNotEmpty);

    final bool flagsOrDates = (_currentFromDate != null) ||
        (_currentToDate != null) ||
        (_currentHasSuccessDeals == true) ||
        (_currentHasInProgressDeals == true) ||
        (_currentHasFailureDeals == true) ||
        (_currentHasNotices == true) ||
        (_currentHasContact == true) ||
        (_currentHasChat == true) ||
        (_currentHasNoReplies == true) ||
        (_currentHasUnreadMessages == true) ||
        (_currentHasDeal == true) ||
        (_currentHasOrders == true) ||
        (_currentDaysWithoutActivity != null) ||
        (_currentNumberOfDaysDeal != null);

    return listsOrQuery || flagsOrDates;
  }

  Future<void> _fetchLeadStatus(
      FetchLeadStatus event, Emitter<LeadState> emit) async {
    emit(LeadLoading());
    try {
      final leadStatus = await apiService.getLeadStatus(event.leadStatusId);
      emit(LeadStatusLoaded(leadStatus));
    } catch (e) {
      emit(LeadError('Failed to fetch deal status: ${e.toString()}'));
    }
  }

  Future<void> _fetchLeads(FetchLeads event, Emitter<LeadState> emit) async {
    final requestKey = _buildFetchRequestKey(event);
    if (!event.ignoreCache &&
        state is LeadDataLoaded &&
        _lastCompletedFetchKey == requestKey &&
        _lastCompletedFetchStatusId == event.statusId) {
      debugPrint(
          '⚠️ LeadBloc: _fetchLeads - Repeated completed request ignored for status ${event.statusId}');
      return;
    }

    if (isFetching) {
      if (_isSameFetchRequest(event)) {
        debugPrint(
            '⚠️ LeadBloc: _fetchLeads - Duplicate request ignored for status ${event.statusId}');
        return;
      }
      debugPrint(
          '⚠️ LeadBloc: _fetchLeads - Already fetching, queueing latest request for status ${event.statusId}');
      _queuedFetchLeadsEvent = event;
      return;
    }

    isFetching = true;
    _currentTabStatusId = event.statusId;

    if (kDebugMode) {
      debugPrint('🔍 LeadBloc: _fetchLeads - START');
      debugPrint('🔍 LeadBloc: statusId=${event.statusId}');
      debugPrint('🔍 LeadBloc: salesFunnelId=${event.salesFunnelId}');
      debugPrint('🔍 LeadBloc: ignoreCache=${event.ignoreCache}');
    }

    try {
      final currentState = state;
      final showingRequestedStatus = currentState is LeadDataLoaded &&
          currentState.leads.any((lead) => lead.statusId == event.statusId);

      if (!showingRequestedStatus) {
        emit(LeadLoading());
      }

      // Сохраняем параметры текущего запроса
      _currentQuery = event.query;
      _currentManagerIds = event.managerIds;
      _currentRegionIds = event.regionsIds;
      _currentRegionId = event.regionId;
      _currentCityIds = event.cityIds;
      _currentSourceIds = event.sourcesIds;
      _currentChannelIds = event.channelIds;
      _currentAdvertisingCampaignIds = event.advertisingCampaignIds;
      _currentReasonForRefusalIds = event.reasonForRefusalIds;
      _currentStatusId = event.statusIds;
      _currentFromDate = event.fromDate;
      _currentToDate = event.toDate;
      _currentHasSuccessDeals = event.hasSuccessDeals;
      _currentHasInProgressDeals = event.hasInProgressDeals;
      _currentHasFailureDeals = event.hasFailureDeals;
      _currentHasNotices = event.hasNotices;
      _currentHasContact = event.hasContact;
      _currentHasChat = event.hasChat;
      _currentHasNoReplies = event.hasNoReplies;
      _currentHasUnreadMessages = event.hasUnreadMessages;
      _currentHasDeal = event.hasDeal;
      _currentHasOrders = event.hasOrders;
      _currentDaysWithoutActivity = event.daysWithoutActivity;
      _currentNumberOfDaysDeal = event.numberOfDaysDeal;
      _currentDirectoryValues = event.directoryValues;
      _currentCustomFieldFilters = event.customFieldFilters;

      // КРИТИЧНО: Восстанавливаем ВСЕ постоянные счетчики
      final allPersistentCounts = await LeadCache.getPersistentLeadCounts();
      for (String statusIdStr in allPersistentCounts.keys) {
        int statusId = int.parse(statusIdStr);
        int count = allPersistentCounts[statusIdStr] ?? 0;
        _leadCounts[statusId] = count;
      }

      if (kDebugMode) {
        debugPrint('✅ LeadBloc: Restored persistent counts: $_leadCounts');
      }

      List<Lead> leads = [];

      // Попытка загрузить из кэша
      if (!event.ignoreCache) {
        leads = await LeadCache.getLeadsForStatus(event.statusId);
        if (leads.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
                '✅ LeadBloc: _fetchLeads - Emitting ${leads.length} cached leads for status ${event.statusId}');
            debugPrint('✅ LeadBloc: Preserved counts: $_leadCounts');
          }
          emit(LeadDataLoaded(leads,
              currentPage: 1,
              leadCounts: Map.from(_leadCounts),
              isLoadingMore: false));
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ LeadBloc: _fetchLeads - Ignoring cache (ignoreCache=true)');
        }
      }

      // КРИТИЧНО: Получаем АКТУАЛЬНУЮ воронку перед запросом к API
      final currentFunnelId =
          event.salesFunnelId ?? await apiService.getSelectedSalesFunnel();

      if (kDebugMode) {
        debugPrint(
            '🔍 LeadBloc: Current salesFunnelId for API request: $currentFunnelId');
      }

      if (await _checkInternetConnection()) {
        if (kDebugMode) {
          debugPrint('📡 LeadBloc: Internet available, fetching from API');
        }

        leads = await apiService.getLeads(
          event.statusId,
          page: 1,
          perPage: 20,
          search: event.query,
          managers: event.managerIds,
          regions: event.regionsIds,
          regionId: event.regionId,
          cityIds: event.cityIds,
          sources: event.sourcesIds,
          channelIds: event.channelIds,
          advertisingCampaignIds: event.advertisingCampaignIds,
          reasonForRefusalIds: event.reasonForRefusalIds,
          statuses: event.statusIds,
          fromDate: event.fromDate,
          toDate: event.toDate,
          hasSuccessDeals: event.hasSuccessDeals,
          hasInProgressDeals: event.hasInProgressDeals,
          hasFailureDeals: event.hasFailureDeals,
          hasNotices: event.hasNotices,
          hasContact: event.hasContact,
          hasChat: event.hasChat,
          hasNoReplies: event.hasNoReplies,
          hasUnreadMessages: event.hasUnreadMessages,
          hasDeal: event.hasDeal,
          hasOrders: event.hasOrders,
          daysWithoutActivity: event.daysWithoutActivity,
          numberOfDaysDeal: event.numberOfDaysDeal,
          directoryValues: event.directoryValues,
          customFieldFilters: event.customFieldFilters,
          bypassAnalyticsCache: event.ignoreCache,
          // salesFunnelId: currentFunnelId != null && currentFunnelId.isNotEmpty
          //     ? int.tryParse(currentFunnelId)
          //     : null, // ← КРИТИЧНО: Передаём валидный funnelId
        );

        if (kDebugMode) {
          debugPrint(
              '✅ LeadBloc: Fetched ${leads.length} leads from API for status ${event.statusId}');
        }

        // КЛЮЧЕВОЙ МОМЕНТ: Берём реальный счётчик из _leadCounts
        // (который был установлен при загрузке статусов из API)
        final int? realTotalCount = _leadCounts[event.statusId];

        if (kDebugMode) {
          debugPrint(
              '🔍 LeadBloc: Real total count for status ${event.statusId}: $realTotalCount');
          debugPrint('🔍 LeadBloc: Fetched leads count: ${leads.length}');
        }

        // Кэшируем лиды с РЕАЛЬНЫМ общим счётчиком, а не с leads.length
        await LeadCache.cacheLeadsForStatus(
          event.statusId,
          leads,
          updatePersistentCount: event.ignoreCache,
          actualTotalCount:
              realTotalCount, // ← Передаём РЕАЛЬНЫЙ счётчик из API статусов
        );

        if (kDebugMode) {
          debugPrint(
              '✅ LeadBloc: Cached ${leads.length} leads for status ${event.statusId}');
          debugPrint(
              '✅ LeadBloc: Used REAL total count: $realTotalCount from _leadCounts');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ LeadBloc: No internet connection');
        }
      }

      allLeadsFetched = leads.isEmpty;

      if (kDebugMode) {
        debugPrint(
            '✅ LeadBloc: _fetchLeads - Emitting LeadDataLoaded with ${leads.length} leads');
        debugPrint('✅ LeadBloc: Final leadCounts: $_leadCounts');
      }

      emit(LeadDataLoaded(leads,
          currentPage: 1,
          leadCounts: Map.from(_leadCounts),
          isLoadingMore: false));
      _lastCompletedFetchKey = requestKey;
      _lastCompletedFetchStatusId = event.statusId;
    } catch (e) {
      if (_isWorkdayAccessError(e)) {
        return;
      }
      if (kDebugMode) {
        debugPrint('❌ LeadBloc: _fetchLeads - Error: $e');
      }
      emit(LeadError('Не удалось загрузить данные!'));
    } finally {
      isFetching = false;
      final queuedFetchLeads = _queuedFetchLeadsEvent;
      final queuedFetchMoreLeads = _queuedFetchMoreLeadsEvent;
      _queuedFetchLeadsEvent = null;
      _queuedFetchMoreLeadsEvent = null;
      if (kDebugMode) {
        debugPrint('🏁 LeadBloc: _fetchLeads - FINISHED');
      }
      if (queuedFetchLeads != null) {
        debugPrint(
            '🔁 LeadBloc: _fetchLeads - Running queued FetchLeads for status ${queuedFetchLeads.statusId}');
        add(queuedFetchLeads);
      } else if (queuedFetchMoreLeads != null) {
        debugPrint(
            '🔁 LeadBloc: _fetchLeads - Running queued FetchMoreLeads for status ${queuedFetchMoreLeads.statusId}');
        add(queuedFetchMoreLeads);
      }
    }
  }

// Заменить метод _fetchLeadStatuses в LeadBloc на этот:

// Полностью заменить метод _fetchLeadStatuses в LeadBloc на этот:

  Future<void> _fetchLeadStatuses(
      FetchLeadStatuses event, Emitter<LeadState> emit) async {
    //print('LeadBloc: _fetchLeadStatuses - Starting with forceRefresh: ${event.forceRefresh}');
    emit(LeadLoading());

    try {
      List<LeadStatus> response;
      final previousTabStatusId = _currentTabStatusId;

      // При forceRefresh = true делаем РАДИКАЛЬНУЮ перезагрузку
      if (event.forceRefresh) {
        //print('LeadBloc: RADICAL REFRESH - loading everything from server, ignoring all cache');

        if (!await _checkInternetConnection()) {
          emit(LeadError('Нет подключения к интернету для обновления данных'));
          return;
        }

        // РАДИКАЛЬНАЯ очистка всех локальных данных блока
        _leadCounts.clear();
        allLeadsFetched = false;
        isFetching = false;

        // Сбрасываем все параметры фильтрации
        _currentQuery = null;
        _currentManagerIds = null;
        _currentRegionIds = null;
        _currentRegionId = null;
        _currentCityIds = null;
        _currentSourceIds = null;
        _currentChannelIds = null;
        _currentAdvertisingCampaignIds = null;
        _currentReasonForRefusalIds = null;
        _currentStatusId = null;
        _currentFromDate = null;
        _currentToDate = null;
        _currentHasSuccessDeals = null;
        _currentHasInProgressDeals = null;
        _currentHasFailureDeals = null;
        _currentHasNotices = null;
        _currentHasContact = null;
        _currentHasChat = null;
        _currentHasNoReplies = null;
        _currentHasUnreadMessages = null;
        _currentHasDeal = null;
        _currentHasOrders = null;
        _currentDaysWithoutActivity = null;
        _currentNumberOfDaysDeal = null;
        _currentDirectoryValues = null;

        // Загружаем статусы с сервера
        response = await apiService.getLeadStatuses(
          reasonForRefusalIds: _currentReasonForRefusalIds,
          bypassAnalyticsCache: true,
        );

        // ПОЛНОСТЬЮ перезаписываем кэш новыми данными
        await LeadCache.clearEverything(); // Используем радикальную очистку
        await LeadCache.cacheLeadStatuses(response);

        // Устанавливаем новые счетчики ТОЛЬКО из свежих данных API
        for (var status in response) {
          _leadCounts[status.id] = status.leadsCount;
          await LeadCache.setPersistentLeadCount(status.id, status.leadsCount);
        }

        //print('LeadBloc: RADICAL REFRESH completed - fresh leadCounts from API: $_leadCounts');
      } else {
        // Стандартная логика для обычной загрузки
        if (!await _checkInternetConnection()) {
          //print('LeadBloc: No internet connection, trying cache');
          final cachedStatuses = await LeadCache.getLeadStatuses();
          if (cachedStatuses.isNotEmpty) {
            final statuses = cachedStatuses
                .map((status) => LeadStatus.fromJson(status))
                .toList();

            // Восстанавливаем счетчики из кэша
            _leadCounts.clear();
            final allPersistentCounts =
                await LeadCache.getPersistentLeadCounts();
            for (String statusIdStr in allPersistentCounts.keys) {
              int statusId = int.parse(statusIdStr);
              int count = allPersistentCounts[statusIdStr] ?? 0;
              _leadCounts[statusId] = count;
            }

            //print('LeadBloc: Using cached statuses with persistent counts: $_leadCounts');
            emit(LeadLoaded(statuses, leadCounts: Map.from(_leadCounts)));
          } else {
            //print('LeadBloc: No cached statuses available');
            emit(LeadError(
                'Нет подключения к интернету и нет кэшированных данных'));
          }
          return;
        }

        // Статусы и их видимость определяет сервер. Кэш используется внутри
        // apiService только как fallback при ошибке запроса.
        response = await apiService.getLeadStatuses(
          reasonForRefusalIds: _currentReasonForRefusalIds,
          bypassAnalyticsCache: true,
        );
        await LeadCache.cacheLeadStatuses(response);

        response = await apiService.getLeadStatuses(
          reasonForRefusalIds: _currentReasonForRefusalIds,
        );
        await LeadCache.cacheLeadStatuses(response);

        // После ответа API полностью обновляем счетчики по свежим данным.
        _leadCounts.clear();
        final allPersistentCounts = await LeadCache.getPersistentLeadCounts();

        for (var status in response) {
          final statusIdStr = status.id.toString();

          if (allPersistentCounts.containsKey(statusIdStr)) {
            _leadCounts[status.id] = allPersistentCounts[statusIdStr] ?? 0;
            //print('LeadBloc: Using persistent count for status ${status.id}: ${_leadCounts[status.id]}');
          } else {
            _leadCounts[status.id] = status.leadsCount;
            await LeadCache.setPersistentLeadCount(
                status.id, status.leadsCount);
            //print('LeadBloc: Setting initial persistent count for status ${status.id}: ${status.leadsCount}');
          }
        }
      }

      //print('LeadBloc: _fetchLeadStatuses - Final leadCounts: $_leadCounts');
      emit(LeadLoaded(response, leadCounts: Map.from(_leadCounts)));

      if (response.isNotEmpty && !_hasActiveFilters) {
        final targetStatusId =
            response.any((status) => status.id == previousTabStatusId)
                ? previousTabStatusId!
                : response.first.id;
        _currentTabStatusId = targetStatusId;
        add(FetchLeads(targetStatusId, ignoreCache: event.forceRefresh));
      }
    } catch (e) {
      if (_isWorkdayAccessError(e)) {
        return;
      }
      //print('LeadBloc: _fetchLeadStatuses - Error: $e');
      emit(LeadError('Не удалось загрузить статусы: $e'));
    }
  }

  Future<void> _fetchAllLeads(
      FetchAllLeads event, Emitter<LeadState> emit) async {
    emit(LeadLoading());
    if (!await _checkInternetConnection()) {
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      final leads = await apiService.getLeads(null);
      allLeadsFetched = leads.isEmpty;
      emit(LeadDataLoaded(leads, currentPage: 1, leadCounts: {}));
    } catch (e) {
      if (_isWorkdayAccessError(e)) {
        return;
      }
      emit(LeadError('Не удалось загрузить лиды!'));
    }
  }

  Future<void> _fetchMoreLeads(
      FetchMoreLeads event, Emitter<LeadState> emit) async {
    if (allLeadsFetched) return;

    if (isFetching) {
      debugPrint(
          '⚠️ LeadBloc: _fetchMoreLeads - Already fetching, queueing latest request for status ${event.statusId}');
      _queuedFetchMoreLeadsEvent = event;
      return;
    }

    if (!await _checkInternetConnection()) {
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      isFetching = true;
      final currentState = state;
      if (currentState is LeadDataLoaded && !currentState.isLoadingMore) {
        emit(currentState.copyWith(isLoadingMore: true));
      }

      final leads = await apiService.getLeads(
        _currentTabStatusId ?? event.statusId,
        page: event.currentPage + 1,
        perPage: 20,
        search: _currentQuery,
        managers: _currentManagerIds,
        regions: _currentRegionIds,
        regionId: _currentRegionId,
        cityIds: _currentCityIds,
        sources: _currentSourceIds,
        channelIds: _currentChannelIds,
        advertisingCampaignIds: _currentAdvertisingCampaignIds,
        statuses: _currentStatusId,
        fromDate: _currentFromDate,
        toDate: _currentToDate,
        hasSuccessDeals: _currentHasSuccessDeals,
        hasInProgressDeals: _currentHasInProgressDeals,
        hasFailureDeals: _currentHasFailureDeals,
        hasNotices: _currentHasNotices,
        hasContact: _currentHasContact,
        hasChat: _currentHasChat,
        hasNoReplies: _currentHasNoReplies, // Новый параметр
        hasUnreadMessages: _currentHasUnreadMessages, // Новый параметр
        hasDeal: _currentHasDeal,
        hasOrders: _currentHasOrders,
        daysWithoutActivity: _currentDaysWithoutActivity,
        numberOfDaysDeal: _currentNumberOfDaysDeal,
        directoryValues:
            _currentDirectoryValues, // Передаем сохраненные значения
        customFieldFilters: _currentCustomFieldFilters,
      );

      if (leads.isEmpty) {
        allLeadsFetched = true;
        if (state is LeadDataLoaded) {
          emit((state as LeadDataLoaded).copyWith(isLoadingMore: false));
        }
        return;
      }

      if (state is LeadDataLoaded) {
        final currentState = state as LeadDataLoaded;
        emit(currentState.merge(leads));
      }
    } catch (e) {
      if (_isWorkdayAccessError(e)) {
        return;
      }
      emit(LeadError('Не удалось загрузить дополнительные лиды!'));
    } finally {
      isFetching = false;
      final queuedFetchLeads = _queuedFetchLeadsEvent;
      final queuedFetchMoreLeads = _queuedFetchMoreLeadsEvent;
      _queuedFetchLeadsEvent = null;
      _queuedFetchMoreLeadsEvent = null;
      if (queuedFetchLeads != null) {
        add(queuedFetchLeads);
      } else if (queuedFetchMoreLeads != null) {
        add(queuedFetchMoreLeads);
      }
    }
  }

  Future<void> _createLead(CreateLead event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    if (!await _checkInternetConnection()) {
      emit(LeadError(event.localizations.translate('no_internet_connection')));
      return;
    }

    try {
      Map<String, dynamic> requestData = {
        'name': event.name,
        'lead_status_id': event.leadStatusId,
        'phone': event.phone,
        'position': 1,
      };

      if (event.customFields != null && event.customFields!.isNotEmpty) {
        requestData['lead_custom_fields'] = event.customFields!
            .map((field) => {
                  'key': field['key'],
                  'value': field['value'],
                  'type': field['type'],
                })
            .toList();
      }

      if (event.directoryValues != null && event.directoryValues!.isNotEmpty) {
        requestData['directory_values'] = event.directoryValues!
            .map((dir) => {
                  'directory_id': dir['directory_id'],
                  'entry_id': dir['entry_id'],
                })
            .toList();
      }

      if (event.isSystemManager) {
        requestData['manager'] = 'system';
      } else if (event.managerId != null) {
        requestData['manager_id'] = event.managerId;
      }

      if (event.regionId != null) requestData['region_id'] = event.regionId;
      if (event.sourceId != null) requestData['source_id'] = event.sourceId;
      if (event.instaLogin != null)
        requestData['insta_login'] = event.instaLogin;
      if (event.facebookLogin != null)
        requestData['facebook_login'] = event.facebookLogin;
      if (event.tgNick != null) requestData['tg_nick'] = event.tgNick;
      if (event.waPhone != null) requestData['wa_phone'] = event.waPhone;
      if (event.birthday != null)
        requestData['birthday'] = event.birthday!.toIso8601String();
      if (event.cityId != null && event.cityId!.isNotEmpty) {
        requestData['city_id'] = event.cityId;
      }
      if (event.email != null) requestData['email'] = event.email;
      if (event.description != null)
        requestData['description'] = event.description;
      if (event.files != null && event.files!.isNotEmpty)
        requestData['files'] = event.files;
      if (event.priceTypeId != null)
        requestData['price_type_id'] =
            event.priceTypeId; // Добавляем price_type_id
      if (event.currencyId != null) {
        requestData['currency_id'] = event.currencyId;
      }

      if (!await _checkInternetConnection()) {
        if (event.files != null && event.files!.isNotEmpty) {
          emit(LeadError(
              'Офлайн-очередь для вложений будет доведена в phase 2. Текстовые изменения можно отправлять без файлов.'));
          return;
        }
        await OfflineRuntime.instance.outboxService.enqueue(
          id: 'lead_create_${DateTime.now().millisecondsSinceEpoch}',
          module: OfflineModule.lead,
          entityType: 'lead',
          entityId: 'local_${DateTime.now().millisecondsSinceEpoch}',
          operationType: 'create',
          payload: {
            'data': requestData,
          },
          idempotencyKey:
              'lead-create-${DateTime.now().millisecondsSinceEpoch}',
          priority: RequestPriority.high,
        );
        emit(LeadSuccess(
            'Действие принято. Лид поставлен в очередь и будет синхронизирован после восстановления сети.'));
        return;
      }

      final result = await apiService.createLeadWithData(requestData);

      if (result['success']) {
        emit(LeadSuccess(
            event.localizations.translate('lead_created_successfully')));
        add(RefreshCurrentStatus(event.leadStatusId));
      } else {
        emit(LeadError(result['message']));
      }
    } catch (e) {
      if (e is ApiException) {
        emit(LeadError(e.message));
        return;
      }

      final rawMessage =
          e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      emit(LeadError(
        rawMessage.isNotEmpty
            ? rawMessage
            : event.localizations.translate('lead_creation_error'),
      ));
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

  Future<void> _updateLead(UpdateLead event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    debugPrint("files: ${event.files}");

    // try {
    final Map<String, dynamic> requestData = {
      'name': event.name,
      'lead_status_id': event.leadStatusId,
      'phone': event.phone,
      if (event.regionId != null) 'region_id': event.regionId,
      if (event.sourseId != null) 'source_id': event.sourseId,
      if (event.instaLogin != null) 'insta_login': event.instaLogin,
      if (event.facebookLogin != null) 'facebook_login': event.facebookLogin,
      if (event.tgNick != null) 'tg_nick': event.tgNick,
      if (event.birthday != null) 'birthday': event.birthday!.toIso8601String(),
      if (event.cityId != null && event.cityId!.isNotEmpty)
        'city_id': event.cityId,
      if (event.email != null) 'email': event.email,
      if (event.description != null) 'description': event.description,
      if (event.waPhone != null) 'wa_phone': event.waPhone,
      if (event.priceTypeId != null)
        'price_type_id': event.priceTypeId, // Добавляем price_type_id
      if (event.salesFunnelId != null)
        'sales_funnel_id': event.salesFunnelId, // ДОБАВЛЕННАЯ СТРОКА
      if (event.duplicate != null)
        'duplicate': event.duplicate, // Добавляем duplicate
      if (event.reasonForRefusalId != null)
        'reason_for_refusal_id': event.reasonForRefusalId,
      if (event.reasonForRefusal != null &&
          event.reasonForRefusal!.trim().isNotEmpty)
        'reason_for_refusal': event.reasonForRefusal!.trim(),
      if (event.currencyId != null) 'currency_id': event.currencyId,
      'lead_custom_fields': event.customFields ?? [],
      'directory_values': event.directoryValues ?? [],
      if (event.files != null) 'files': event.files
    };

    if (event.isSystemManager) {
      requestData['manager_id'] = 0;
    } else if (event.managerId != null) {
      requestData['manager_id'] = event.managerId;
    }

    if (!await _checkInternetConnection()) {
      if (event.files != null && event.files!.isNotEmpty) {
        emit(LeadError(
            'Офлайн-очередь для вложений будет доведена в phase 2. Текстовые изменения можно отправлять без файлов.'));
        return;
      }
      await OfflineRuntime.instance.outboxService.enqueue(
        id: 'lead_update_${event.leadId}_${DateTime.now().millisecondsSinceEpoch}',
        module: OfflineModule.lead,
        entityType: 'lead',
        entityId: event.leadId.toString(),
        operationType: 'update',
        payload: {
          'leadId': event.leadId,
          'data': requestData,
        },
        idempotencyKey:
            'lead-update-${event.leadId}-${DateTime.now().millisecondsSinceEpoch}',
        priority: RequestPriority.high,
      );
      emit(LeadSuccess(
          'Изменения приняты и поставлены в очередь на синхронизацию.'));
      return;
    }

    final result = await apiService.updateLeadWithData(
      leadId: event.leadId,
      data: requestData,
    );

    if (result['success']) {
      emit(LeadSuccess(
          event.localizations.translate('lead_updated_successfully')));
    } else {
      emit(LeadError(result['message']));
    }
    // } catch (e) {
    //   emit(LeadError(event.localizations.translate('error_update_lead')));
    // }
  }

  Future<void> _createLeadStatus(
      CreateLeadStatus event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    if (!await _checkInternetConnection()) {
      emit(LeadError(event.localizations.translate('no_internet_connection')));
      return;
    }

    try {
      final result = await apiService.createLeadStatus(
        event.title,
        event.color,
        event.isFailure,
        event.isSuccess,
        event.isUnassembled,
        event.userIds,
      );

      if (result['success']) {
        emit(LeadSuccess(result['message']));
        add(FetchLeadStatuses());
      } else {
        emit(LeadError(result['message']));
      }
    } catch (e) {
      emit(
          LeadError(event.localizations.translate('error_create_status_lead')));
    }
  }

  Future<void> _deleteLead(DeleteLead event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    try {
      final response = await apiService.deleteLead(event.leadId);
      if (response['success'] == true || response['result'] == 'Success') {
        emit(LeadDeleted(
            event.localizations.translate('lead_deleted_successfully')));
      } else {
        emit(LeadError(response['message']?.toString() ??
            event.localizations.translate('error_delete_lead')));
      }
    } catch (e) {
      emit(LeadError(event.localizations.translate('error_delete_lead')));
    }
  }

  Future<void> _deleteLeadStatuses(
      DeleteLeadStatuses event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    try {
      final response = await apiService.deleteLeadStatuses(event.leadStatusId);
      if (response['result'] == 'Success') {
        emit(LeadDeleted(
            event.localizations.translate('delete_status_lead_successfully')));
      } else {
        emit(LeadError(
            event.localizations.translate('error_delete_status_lead')));
      }
    } catch (e) {
      emit(
          LeadError(event.localizations.translate('error_delete_status_lead')));
    }
  }

  Future<void> _updateLeadStatusEdit(
      UpdateLeadStatusEdit event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    try {
      final response = await apiService.updateLeadStatusEdit(
        event.leadStatusId,
        event.title,
        event.isSuccess,
        event.isFailure,
        event.isUnassembled,
        event.userIds,
      );

      if (response['result'] == 'Success') {
        emit(LeadStatusUpdatedEdit(
            event.localizations.translate('status_updated_successfully')));
      } else {
        emit(LeadError(event.localizations.translate('error_update_status')));
      }
    } catch (e) {
      emit(LeadError(event.localizations.translate('error_update_status')));
    }
  }

  Future<void> _updateLeadStatusAndCount(
      UpdateLeadStatus event, Emitter<LeadState> emit) async {
    try {
      // Обновляем лид в API
      await apiService.updateLeadStatus(
          event.leadId, event.newStatusId, event.oldStatusId);

      // Обновляем постоянные счетчики
      await LeadCache.updateLeadCountTemporary(
          event.oldStatusId, event.newStatusId);

      // Обновляем локальные счетчики
      final oldCount =
          await LeadCache.getPersistentLeadCount(event.oldStatusId);
      final newCount =
          await LeadCache.getPersistentLeadCount(event.newStatusId);

      _leadCounts[event.oldStatusId] = oldCount;
      _leadCounts[event.newStatusId] = newCount;

      // Перезагружаем текущий статус
      add(FetchLeads(event.oldStatusId, ignoreCache: true));

      ////print('LeadBloc: Updated lead status and counts - old: ${event.oldStatusId}($oldCount), new: ${event.newStatusId}($newCount)');
    } catch (e) {
      emit(LeadError('Не удалось обновить статус лида: $e'));
    }
  }
// Метод для очистки всех счетчиков (при смене воронки)
// Заменить существующий метод clearAllCountsAndCache в LeadBloc на этот:

  /// РАДИКАЛЬНАЯ очистка - удаляет ВСЕ данные и сбрасывает состояние блока
  Future<void> clearAllCountsAndCache() async {
    //print('LeadBloc: RADICAL CLEAR - Clearing all counts, cache and resetting state');

    // Очищаем локальные переменные блока
    _leadCounts.clear();
    allLeadsFetched = false;
    isFetching = false;

    // Сбрасываем все текущие параметры фильтрации
    _currentQuery = null;
    _currentManagerIds = null;
    _currentRegionIds = null;
    _currentSourceIds = null;
    _currentAdvertisingCampaignIds = null;
    _currentStatusId = null;
    _currentFromDate = null;
    _currentToDate = null;
    _currentHasSuccessDeals = null;
    _currentHasInProgressDeals = null;
    _currentHasFailureDeals = null;
    _currentHasNotices = null;
    _currentHasContact = null;
    _currentHasChat = null;
    _currentHasNoReplies = null;
    _currentHasUnreadMessages = null;
    _currentHasDeal = null;
    _currentHasOrders = null;
    _currentDaysWithoutActivity = null;
    _currentNumberOfDaysDeal = null;
    _currentTabStatusId = null;
    _currentDirectoryValues = null;
    _queuedFetchLeadsEvent = null;
    _queuedFetchMoreLeadsEvent = null;

    // Радикальная очистка кэша
    await LeadCache.clearEverything(); // Используем новый метод полной очистки

    //print('LeadBloc: RADICAL CLEAR completed - all state reset to initial');
  }

  /// Дополнительный метод для принудительного сброса всех счетчиков
  Future<void> resetAllCounters() async {
    _leadCounts.clear();
    await LeadCache.clearPersistentCounts();
    //print('LeadBloc: Reset all counters to zero');
  }

  /// Вызывать перед переходом между табами
  Future<void> _preserveCurrentCounts() async {
    if (_leadCounts.isNotEmpty) {
      for (int statusId in _leadCounts.keys) {
        int currentCount = _leadCounts[statusId] ?? 0;
        await LeadCache.setPersistentLeadCount(statusId, currentCount);
      }
      ////print('LeadBloc: Preserved all current counts: $_leadCounts');
    }
  }

  /// Метод для восстановления всех счетчиков из постоянного кэша
  Future<void> _restoreAllCounts() async {
    final allPersistentCounts = await LeadCache.getPersistentLeadCounts();
    _leadCounts.clear();

    for (String statusIdStr in allPersistentCounts.keys) {
      int statusId = int.parse(statusIdStr);
      int count = allPersistentCounts[statusIdStr] ?? 0;
      _leadCounts[statusId] = count;
    }

    ////print('LeadBloc: Restored all counts from persistent cache: $_leadCounts');
  }

  Future<void> _restoreCountsFromCache(
      RestoreCountsFromCache event, Emitter<LeadState> emit) async {
    await _restoreAllCounts();

    // Перезапускаем текущее состояние с восстановленными счетчиками
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      emit(LeadLoaded(currentState.leadStatuses,
          leadCounts: Map.from(_leadCounts)));
    } else if (state is LeadDataLoaded) {
      final currentState = state as LeadDataLoaded;
      emit(LeadDataLoaded(currentState.leads,
          currentPage: currentState.currentPage,
          leadCounts: Map.from(_leadCounts)));
    }
  }

  Future<void> _refreshCurrentStatus(
      RefreshCurrentStatus event, Emitter<LeadState> emit) async {
    //print('LeadBloc: _refreshCurrentStatus for statusId: ${event.statusId}');

    try {
      if (await _checkInternetConnection()) {
        // Принудительно загружаем лиды для указанного статуса с сервера
        final leads = await apiService.getLeads(
          event.statusId,
          page: 1,
          perPage: 20,
          salesFunnelId: event.salesFunnelId,
        );

        // Кэшируем новые данные, ПЕРЕЗАПИСЫВАЯ старые
        await LeadCache.cacheLeadsForStatus(event.statusId, leads);

        // Восстанавливаем все счетчики из постоянного кэша
        await _restoreAllCounts();

        //print('LeadBloc: _refreshCurrentStatus - Loaded ${leads.length} leads for status ${event.statusId}');
        emit(LeadDataLoaded(leads,
            currentPage: 1, leadCounts: Map.from(_leadCounts)));
      } else {
        //print('LeadBloc: _refreshCurrentStatus - No internet connection');
        emit(LeadError('Нет подключения к интернету'));
      }
    } catch (e) {
      //print('LeadBloc: _refreshCurrentStatus - Error: $e');
      emit(LeadError('Не удалось обновить данные статуса: $e'));
    }
  }

  Future<void> _onLeadCreatedFromSocket(
    LeadCreatedFromSocket event,
    Emitter<LeadState> emit,
  ) async {
    if (event.hasActiveFilters) {
      if (event.activeStatusId != null) {
        add(FetchLeads(
          event.activeStatusId!,
          query: _currentQuery,
          managerIds: _currentManagerIds,
          regionsIds: _currentRegionIds,
          regionId: _currentRegionId,
          cityIds: _currentCityIds,
          sourcesIds: _currentSourceIds,
          channelIds: _currentChannelIds,
          advertisingCampaignIds: _currentAdvertisingCampaignIds,
          reasonForRefusalIds: _currentReasonForRefusalIds,
          statusIds: _currentStatusId,
          fromDate: _currentFromDate,
          toDate: _currentToDate,
          hasSuccessDeals: _currentHasSuccessDeals,
          hasInProgressDeals: _currentHasInProgressDeals,
          hasFailureDeals: _currentHasFailureDeals,
          hasNotices: _currentHasNotices,
          hasContact: _currentHasContact,
          hasChat: _currentHasChat,
          hasNoReplies: _currentHasNoReplies,
          hasUnreadMessages: _currentHasUnreadMessages,
          hasDeal: _currentHasDeal,
          hasOrders: _currentHasOrders,
          daysWithoutActivity: _currentDaysWithoutActivity,
          numberOfDaysDeal: _currentNumberOfDaysDeal,
          directoryValues: _currentDirectoryValues,
          customFieldFilters: _currentCustomFieldFilters,
          ignoreCache: true,
        ));
      }
      return;
    }

    final newCount = (_leadCounts[event.lead.statusId] ?? 0) + 1;
    _leadCounts[event.lead.statusId] = newCount;

    await LeadCache.incrementLeadCount(event.lead.statusId);
    await LeadCache.insertOrUpdateLeadForStatus(
        event.lead.statusId, event.lead);

    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      emit(currentState.copyWith(leadCounts: Map<int, int>.from(_leadCounts)));
      return;
    }

    if (state is LeadDataLoaded) {
      final currentState = state as LeadDataLoaded;
      final updatedLeads = List<Lead>.from(currentState.leads)
        ..removeWhere((lead) => lead.id == event.lead.id);

      if (event.activeStatusId == event.lead.statusId) {
        updatedLeads.insert(0, event.lead);
      }

      emit(currentState.refresh(
        updatedLeads,
        newCounts: Map<int, int>.from(_leadCounts),
      ));
    }
  }

  Future<void> _fetchLeadStatusesWithFilters(
    FetchLeadStatusesWithFilters event,
    Emitter<LeadState> emit,
  ) async {
    if (kDebugMode) {
      debugPrint('🔍 LeadBloc: _fetchLeadStatusesWithFilters - START');
    }

    emit(LeadLoading());

    try {
      // 1. Получаем статусы с учётом фильтров
      final statuses = await apiService.getLeadStatuses(
        managers: event.managerIds,
        regions: event.regionsIds,
        regionId: event.regionId,
        cityIds: event.cityIds,
        sources: event.sourcesIds,
        channelIds: event.channelIds,
        advertisingCampaignIds: event.advertisingCampaignIds,
        reasonForRefusalIds: event.reasonForRefusalIds,
        fromDate: event.fromDate,
        toDate: event.toDate,
        hasSuccessDeals: event.hasSuccessDeals,
        hasInProgressDeals: event.hasInProgressDeals,
        hasFailureDeals: event.hasFailureDeals,
        hasNotices: event.hasNotices,
        hasContact: event.hasContact,
        hasChat: event.hasChat,
        hasNoReplies: event.hasNoReplies,
        hasUnreadMessages: event.hasUnreadMessages,
        hasDeal: event.hasDeal,
        hasOrders: event.hasOrders,
        daysWithoutActivity: event.daysWithoutActivity,
        numberOfDaysDeal: event.numberOfDaysDeal,
        directoryValues: event.directoryValues,
        bypassAnalyticsCache: true,
      );

      if (kDebugMode) {
        debugPrint('✅ LeadBloc: Got ${statuses.length} statuses with filters');
      }

      // 2. Обновляем счётчики только в памяти.
      // Фильтрованные значения нельзя сохранять как постоянные,
      // иначе после reset экран продолжит показывать числа от фильтра.
      _leadCounts.clear();
      for (var status in statuses) {
        _leadCounts[status.id] = status.leadsCount;
      }

      // 3. Эмитим состояние со статусами
      emit(LeadLoaded(statuses, leadCounts: Map.from(_leadCounts)));

      // 4. Сохраняем фильтры в блоке перед загрузкой целевого статуса
      if (statuses.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🎯 LeadBloc: Saving filters before filtered fetch');
          debugPrint('🔍 LeadBloc: SAVING FILTERS TO BLOC STATE:');
          debugPrint('   managerIds: ${event.managerIds}');
          debugPrint('   regionsIds: ${event.regionsIds}');
          debugPrint('   sourcesIds: ${event.sourcesIds}');
          debugPrint('   hasContact: ${event.hasContact}');
          debugPrint('   hasOrders: ${event.hasOrders}');
        }

        // ← СОХРАНЯЕМ фильтры для последующих запросов
        _currentQuery = null; // При фильтрах query обычно null
        _currentManagerIds = event.managerIds;
        _currentRegionIds = event.regionsIds;
        _currentRegionId = event.regionId;
        _currentCityIds = event.cityIds;
        _currentSourceIds = event.sourcesIds;
        _currentChannelIds = event.channelIds;
        _currentAdvertisingCampaignIds = event.advertisingCampaignIds;
        _currentReasonForRefusalIds = event.reasonForRefusalIds;
        _currentStatusId =
            null; // Будет устанавливаться для каждого статуса отдельно
        _currentFromDate = event.fromDate;
        _currentToDate = event.toDate;
        _currentHasSuccessDeals = event.hasSuccessDeals;
        _currentHasInProgressDeals = event.hasInProgressDeals;
        _currentHasFailureDeals = event.hasFailureDeals;
        _currentHasNotices = event.hasNotices;
        _currentHasContact = event.hasContact;
        _currentHasChat = event.hasChat;
        _currentHasNoReplies = event.hasNoReplies;
        _currentHasUnreadMessages = event.hasUnreadMessages;
        _currentHasDeal = event.hasDeal;
        _currentHasOrders = event.hasOrders;
        _currentDaysWithoutActivity = event.daysWithoutActivity;
        _currentNumberOfDaysDeal = event.numberOfDaysDeal;
        _currentDirectoryValues = event.directoryValues;
        _currentCustomFieldFilters = null;

        if (kDebugMode) {
          debugPrint('✅ LeadBloc: Filters saved to bloc state');
        }

        final targetStatus =
            statuses.any((status) => status.id == event.preferredStatusId)
                ? event.preferredStatusId!
                : statuses.first.id;

        _currentTabStatusId = targetStatus;

        if (kDebugMode) {
          debugPrint(
              '🎯 LeadBloc: target status after filtered statuses request = $targetStatus');
        }

        await _fetchLeadsForStatusWithFilters(
          targetStatus,
          event.managerIds,
          event.regionsIds,
          event.regionId,
          event.cityIds,
          event.sourcesIds,
          event.channelIds,
          event.advertisingCampaignIds,
          event.reasonForRefusalIds,
          event.fromDate,
          event.toDate,
          event.hasSuccessDeals,
          event.hasInProgressDeals,
          event.hasFailureDeals,
          event.hasNotices,
          event.hasContact,
          event.hasChat,
          event.hasNoReplies,
          event.hasUnreadMessages,
          event.hasDeal,
          event.hasOrders,
          event.daysWithoutActivity,
          event.numberOfDaysDeal,
          event.directoryValues,
          event.salesFunnelId,
        );

        final leadsForTarget = await LeadCache.getLeadsForStatus(targetStatus);
        emit(LeadDataLoaded(leadsForTarget,
            currentPage: 1,
            leadCounts: Map.from(_leadCounts),
            isLoadingMore: false));
      }
    } catch (e) {
      if (_isWorkdayAccessError(e)) {
        return;
      }
      if (kDebugMode) {
        debugPrint('❌ LeadBloc: _fetchLeadStatusesWithFilters - Error: $e');
      }
      emit(LeadError('Не удалось загрузить статусы с фильтрами: $e'));
    }
  }

// Вспомогательный метод для загрузки лидов одного статуса
  Future<void> _fetchLeadsForStatusWithFilters(
    int statusId,
    List<int>? managerIds,
    List<int>? regionsIds,
    int? regionId,
    List<int>? cityIds,
    List<int>? sourcesIds,
    List<int>? channelIds,
    List<int>? advertisingCampaignIds,
    List<int>? reasonForRefusalIds,
    DateTime? fromDate,
    DateTime? toDate,
    bool? hasSuccessDeals,
    bool? hasInProgressDeals,
    bool? hasFailureDeals,
    bool? hasNotices,
    bool? hasContact,
    bool? hasChat,
    bool? hasNoReplies,
    bool? hasUnreadMessages,
    bool? hasDeal,
    bool? hasOrders,
    int? daysWithoutActivity,
    int? numberOfDaysDeal,
    List<Map<String, dynamic>>? directoryValues,
    int? salesFunnelId,
  ) async {
    try {
      if (!await _checkInternetConnection()) {
        if (kDebugMode) {
          debugPrint('⚠️ LeadBloc: No internet for status $statusId');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '🔍 LeadBloc: _fetchLeadsForStatusWithFilters for status $statusId');
        debugPrint('   managerIds: $managerIds');
        debugPrint('   regionsIds: $regionsIds');
        debugPrint('   regionId: $regionId');
        debugPrint('   cityIds: $cityIds');
        debugPrint('   sourcesIds: $sourcesIds');
        debugPrint('   channelIds: $channelIds');
        debugPrint('   hasContact: $hasContact');
        debugPrint('   hasOrders: $hasOrders');
        debugPrint('   hasSuccessDeals: $hasSuccessDeals');
        debugPrint('   hasInProgressDeals: $hasInProgressDeals');
        debugPrint('   hasFailureDeals: $hasFailureDeals');
        debugPrint('   hasNotices: $hasNotices');
      }

      final leads = await apiService.getLeads(
        null, // ← leadStatusId = null
        page: 1,
        perPage: 20,
        managers: managerIds, // ← КРИТИЧНО: Передаём фильтры!
        regions: regionsIds,
        regionId: regionId,
        cityIds: cityIds,
        sources: sourcesIds,
        channelIds: channelIds,
        advertisingCampaignIds: advertisingCampaignIds,
        reasonForRefusalIds: reasonForRefusalIds,
        statuses: statusId, // ← ВАЖНО: ID статуса через параметр statuses
        fromDate: fromDate,
        toDate: toDate,
        hasSuccessDeals: hasSuccessDeals,
        hasInProgressDeals: hasInProgressDeals,
        hasFailureDeals: hasFailureDeals,
        hasNotices: hasNotices,
        hasContact: hasContact, // ← Проверь что передаётся!
        hasChat: hasChat,
        hasNoReplies: hasNoReplies,
        hasUnreadMessages: hasUnreadMessages,
        hasDeal: hasDeal,
        hasOrders: hasOrders, // ← Проверь что передаётся!
        daysWithoutActivity: daysWithoutActivity,
        numberOfDaysDeal: numberOfDaysDeal,
        directoryValues: directoryValues,
        salesFunnelId: salesFunnelId,
      );

      if (kDebugMode) {
        debugPrint(
            '✅ LeadBloc: Fetched ${leads.length} leads for status $statusId WITH FILTERS');
      }

      // Кэшируем с сохранением реального счётчика
      final realCount = _leadCounts[statusId];
      await LeadCache.cacheLeadsForStatus(
        statusId,
        leads,
        updatePersistentCount: true,
        actualTotalCount: realCount,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ LeadBloc: Error fetching leads for status $statusId: $e');
      }
    }
  }

  bool _isSameFetchRequest(FetchLeads event) {
    return _buildCurrentFetchRequestKey() == _buildFetchRequestKey(event);
  }

  String _buildCurrentFetchRequestKey() {
    return [
      _currentTabStatusId,
      _currentQuery,
      _currentManagerIds?.join(','),
      _currentRegionIds?.join(','),
      _currentRegionId,
      _currentCityIds?.join(','),
      _currentSourceIds?.join(','),
      _currentChannelIds?.join(','),
      _currentAdvertisingCampaignIds?.join(','),
      _currentReasonForRefusalIds?.join(','),
      _currentStatusId,
      _currentFromDate?.toIso8601String(),
      _currentToDate?.toIso8601String(),
      _currentHasSuccessDeals,
      _currentHasInProgressDeals,
      _currentHasFailureDeals,
      _currentHasNotices,
      _currentHasContact,
      _currentHasChat,
      _currentHasNoReplies,
      _currentHasUnreadMessages,
      _currentHasDeal,
      _currentHasOrders,
      _currentDaysWithoutActivity,
      _currentNumberOfDaysDeal,
      _currentDirectoryValues?.toString(),
      _currentCustomFieldFilters?.toString(),
    ].join('|');
  }

  String _buildFetchRequestKey(FetchLeads event) {
    return [
      event.statusId,
      event.query,
      event.managerIds?.join(','),
      event.regionsIds?.join(','),
      event.regionId,
      event.cityIds?.join(','),
      event.sourcesIds?.join(','),
      event.channelIds?.join(','),
      event.advertisingCampaignIds?.join(','),
      event.reasonForRefusalIds?.join(','),
      event.statusIds,
      event.fromDate?.toIso8601String(),
      event.toDate?.toIso8601String(),
      event.hasSuccessDeals,
      event.hasInProgressDeals,
      event.hasFailureDeals,
      event.hasNotices,
      event.hasContact,
      event.hasChat,
      event.hasNoReplies,
      event.hasUnreadMessages,
      event.hasDeal,
      event.hasOrders,
      event.daysWithoutActivity,
      event.numberOfDaysDeal,
      event.directoryValues?.toString(),
      event.customFieldFilters?.toString(),
    ].join('|');
  }
}
