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
      on<UpdateLeadStatusLocally>(_updateLeadStatusLocally);
  on<RefreshLeadCounts>(_refreshLeadCounts);
  on<MoveLeadBetweenStatuses>(_moveLeadBetweenStatuses);
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
    print('LeadBloc: _fetchLeads - Already fetching, skipping');
    return;
  }
  isFetching = true;
  try {
    print('LeadBloc: _fetchLeads - statusId: ${event.statusId}, salesFunnelId: ${event.salesFunnelId}, ignoreCache: ${event.ignoreCache}');
    emit(LeadLoading());

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

    List<Lead> leads = [];
    if (!event.ignoreCache) {
      leads = await LeadCache.getLeadsForStatus(event.statusId);
      if (leads.isNotEmpty) {
        print('LeadBloc: _fetchLeads - Emitting cached leads: ${leads.length}');
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

      // Кэшируем лиды
      await LeadCache.cacheLeadsForStatus(event.statusId, leads);
      // Обновляем leads_count в кэше
      await LeadCache.updateLeadCount(event.statusId, leads.length);
      print('LeadBloc: _fetchLeads - Cached leads for statusId: ${event.statusId}, count: ${leads.length}');
    }

    _leadCounts[event.statusId] = leads.length;
    allLeadsFetched = leads.isEmpty;
    emit(LeadDataLoaded(leads, currentPage: 1, leadCounts: Map.from(_leadCounts)));
  } catch (e) {
    print('LeadBloc: _fetchLeads - Error: $e');
    emit(LeadError('Не удалось загрузить данные!'));
  } finally {
    isFetching = false;
  }
}
 Future<void> _fetchLeadStatuses(FetchLeadStatuses event, Emitter<LeadState> emit) async {
  print('LeadBloc: _fetchLeadStatuses - Starting');
  emit(LeadLoading());

  if (!await _checkInternetConnection()) {
    print('LeadBloc: _fetchLeadStatuses - No internet connection');
    final cachedStatuses = await LeadCache.getLeadStatuses();
    if (cachedStatuses.isNotEmpty) {
      final statuses = cachedStatuses.map((status) => LeadStatus.fromJson(status)).toList();
      print('LeadBloc: _fetchLeadStatuses - Emitting cached statuses: ${statuses.map((s) => {'id': s.id, 'title': s.title, 'leads_count': s.leadsCount})}');
      emit(LeadLoaded(statuses, leadCounts: Map.from(_leadCounts)));
    } else {
      print('LeadBloc: _fetchLeadStatuses - No cached statuses available');
      emit(LeadError('Нет подключения к интернету и нет кэшированных данных'));
    }
    return;
  }

  try {
    final response = await apiService.getLeadStatuses();
    print('LeadBloc: _fetchLeadStatuses - Retrieved statuses: ${response.map((s) => {'id': s.id, 'title': s.title, 'leads_count': s.leadsCount})}');

    // Кэшируем статусы
    await LeadCache.cacheLeadStatuses(response);

    // Обновляем счетчики
    final futures = response.map((status) async {
      final leads = await apiService.getLeads(status.id, page: 1, perPage: 1);
      return {status.id: leads.length};
    }).toList();

    final leadCountsResults = await Future.wait(futures);
    _leadCounts.clear();
    for (var result in leadCountsResults) {
      _leadCounts.addAll(result);
    }

    print('LeadBloc: _fetchLeadStatuses - Emitting LeadLoaded with statuses: ${response.map((s) => {'id': s.id, 'title': s.title, 'leads_count': s.leadsCount})}');
    emit(LeadLoaded(response, leadCounts: Map.from(_leadCounts)));
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
  Future<void> _updateLeadStatusLocally(UpdateLeadStatusLocally event, Emitter<LeadState> emit) async {
  if (state is! LeadDataLoaded) return;
  
  final currentState = state as LeadDataLoaded;
  
  try {
    if (event.refreshCurrentStatus) {
      print('LeadBloc: _updateLeadStatusLocally - Refreshing status ${event.statusId}');
      
      // Получаем новые лиды только для этого статуса
      final newLeads = await apiService.getLeads(
        event.statusId,
        page: 1,
        perPage: 50,
      );
      
      // Обновляем только лиды этого статуса
      final List<Lead> updatedLeads = List.from(currentState.leads);
      updatedLeads.removeWhere((lead) => lead.statusId == event.statusId);
      updatedLeads.addAll(newLeads);
      
      // Обновляем счетчики
      final Map<int, int> newLeadCounts = Map.from(currentState.leadCounts);
      newLeadCounts[event.statusId] = newLeads.length;
      
      // Кэшируем обновленные данные
      await LeadCache.cacheLeadsForStatus(event.statusId, newLeads);
      await LeadCache.updateLeadCount(event.statusId, newLeads.length);
      
      emit(LeadDataLoaded(
        updatedLeads,
        currentPage: currentState.currentPage,
        leadCounts: newLeadCounts,
      ));
      
      print('LeadBloc: _updateLeadStatusLocally - Status ${event.statusId} updated with ${newLeads.length} leads');
    }
  } catch (e) {
    print('LeadBloc: _updateLeadStatusLocally - Error: $e');
    // Не показываем ошибку пользователю, просто логируем
  }
}

Future<void> _refreshLeadCounts(RefreshLeadCounts event, Emitter<LeadState> emit) async {
  if (state is! LeadDataLoaded) return;
  
  final currentState = state as LeadDataLoaded;
  
  try {
    print('LeadBloc: _refreshLeadCounts - Updating all lead counts');
    
    // Получаем статусы с актуальными счетчиками
    final statuses = await apiService.getLeadStatuses();
    final Map<int, int> newLeadCounts = {};
    
    for (var status in statuses) {
      newLeadCounts[status.id] = status.leadsCount;
    }
    
    emit(LeadDataLoaded(
      currentState.leads,
      currentPage: currentState.currentPage,
      leadCounts: newLeadCounts,
    ));
    
    print('LeadBloc: _refreshLeadCounts - Lead counts updated: $newLeadCounts');
  } catch (e) {
    print('LeadBloc: _refreshLeadCounts - Error: $e');
  }
}

Future<void> _moveLeadBetweenStatuses(MoveLeadBetweenStatuses event, Emitter<LeadState> emit) async {
  if (state is! LeadDataLoaded) return;
  
  final currentState = state as LeadDataLoaded;
  final List<Lead> updatedLeads = List.from(currentState.leads);
  final Map<int, int> newLeadCounts = Map.from(currentState.leadCounts);
  
  // Находим и обновляем лид
  final leadIndex = updatedLeads.indexWhere((lead) => lead.id == event.leadId);
  if (leadIndex != -1) {
    final updatedLead = Lead.fromJson(event.updatedLeadData, event.toStatusId);
    updatedLeads[leadIndex] = updatedLead;
    
    // Обновляем счетчики только если статус действительно изменился
    if (event.fromStatusId != event.toStatusId) {
      newLeadCounts[event.fromStatusId] = (newLeadCounts[event.fromStatusId] ?? 1) - 1;
      newLeadCounts[event.toStatusId] = (newLeadCounts[event.toStatusId] ?? 0) + 1;
      
      print('LeadBloc: _moveLeadBetweenStatuses - Lead ${event.leadId} moved from ${event.fromStatusId} to ${event.toStatusId}');
      print('LeadBloc: _moveLeadBetweenStatuses - New counts: ${event.fromStatusId}: ${newLeadCounts[event.fromStatusId]}, ${event.toStatusId}: ${newLeadCounts[event.toStatusId]}');
    }
    
    emit(LeadDataLoaded(
      updatedLeads,
      currentPage: currentState.currentPage,
      leadCounts: newLeadCounts,
    ));
    
    // Обновляем кэш
    await LeadCache.updateLeadCount(event.fromStatusId, newLeadCounts[event.fromStatusId] ?? 0);
    await LeadCache.updateLeadCount(event.toStatusId, newLeadCounts[event.toStatusId] ?? 0);
  }
}
}
