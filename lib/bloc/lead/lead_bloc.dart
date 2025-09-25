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
    //print('LeadBloc: _fetchLeads - Already fetching, skipping');
    return;
  }
  isFetching = true;
  try {
    //print('LeadBloc: _fetchLeads - statusId: ${event.statusId}, salesFunnelId: ${event.salesFunnelId}, ignoreCache: ${event.ignoreCache}');
    
    // НЕ отправляем LeadLoading, чтобы не мигал интерфейс
    if (state is! LeadDataLoaded) {
      emit(LeadLoading());
    }

    _currentQuery = event.query;
    _currentManagerIds = event.managerIds;
    _currentRegionIds = event.regionsIds;
    _currentSourceIds = event.sourcesIds;
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
    _currentDaysWithoutActivity = event.daysWithoutActivity;
    _currentDirectoryValues = event.directoryValues;

    // КРИТИЧНО: Сначала восстанавливаем ВСЕ постоянные счетчики
    final allPersistentCounts = await LeadCache.getPersistentLeadCounts();
    for (String statusIdStr in allPersistentCounts.keys) {
      int statusId = int.parse(statusIdStr);
      int count = allPersistentCounts[statusIdStr] ?? 0;
      _leadCounts[statusId] = count;
    }
    //print('LeadBloc: Restored all persistent counts: $_leadCounts');

    List<Lead> leads = [];
    if (!event.ignoreCache) {
      leads = await LeadCache.getLeadsForStatus(event.statusId);
      if (leads.isNotEmpty) {
        //print('LeadBloc: _fetchLeads - Emitting cached leads: ${leads.length}, preserved counts: $_leadCounts');
        emit(LeadDataLoaded(leads, currentPage: 1, leadCounts: Map.from(_leadCounts)));
      }
    }

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
        daysWithoutActivity: event.daysWithoutActivity,
        directoryValues: event.directoryValues,
        salesFunnelId: event.salesFunnelId,
      );

      // Кэшируем лиды БЕЗ изменения постоянных счетчиков
      await LeadCache.cacheLeadsForStatus(event.statusId, leads);
      
      // ВАЖНО: НЕ ПЕРЕЗАПИСЫВАЕМ счетчики значениями из пагинации!
      // Счетчики остаются такими, какими были в постоянном кэше
      //print('LeadBloc: _fetchLeads - Fetched ${leads.length} leads from API, but kept persistent counts: $_leadCounts');
    }

    allLeadsFetched = leads.isEmpty;
    emit(LeadDataLoaded(leads, currentPage: 1, leadCounts: Map.from(_leadCounts)));
  } catch (e) {
    //print('LeadBloc: _fetchLeads - Error: $e');
    emit(LeadError('Не удалось загрузить данные!'));
  } finally {
    isFetching = false;
  }
}




// Заменить метод _fetchLeadStatuses в LeadBloc на этот:

