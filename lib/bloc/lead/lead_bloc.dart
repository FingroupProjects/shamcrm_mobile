import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
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
  List<int>? _currentSourceIds;
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
  bool isFetching = false; // Новый флаг
  List<Map<String, dynamic>>? _currentDirectoryValues; // Новый параметр


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
  }

  Future<void> _fetchLeadStatus(FetchLeadStatus event, Emitter<LeadState> emit) async {
    emit(LeadLoading());
    try {
      final leadStatus = await apiService.getLeadStatus(event.leadStatusId);
      emit(LeadStatusLoaded(leadStatus));
    } catch (e) {
      emit(LeadError('Failed to fetch deal status: ${e.toString()}'));
    }
  }

Future<void> _fetchLeads(FetchLeads event, Emitter<LeadState> emit) async {
  if (isFetching) {
    return;
  }
  isFetching = true;
  
  try {
    // ВСЕГДА эмитим LeadLoading в начале, если это новый запрос
    if (event.ignoreCache || event.query != null || event.managerIds != null) {
      emit(LeadLoading());
    }

    _currentQuery = event.query;
    _currentManagerIds = event.managerIds;
    // ... остальные параметры
    
    // Восстанавливаем постоянные счетчики
    final allPersistentCounts = await LeadCache.getPersistentLeadCounts();
    for (String statusIdStr in allPersistentCounts.keys) {
      int statusId = int.parse(statusIdStr);
      int count = allPersistentCounts[statusIdStr] ?? 0;
      _leadCounts[statusId] = count;
    }

    List<Lead> leads = [];
    
    // Проверяем кэш только если НЕ ignoreCache
    if (!event.ignoreCache && event.query == null) {
      leads = await LeadCache.getLeadsForStatus(event.statusId);
      if (leads.isNotEmpty) {
        emit(LeadDataLoaded(leads, currentPage: 1, leadCounts: Map.from(_leadCounts)));
      }
    }

    // Загружаем с сервера
    if (await _checkInternetConnection()) {
      leads = await apiService.getLeads(
        event.statusId,
        page: 1,
        perPage: 20,
        search: event.query,
        managers: event.managerIds,
        regions: event.regionsIds,
        sources: event.sourcesIds,
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
        directoryValues: event.directoryValues,
        salesFunnelId: event.salesFunnelId,
      );

      // Кэшируем данные
      await LeadCache.cacheLeadsForStatus(
        event.statusId,
        leads,
        updatePersistentCount: event.ignoreCache,
      );
    }

    allLeadsFetched = leads.isEmpty;
    
    // КРИТИЧНО: ВСЕГДА эмитим финальное состояние
    emit(LeadDataLoaded(
      leads, 
      currentPage: 1, 
      leadCounts: Map.from(_leadCounts),
      timestamp: DateTime.now(), // Обновляем timestamp для гарантии изменения
    ));
    
  } catch (e) {
    emit(LeadError('Не удалось загрузить данные!'));
  } finally {
    isFetching = false; // ОБЯЗАТЕЛЬНО сбрасываем флаг
  }
}




// Заменить метод _fetchLeadStatuses в LeadBloc на этот:

// Полностью заменить метод _fetchLeadStatuses в LeadBloc на этот:

