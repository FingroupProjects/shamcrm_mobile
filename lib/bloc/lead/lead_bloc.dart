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
    _currentHasNoReplies = event.hasNoReplies; // Новый параметр
    _currentHasUnreadMessages = event.hasUnreadMessages; // Новый параметр
    _currentHasDeal = event.hasDeal;
    _currentDaysWithoutActivity = event.daysWithoutActivity;
        _currentDirectoryValues = event.directoryValues; // Сохраняем текущие значения


    if (!await _checkInternetConnection()) {
      final cachedLeads = await LeadCache.getLeadsForStatus(event.statusId);
      if (cachedLeads.isNotEmpty) {
        emit(LeadDataLoaded(cachedLeads, currentPage: 1, leadCounts: {}));
      } else {
        emit(LeadError('Нет подключения к интернету и нет данных в кэше!'));
      }
      return;
    }

    try {
      final cachedLeads = await LeadCache.getLeadsForStatus(event.statusId);
      if (cachedLeads.isNotEmpty) {
        emit(LeadDataLoaded(cachedLeads, currentPage: 1, leadCounts: {}));
      }

      final leads = await apiService.getLeads(
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
        hasNoReplies: event.hasNoReplies, // Новый параметр
        hasUnreadMessages: event.hasUnreadMessages, // Новый параметр
        hasDeal: event.hasDeal,
        daysWithoutActivity: event.daysWithoutActivity,
                directoryValues: event.directoryValues, // Передаем в API

      );

      await LeadCache.cacheLeadsForStatus(event.statusId, leads);

      final leadCounts = Map<int, int>.from(_leadCounts);
      for (var lead in leads) {
        leadCounts[lead.statusId] = (leadCounts[lead.statusId] ?? 0) + 1;
      }

      allLeadsFetched = leads.isEmpty;
      emit(LeadDataLoaded(leads, currentPage: 1, leadCounts: leadCounts));
    } catch (e) {
      emit(LeadError('Не удалось загрузить данные!'));
    }
  }

  Future<void> _fetchLeadStatuses(FetchLeadStatuses event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    final cachedStatuses = await LeadCache.getLeadStatuses();
    if (cachedStatuses.isNotEmpty) {
      emit(LeadLoaded(
        cachedStatuses.map((status) => LeadStatus.fromJson(status)).toList(),
        leadCounts: Map.from(_leadCounts),
      ));
    }

    if (!await _checkInternetConnection()) {
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      final response = await apiService.getLeadStatuses();
      await LeadCache.cacheLeadStatuses(response
          .map((status) => {'id': status.id, 'title': status.title})
          .toList());

      final futures = response.map((status) {
        return apiService.getLeads(status.id, page: 1, perPage: 1);
      }).toList();

      final leadCountsResults = await Future.wait(futures);

      for (int i = 0; i < response.length; i++) {
        _leadCounts[response[i].id] = leadCountsResults[i].length;
      }

      emit(LeadLoaded(response, leadCounts: Map.from(_leadCounts)));
    } catch (e) {
      emit(LeadError('Не удалось загрузить данные!'));
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

      // Добавляем lead_custom_fields только если они не пустые
      if (event.customFields != null && event.customFields!.isNotEmpty) {
        requestData['lead_custom_fields'] = event.customFields!.map((field) => {
              'key': field.keys.first,
              'value': field.values.first,
            }).toList();
      }

      // Добавляем directory_values только если они не пустые
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

      final result = await apiService.createLeadWithData(requestData);

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

  // Проверка подключения к интернету
  if (!await _checkInternetConnection()) {
    emit(LeadError(event.localizations.translate('no_internet_connection')));
    return;
  }

  try {
    // Формируем данные для отправки
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
      'lead_custom_fields': event.customFields?.map((field) => {
            'key': field.keys.first,
            'value': field.values.first,
          }).toList() ?? [],
      'directory_values': event.directoryValues ?? [], // Добавляем справочные поля
    };

    // Обработка менеджера
    if (event.isSystemManager) {
      requestData['manager_id'] = 0; // Для "Системы" отправляем manager_id = 0
    } else if (event.managerId != null) {
      requestData['manager_id'] = event.managerId;
    }

    // Вызов метода обновления лида
    final result = await apiService.updateLeadWithData(
      leadId: event.leadId,
      data: requestData,
    );

    // Если успешно, то обновляем состояние
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
}