Future<void> _fetchLeadStatuses(FetchLeadStatuses event, Emitter<LeadState> emit) async {
  print('LeadBloc: _fetchLeadStatuses - Starting with forceRefresh: ${event.forceRefresh}');
  emit(LeadLoading());

  try {
    List<LeadStatus> response;

    // Если forceRefresh = true, игнорируем кэш и загружаем с сервера
    if (event.forceRefresh) {
      print('LeadBloc: Force refresh - loading from API');
      if (!await _checkInternetConnection()) {
        emit(LeadError('Нет подключения к интернету для обновления данных'));
        return;
      }
      response = await apiService.getLeadStatuses();
      
      // При принудительном обновлении ПОЛНОСТЬЮ ПЕРЕЗАПИСЫВАЕМ кэш
      await LeadCache.clearAllData(); // Очищаем ВСЕ данные
      await LeadCache.cacheLeadStatuses(response); // Кэшируем новые статусы
      
      // Сбрасываем локальные счетчики и устанавливаем новые
      _leadCounts.clear();
      for (var status in response) {
        _leadCounts[status.id] = status.leadsCount;
        await LeadCache.setPersistentLeadCount(status.id, status.leadsCount);
      }
      
      print('LeadBloc: Force refresh completed - new leadCounts: $_leadCounts');
      
    } else {
      // Стандартная логика с использованием кэша
      if (!await _checkInternetConnection()) {
        print('LeadBloc: No internet connection, using cache');
        final cachedStatuses = await LeadCache.getLeadStatuses();
        if (cachedStatuses.isNotEmpty) {
          final statuses = cachedStatuses.map((status) => LeadStatus.fromJson(status)).toList();
          
          // Восстанавливаем ВСЕ постоянные счетчики
          _leadCounts.clear();
          final allPersistentCounts = await LeadCache.getPersistentLeadCounts();
          for (String statusIdStr in allPersistentCounts.keys) {
            int statusId = int.parse(statusIdStr);
            int count = allPersistentCounts[statusIdStr] ?? 0;
            _leadCounts[statusId] = count;
          }
          
          print('LeadBloc: Using cached statuses with persistent counts: $_leadCounts');
          emit(LeadLoaded(statuses, leadCounts: Map.from(_leadCounts)));
        } else {
          print('LeadBloc: No cached statuses available');
          emit(LeadError('Нет подключения к интернету и нет кэшированных данных'));
        }
        return;
      }

      // Сначала проверяем кэш
      final cachedStatuses = await LeadCache.getLeadStatuses();
      if (cachedStatuses.isNotEmpty) {
        print('LeadBloc: Using cached statuses');
        response = cachedStatuses.map((status) => LeadStatus.fromJson(status)).toList();
      } else {
        print('LeadBloc: No cache found, loading from API');
        response = await apiService.getLeadStatuses();
        await LeadCache.cacheLeadStatuses(response);
      }

      // КРИТИЧНО: Восстанавливаем постоянные счетчики, если они есть, иначе используем из API
      _leadCounts.clear();
      final allPersistentCounts = await LeadCache.getPersistentLeadCounts();
      
      for (var status in response) {
        final statusIdStr = status.id.toString();
        
        // Если есть постоянный счетчик - используем его, иначе - из API
        if (allPersistentCounts.containsKey(statusIdStr)) {
          _leadCounts[status.id] = allPersistentCounts[statusIdStr] ?? 0;
          print('LeadBloc: Using persistent count for status ${status.id}: ${_leadCounts[status.id]}');
        } else {
          _leadCounts[status.id] = status.leadsCount;
          // Сохраняем как постоянный счетчик для будущего использования
          await LeadCache.setPersistentLeadCount(status.id, status.leadsCount);
          print('LeadBloc: Setting initial persistent count for status ${status.id}: ${status.leadsCount}');
        }
      }
    }

    print('LeadBloc: _fetchLeadStatuses - Final leadCounts: $_leadCounts');
    emit(LeadLoaded(response, leadCounts: Map.from(_leadCounts)));

    // После загрузки статусов, загружаем лиды для первого статуса (если есть)
    if (response.isNotEmpty) {
      final firstStatusId = response.first.id;
      print('LeadBloc: Loading leads for first status: $firstStatusId');
      add(FetchLeads(firstStatusId, ignoreCache: event.forceRefresh));
    }

  } catch (e) {
    print('LeadBloc: _fetchLeadStatuses - Error: $e');
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
    
    //print('LeadBloc: Updated lead status and counts - old: ${event.oldStatusId}($oldCount), new: ${event.newStatusId}($newCount)');
  } catch (e) {
    emit(LeadError('Не удалось обновить статус лида: $e'));
  }
}
// Метод для очистки всех счетчиков (при смене воронки)
Future<void> clearAllCountsAndCache() async {
  _leadCounts.clear();
  await LeadCache.clearAllLeads();
  await LeadCache.clearLeadStatuses();

}
/// Вызывать перед переходом между табами
Future<void> _preserveCurrentCounts() async {
  if (_leadCounts.isNotEmpty) {
    for (int statusId in _leadCounts.keys) {
      int currentCount = _leadCounts[statusId] ?? 0;
      await LeadCache.setPersistentLeadCount(statusId, currentCount);
    }
    //print('LeadBloc: Preserved all current counts: $_leadCounts');
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
  
  //print('LeadBloc: Restored all counts from persistent cache: $_leadCounts');
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

}