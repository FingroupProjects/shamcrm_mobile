import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'deal_event.dart';
import 'deal_state.dart';

class DealBloc extends Bloc<DealEvent, DealState> {
  final ApiService apiService;
  bool allDealsFetched = false; 
  bool isFetching = false;
  Map<int, int> _dealCounts = {}; 
  String? _currentQuery;
  List<int>? _currentManagerIds;
  int? _currentStatusId;
  DateTime? _currentFromDate;
  DateTime? _currentToDate;
  List<int>? _currentLeadIds;
  bool? _currentHasTasks;
  int? _currentDaysWithoutActivity;
  List<Map<String, dynamic>>? _currentDirectoryValues;
  List<String>? _currentNames;
  Map<String, List<String>>? _currentCustomFieldFilters;

  DealBloc(this.apiService) : super(DealInitial()) {
    on<FetchDealStatuses>(_fetchDealStatuses);
    on<FetchDeals>(_fetchDeals);
    on<CreateDeal>(_createDeal);
    on<FetchMoreDeals>(_fetchMoreDeals);
    on<CreateDealStatus>(_createDealStatus);
    on<UpdateDeal>(_updateDeal);
    on<DeleteDeal>(_deleteDeal);
    on<DeleteDealStatuses>(_deleteDealStatuses);
    on<UpdateDealStatusEdit>(_updateDealStatusEdit);
    on<FetchDealStatus>(_fetchDealStatus);
  }

