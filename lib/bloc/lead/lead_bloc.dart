import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'lead_event.dart';
import 'lead_state.dart';

class LeadBloc extends Bloc<LeadEvent, LeadState> {
  final ApiService apiService;
  bool allLeadsFetched = false;
  Map<int, int> _leadCounts = {}; // Хранение количества лидов

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
  }

  // Метод для загрузки лидов с учётом кэша
  Future<void> _fetchLeads(FetchLeads event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    if (!await _checkInternetConnection()) {
      // Если интернета нет, пробуем загрузить лиды из кэша
      final cachedLeads = await LeadCache.getLeadsForStatus(event.statusId);
      if (cachedLeads.isNotEmpty) {
        emit(LeadDataLoaded(cachedLeads, currentPage: 1, leadCounts: {}));
      } else {
        emit(LeadError('Нет подключения к интернету и нет данных в кэше!'));
      }
      return;
    }

    try {
      // Сначала пробуем загрузить лиды из кэша
      final cachedLeads = await LeadCache.getLeadsForStatus(event.statusId);
      if (cachedLeads.isNotEmpty) {
        emit(LeadDataLoaded(cachedLeads, currentPage: 1, leadCounts: {}));
      }

      // Затем запрашиваем данные из API
      final leads = await apiService.getLeads(
        event.statusId,
        page: 1,
        perPage: 20,
        search: event.query,
        managerId: event.managerId,
      );

      // Сохраняем лиды в кэш
      await LeadCache.cacheLeadsForStatus(event.statusId, leads);

      // Обновляем состояние
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

  Future<void> _fetchLeadStatuses(
      FetchLeadStatuses event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    // Try fetching data from cache first
    final cachedStatuses = await LeadCache.getLeadStatuses();
    if (cachedStatuses.isNotEmpty) {
      emit(LeadLoaded(
        cachedStatuses.map((status) => LeadStatus.fromJson(status)).toList(),
        leadCounts: Map.from(_leadCounts),
      ));
    }

    // Then fetch from API
    if (!await _checkInternetConnection()) {
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      final response = await apiService.getLeadStatuses();
      if (response.isEmpty) {
        emit(LeadError('Нет статусов'));
        return;
      }

      // Cache the statuses
      await LeadCache.cacheLeadStatuses(response
          .map((status) => {'id': status.id, 'title': status.title})
          .toList());

      // Fetch lead counts for all statuses in parallel
      final futures = response.map((status) {
        return apiService.getLeads(status.id, page: 1, perPage: 1);
      }).toList();

      final leadCountsResults = await Future.wait(futures);

      // Update lead counts
      for (int i = 0; i < response.length; i++) {
        _leadCounts[response[i].id] = leadCountsResults[i].length;
      }

      emit(LeadLoaded(response, leadCounts: Map.from(_leadCounts)));
    } catch (e) {
      emit(LeadError('Не удалось загрузить данные!'));
    }
  }

  // Метод для загрузки всех лидов
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
      emit(LeadError('Не удалось загрузить лиды!'));
    }
  }

  Future<void> _fetchMoreLeads(
      FetchMoreLeads event, Emitter<LeadState> emit) async {
    if (allLeadsFetched)
      return; // Если все лиды уже загружены, ничего не делаем

    if (!await _checkInternetConnection()) {
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      final leads = await apiService.getLeads(event.statusId,
          page: event.currentPage + 1);
      if (leads.isEmpty) {
        allLeadsFetched = true; // Если пришли пустые данные, устанавливаем флаг
        return; // Выходим, так как данных больше нет
      }
      if (state is LeadDataLoaded) {
        final currentState = state as LeadDataLoaded;
        emit(currentState.merge(leads)); // Объединяем старые и новые лиды
      }
    } catch (e) {
      emit(LeadError('Не удалось загрузить дополнительные лиды!'));
    }
  }

  Future<void> _createLead(CreateLead event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    // Проверка подключения к интернету
    if (!await _checkInternetConnection()) {
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      // Вызов метода создания лида
      final result = await apiService.createLead(
        name: event.name,
        leadStatusId: event.leadStatusId,
        phone: event.phone,
        regionId: event.regionId,
        managerId: event.managerId,
        sourceId: event.sourceId,
        instaLogin: event.instaLogin,
        facebookLogin: event.facebookLogin,
        tgNick: event.tgNick,
        birthday: event.birthday,
        email: event.email,
        description: event.description,
        waPhone: event.waPhone,
        customFields: event.customFields,
      );

      // Если успешно, то обновляем состояние
      if (result['success']) {
        emit(LeadSuccess('Лид успешно создан!'));
        // Передаем статус лида (event.leadStatusId) в событие FetchLeads
        // add(FetchLeads(event.leadStatusId));
      } else {
        // Если есть ошибка, отображаем сообщение об ошибке
        emit(LeadError(result['message']));
      }
    } catch (e) {
      // Логирование ошибки
      emit(LeadError('Ошибка создания лида!'));
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
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      // Вызов метода обновления лида
      final result = await apiService.updateLead(
        leadId: event.leadId,
        name: event.name,
        leadStatusId: event.leadStatusId,
        phone: event.phone,
        regionId: event.regionId,
        sourceId: event.sourseId,
        managerId: event.managerId,
        instaLogin: event.instaLogin,
        facebookLogin: event.facebookLogin,
        tgNick: event.tgNick,
        birthday: event.birthday,
        email: event.email,
        description: event.description,
        waPhone: event.waPhone,
        customFields: event.customFields,
      );

      // Если успешно, то обновляем состояние
      if (result['success']) {
        emit(LeadSuccess('Лид успешно обновлен!'));
        // add(FetchLeads(event.leadStatusId)); // Обновляем список лидов
      } else {
        emit(LeadError(result['message']));
      }
    } catch (e) {
      emit(LeadError('Ошибка обновления лида!'));
    }
  }

  Future<void> _createLeadStatus(
      CreateLeadStatus event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    if (!await _checkInternetConnection()) {
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      final result =
          await apiService.createLeadStatus(event.title, event.color);

      if (result['success']) {
        emit(LeadSuccess(result['message']));
        add(FetchLeadStatuses());
      } else {
        emit(LeadError(result['message']));
      }
    } catch (e) {
      emit(LeadError('Ошибка создания статуса лида!'));
    }
  }

  Future<void> _deleteLead(DeleteLead event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    try {
      final response = await apiService.deleteLead(event.leadId);
      if (response['result'] == 'Success') {
        emit(LeadDeleted('Лид успешно удален!'));
      } else {
        emit(LeadError('Ошибка удаления лида!'));
      }
    } catch (e) {
      emit(LeadError('Ошибка удаления лида!'));
    }
  }

  Future<void> _deleteLeadStatuses(
      DeleteLeadStatuses event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    try {
      final response = await apiService.deleteLeadStatuses(event.leadStatusId);
      if (response['result'] == 'Success') {
        emit(LeadDeleted('Статус Лида успешно удалена'));
      } else {
        emit(LeadError('Ошибка удаления статуса лида'));
      }
    } catch (e) {
      emit(LeadError('Ошибка удаления статуса лида!'));
    }
  }
}