Future<void> _fetchLeadStatuses(FetchLeadStatuses event, Emitter<LeadState> emit) async {
  //print('LeadBloc: _fetchLeadStatuses - Starting with forceRefresh: ${event.forceRefresh}');
  emit(LeadLoading());

  try {
    List<LeadStatus> response;

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
      _currentSourceIds = null;
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
      _currentDirectoryValues = null;
      
      // Загружаем статусы с сервера
      response = await apiService.getLeadStatuses();
      
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
          final statuses = cachedStatuses.map((status) => LeadStatus.fromJson(status)).toList();
          
          // Восстанавливаем счетчики из кэша
          _leadCounts.clear();
          final allPersistentCounts = await LeadCache.getPersistentLeadCounts();
          for (String statusIdStr in allPersistentCounts.keys) {
            int statusId = int.parse(statusIdStr);
            int count = allPersistentCounts[statusIdStr] ?? 0;
            _leadCounts[statusId] = count;
          }
          
          //print('LeadBloc: Using cached statuses with persistent counts: $_leadCounts');
          emit(LeadLoaded(statuses, leadCounts: Map.from(_leadCounts)));
        } else {
          //print('LeadBloc: No cached statuses available');
          emit(LeadError('Нет подключения к интернету и нет кэшированных данных'));
        }
        return;
      }

      // Проверяем кэш
      final cachedStatuses = await LeadCache.getLeadStatuses();
      if (cachedStatuses.isNotEmpty) {
        //print('LeadBloc: Using cached statuses');
        response = cachedStatuses.map((status) => LeadStatus.fromJson(status)).toList();
      } else {
        //print('LeadBloc: No cache found, loading from API');
        response = await apiService.getLeadStatuses();
        await LeadCache.cacheLeadStatuses(response);
      }

      // Восстанавливаем или устанавливаем счетчики
      _leadCounts.clear();
      final allPersistentCounts = await LeadCache.getPersistentLeadCounts();
      
      for (var status in response) {
        final statusIdStr = status.id.toString();
        
        if (allPersistentCounts.containsKey(statusIdStr)) {
          _leadCounts[status.id] = allPersistentCounts[statusIdStr] ?? 0;
          //print('LeadBloc: Using persistent count for status ${status.id}: ${_leadCounts[status.id]}');
        } else {
          _leadCounts[status.id] = status.leadsCount;
          await LeadCache.setPersistentLeadCount(status.id, status.leadsCount);
          //print('LeadBloc: Setting initial persistent count for status ${status.id}: ${status.leadsCount}');
        }
      }
    }

    //print('LeadBloc: _fetchLeadStatuses - Final leadCounts: $_leadCounts');
    emit(LeadLoaded(response, leadCounts: Map.from(_leadCounts)));

    // При обычной загрузке автоматически загружаем лиды для первого статуса
    // При forceRefresh НЕ загружаем автоматически - это будет делать LeadScreen вручную
    if (response.isNotEmpty && !event.forceRefresh) {
      final firstStatusId = response.first.id;
      //print('LeadBloc: Auto-loading leads for first status: $firstStatusId');
      add(FetchLeads(firstStatusId, ignoreCache: false));
    } else if (event.forceRefresh) {
      //print('LeadBloc: ForceRefresh mode - NOT auto-loading leads, waiting for manual trigger');
    }

  } catch (e) {
    //print('LeadBloc: _fetchLeadStatuses - Error: $e');
    emit(LeadError('Не удалось загрузить статусы: $e'));
  }
}

  Future<void> _fetchAllLeads(FetchAllLeads event, Emitter<LeadState> emit) async {
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
      emit(LeadError('Не удалось загрузить лиды!'));
    }
  }

  Future<void> _fetchMoreLeads(FetchMoreLeads event, Emitter<LeadState> emit) async {
    if (allLeadsFetched) return;

    if (!await _checkInternetConnection()) {
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      final leads = await apiService.getLeads(
        _currentStatusId ?? event.statusId,
        page: event.currentPage + 1,
        perPage: 20,
        search: _currentQuery,
        managers: _currentManagerIds,
        regions: _currentRegionIds,
        sources: _currentSourceIds,
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
                directoryValues: _currentDirectoryValues, // Передаем сохраненные значения

      );

      if (leads.isEmpty) {
        allLeadsFetched = true;
        return;
      }

      if (state is LeadDataLoaded) {
        final currentState = state as LeadDataLoaded;
        emit(currentState.merge(leads));
      }
    } catch (e) {
      emit(LeadError('Не удалось загрузить дополнительные лиды!'));
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
      requestData['lead_custom_fields'] = event.customFields!.map((field) => {
            'key': field['key'],
            'value': field['value'],
            'type': field['type'],
          }).toList();
    }

    if (event.directoryValues != null && event.directoryValues!.isNotEmpty) {
      requestData['directory_values'] = event.directoryValues!.map((dir) => {
            'directory_id': dir['directory_id'],
            'entry_id': dir['entry_id'],
          }).toList();
    }

    if (event.isSystemManager) {
      requestData['manager'] = 'system';
    } else if (event.managerId != null) {
      requestData['manager_id'] = event.managerId;
    }

    if (event.regionId != null) requestData['region_id'] = event.regionId;
    if (event.sourceId != null) requestData['source_id'] = event.sourceId;
    if (event.instaLogin != null) requestData['insta_login'] = event.instaLogin;
    if (event.facebookLogin != null) requestData['facebook_login'] = event.facebookLogin;
    if (event.tgNick != null) requestData['tg_nick'] = event.tgNick;
    if (event.waPhone != null) requestData['wa_phone'] = event.waPhone;
    if (event.birthday != null) requestData['birthday'] = event.birthday!.toIso8601String();
    if (event.email != null) requestData['email'] = event.email;
    if (event.description != null) requestData['description'] = event.description;

    final result = await apiService.createLeadWithData(
      requestData,
      filePaths: event.filePaths,
    );

    if (result['success']) {
      emit(LeadSuccess(event.localizations.translate('lead_created_successfully')));
    } else {
      emit(LeadError(result['message']));
    }
  } catch (e) {
    emit(LeadError(event.localizations.translate('lead_creation_error')));
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

  if (!await _checkInternetConnection()) {
    emit(LeadError(event.localizations.translate('no_internet_connection')));
    return;
  }

  try {
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
      if (event.email != null) 'email': event.email,
      if (event.description != null) 'description': event.description,
      if (event.waPhone != null) 'wa_phone': event.waPhone,
      if (event.priceTypeId != null) 'price_type_id': event.priceTypeId, // Добавляем price_type_id
            if (event.salesFunnelId != null) 'sales_funnel_id': event.salesFunnelId, // ДОБАВЛЕННАЯ СТРОКА
if (event.duplicate != null) 'duplicate': event.duplicate, // Добавляем duplicate
      'lead_custom_fields': event.customFields ?? [],
      'directory_values': event.directoryValues ?? [],
      'existing_file_ids': event.existingFiles.map((file) => file.id).toList(),
    };

    if (event.isSystemManager) {
      requestData['manager_id'] = 0;
    } else if (event.managerId != null) {
      requestData['manager_id'] = event.managerId;
    }

    final result = await apiService.updateLeadWithData(
      leadId: event.leadId,
      data: requestData,
      filePaths: event.filePaths,
    );

    if (result['success']) {
      emit(LeadSuccess(event.localizations.translate('lead_updated_successfully')));
    } else {
      emit(LeadError(result['message']));
    }
  } catch (e) {
    emit(LeadError(event.localizations.translate('error_update_lead')));
  }
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
          event.title, event.color, event.isFailure, event.isSuccess);

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
      if (response['result'] == 'Success') {
        emit(LeadDeleted(
            event.localizations.translate('lead_deleted_successfully')));
      } else {
        emit(LeadError(event.localizations.translate('error_delete_lead')));
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


  Future<void> _updateLeadStatusAndCount(UpdateLeadStatus event, Emitter<LeadState> emit) async {
  try {
    // Обновляем лид в API
    await apiService.updateLeadStatus(event.leadId, event.newStatusId, event.oldStatusId);
    
    // Обновляем постоянные счетчики
    await LeadCache.updateLeadCountTemporary(event.oldStatusId, event.newStatusId);
    
    // Обновляем локальные счетчики
    final oldCount = await LeadCache.getPersistentLeadCount(event.oldStatusId);
    final newCount = await LeadCache.getPersistentLeadCount(event.newStatusId);
    
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
  _currentDirectoryValues = null;
  
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

Future<void> _restoreCountsFromCache(RestoreCountsFromCache event, Emitter<LeadState> emit) async {
  await _restoreAllCounts();
  
  // Перезапускаем текущее состояние с восстановленными счетчиками
  if (state is LeadLoaded) {
    final currentState = state as LeadLoaded;
    emit(LeadLoaded(currentState.leadStatuses, leadCounts: Map.from(_leadCounts)));
  } else if (state is LeadDataLoaded) {
    final currentState = state as LeadDataLoaded;
    emit(LeadDataLoaded(
      currentState.leads, 
      currentPage: currentState.currentPage, 
      leadCounts: Map.from(_leadCounts)
    ));
  }
}
Future<void> _refreshCurrentStatus(RefreshCurrentStatus event, Emitter<LeadState> emit) async {
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
      emit(LeadDataLoaded(leads, currentPage: 1, leadCounts: Map.from(_leadCounts)));
    } else {
      //print('LeadBloc: _refreshCurrentStatus - No internet connection');
      emit(LeadError('Нет подключения к интернету'));
    }
  } catch (e) {
    //print('LeadBloc: _refreshCurrentStatus - Error: $e');
    emit(LeadError('Не удалось обновить данные статуса: $e'));
  }
}
}