  Future<void> _fetchDealStatus(FetchDealStatus event, Emitter<DealState> emit) async {
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
      //print('DealBloc: _fetchDeals - Already fetching, skipping');
      return;
    }
    isFetching = true;
    try {
      //print('DealBloc: _fetchDeals - statusId: ${event.statusId}, salesFunnelId: ${event.salesFunnelId}');
      emit(DealLoading());

      _currentQuery = event.query;
      _currentManagerIds = event.managerIds;
      _currentStatusId = event.statusIds;
      _currentFromDate = event.fromDate;
      _currentToDate = event.toDate;
      _currentLeadIds = event.leadIds;
      _currentHasTasks = event.hasTasks;
      _currentDaysWithoutActivity = event.daysWithoutActivity;
      _currentDirectoryValues = event.directoryValues;
      _currentNames = event.names;
      _currentCustomFieldFilters = event.customFieldFilters;

      if (!await _checkInternetConnection()) {
        //print('DealBloc: _fetchDeals - No internet connection');
        final cachedDeals = await DealCache.getDealsForStatus(event.statusId);
        if (cachedDeals.isNotEmpty) {
          emit(DealDataLoaded(cachedDeals, currentPage: 1, dealCounts: {}));
          emit(DealWarning('Используются кэшированные данные из-за отсутствия интернета'));
        } else {
          emit(DealError('Нет подключения к интернету и нет данных в кэше!'));
        }
        return;
      }

      final cachedDeals = await DealCache.getDealsForStatus(event.statusId);
      if (cachedDeals.isNotEmpty) {
        //print('DealBloc: _fetchDeals - Emitting cached deals: ${cachedDeals.length}');
        emit(DealDataLoaded(cachedDeals, currentPage: 1, dealCounts: {}));
      }

      final deals = await apiService.getDeals(
        event.statusId,
        page: 1,
        perPage: 20,
        search: event.query,
        managers: event.managerIds,
        statuses: event.statusIds,
        fromDate: event.fromDate,
        toDate: event.toDate,
        leads: event.leadIds,
        hasTasks: event.hasTasks,
        daysWithoutActivity: event.daysWithoutActivity,
        directoryValues: event.directoryValues,
        names: event.names,
        salesFunnelId: event.salesFunnelId,
        customFieldFilters: event.customFieldFilters,
      );

      await DealCache.cacheDealsForStatus(event.statusId, deals);
      //print('DealBloc: _fetchDeals - Cached deals for statusId: ${event.statusId}, count: ${deals.length}');

      final dealCounts = Map<int, int>.from(_dealCounts);
      for (var deal in deals) {
        dealCounts[deal.statusId] = (dealCounts[deal.statusId] ?? 0) + 1;
      }

      allDealsFetched = deals.isEmpty;
      emit(DealDataLoaded(deals, currentPage: 1, dealCounts: dealCounts));
    } catch (e) {
      //print('DealBloc: _fetchDeals - Error: $e');
      emit(DealError('Не удалось загрузить данные!'));
    } finally {
      isFetching = false;
    }
  }

  // ✅ ИСПРАВЛЕННЫЙ МЕТОД - убрали двойной emit
  Future<void> _fetchDealStatuses(
      FetchDealStatuses event, Emitter<DealState> emit) async {
    debugPrint("DealBloc: _fetchDealStatuses called");
    emit(DealLoading());

    // ✅ ИЗМЕНЕНИЕ 1: Проверяем интернет ПЕРЕД кэшем
    final hasInternet = await _checkInternetConnection();
    
    if (!hasInternet) {
      debugPrint("DealBloc: No internet, using cache only");
      final cachedStatuses = await DealCache.getDealStatuses();
      if (cachedStatuses.isNotEmpty) {
        emit(DealLoaded(
          cachedStatuses.map((status) => DealStatus.fromJson(status)).toList(),
          dealCounts: Map.from(_dealCounts),
        ));
        debugPrint("DealBloc: Emitted ${cachedStatuses.length} statuses from cache");
      } else {
        emit(DealError('Нет подключения к интернету и нет данных в кэше'));
      }
      return;
    }

    // ✅ ИЗМЕНЕНИЕ 2: Если есть интернет, грузим только из API (без промежуточного emit кэша)
    try {
      debugPrint("DealBloc: _fetchDealStatuses - Fetching from API");
      final response = await apiService.getDealStatuses();

      // Сохраняем статусы в кэш
      await DealCache.cacheDealStatuses(
        response
            .map((status) => {'id': status.id, 'title': status.title})
            .toList(),
      );
      debugPrint("DealBloc: cached deal statuses: ${response.length}");

      // Параллельно загружаем количество сделок для каждого статуса
      final futures = response.map((status) {
        debugPrint("DealBloc: Fetching deal count for status ID: ${status.id}");
        return apiService.getDeals(status.id, page: 1, perPage: 1);
      }).toList();

      final dealCountsResults = await Future.wait(futures);
      debugPrint("DealBloc: dealCountsResults fetched for ${dealCountsResults.length} statuses");

      // Обновляем количество сделок
      for (int i = 0; i < response.length; i++) {
        debugPrint("DealBloc: Status ID: ${response[i].id}, Deal Count: ${dealCountsResults[i].length}");
        _dealCounts[response[i].id] = dealCountsResults[i].length;
      }

      // ✅ КРИТИЧНО: Только ОДИН emit с финальными данными
      emit(DealLoaded(response, dealCounts: Map.from(_dealCounts)));
      debugPrint("DealBloc: ✅ Emitted DealLoaded with ${response.length} statuses");
      
    } catch (e) {
      debugPrint("DealBloc: Error fetching statuses: $e");
      
      // При ошибке пробуем загрузить из кэша
      final cachedStatuses = await DealCache.getDealStatuses();
      if (cachedStatuses.isNotEmpty) {
        emit(DealLoaded(
          cachedStatuses.map((status) => DealStatus.fromJson(status)).toList(),
          dealCounts: Map.from(_dealCounts),
        ));
        emit(DealWarning('Ошибка загрузки, используются кэшированные данные'));
      } else {
        emit(DealError('Не удалось загрузить статусы: ${e.toString()}'));
      }
    }
  }

  Future<void> _fetchMoreDeals(FetchMoreDeals event, Emitter<DealState> emit) async {
    if (allDealsFetched) return;

    if (!await _checkInternetConnection()) {
      emit(DealError('Нет подключения к интернету'));
      return;
    }

    try {
      final deals = await apiService.getDeals(
        _currentStatusId ?? event.statusId,
        page: event.currentPage + 1,
        perPage: 20,
        search: _currentQuery,
        managers: _currentManagerIds,
        statuses: _currentStatusId,
        fromDate: _currentFromDate,
        toDate: _currentToDate,
        leads: _currentLeadIds,
        hasTasks: _currentHasTasks,
        daysWithoutActivity: _currentDaysWithoutActivity,
        directoryValues: _currentDirectoryValues,
        customFieldFilters: _currentCustomFieldFilters,
      );

      if (deals.isEmpty) {
        allDealsFetched = true;
        return;
      }

      if (state is DealDataLoaded) {
        final currentState = state as DealDataLoaded;
        emit(currentState.merge(deals));
      }
    } catch (e) {
      emit(DealError('Не удалось загрузить дополнительные сделки!'));
    }
  }

  Future<void> _createDealStatus(CreateDealStatus event, Emitter<DealState> emit) async {
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
        event.userIds,
      );

      if (result['success']) {
        emit(DealSuccess(result['message']));
        add(FetchDealStatuses());
      } else {
        emit(DealError(result['message']));
      }
    } catch (e) {
      emit(DealError(event.localizations.translate('error_delete_status_deal')));
    }
  }

  Future<void> _createDeal(CreateDeal event, Emitter<DealState> emit) async {
    emit(DealLoading());
    if (!await _checkInternetConnection()) {
      emit(DealError(event.localizations.translate('no_internet_connection')));
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
      );
      if (result['success']) {
        emit(DealSuccess(event.localizations.translate('deal_created_successfully')));
      } else {
        emit(DealError(event.localizations.translate(result['message'])));
      }
    } catch (e) {
      emit(DealError(event.localizations.translate('error_deal_create_successfully')));
    }
  }

  Future<void> _updateDeal(UpdateDeal event, Emitter<DealState> emit) async {
    emit(DealLoading());

    if (!await _checkInternetConnection()) {
      emit(DealError(event.localizations.translate('no_internet_connection')));
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
      );

      if (result['success']) {
        emit(DealSuccess(event.localizations.translate('deal_updated_successfully')));
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
        event.notificationMessage,
        event.showOnMainPage,
        event.userIds,
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
}