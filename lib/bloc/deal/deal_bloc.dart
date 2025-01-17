import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'deal_event.dart';
import 'deal_state.dart';

class DealBloc extends Bloc<DealEvent, DealState> {
  final ApiService apiService;
  bool allDealsFetched =
      false; // Переменная для отслеживания завершения загрузки
  Map<int, int> _dealCounts =
      {}; // Приватное поле для хранения количества сделок

  DealBloc(this.apiService) : super(DealInitial()) {
    on<FetchDealStatuses>(_fetchDealStatuses);
    on<FetchDeals>(_fetchDeals);
    on<CreateDeal>(_createDeal);
    on<FetchMoreDeals>(_fetchMoreDeals);
    on<CreateDealStatus>(_createDealStatus);
    on<UpdateDeal>(_updateDeal);
    on<DeleteDeal>(_deleteDeal);
    on<DeleteDealStatuses>(_deleteDealStatuses);
  }

  // Метод для загрузки сделок с учётом кэша
Future<void> _fetchDeals(FetchDeals event, Emitter<DealState> emit) async {
  emit(DealLoading());

  if (!await _checkInternetConnection()) {
    // Если интернета нет, пробуем загрузить сделки из кэша
    final cachedDeals = await DealCache.getDealsForStatus(event.statusId);
    if (cachedDeals.isNotEmpty) {
      emit(DealDataLoaded(cachedDeals, currentPage: 1, dealCounts: {}));
    } else {
      emit(DealError('Нет подключения к интернету и нет данных в кэше!'));
    }
    return;
  }

  try {
    // Сначала пробуем загрузить сделки из кэша
    final cachedDeals = await DealCache.getDealsForStatus(event.statusId);
    if (cachedDeals.isNotEmpty) {
      emit(DealDataLoaded(cachedDeals, currentPage: 1, dealCounts: {}));
    }

    // Затем запрашиваем данные из API
    final deals = await apiService.getDeals(
      event.statusId,
      page: 1,
      perPage: 20,
      search: event.query,
      managerId: event.managerId,
    );

    // Сохраняем сделки в кэш
    await DealCache.cacheDealsForStatus(event.statusId, deals);

    // Обновляем состояние
    final dealCounts = Map<int, int>.from(_dealCounts);
    for (var deal in deals) {
      dealCounts[deal.statusId] = (dealCounts[deal.statusId] ?? 0) + 1;
    }

    allDealsFetched = deals.isEmpty;
    emit(DealDataLoaded(deals, currentPage: 1, dealCounts: dealCounts));
  } catch (e) {
    emit(DealError('Не удалось загрузить данные!'));
  }
}

// Метод для загрузки статусов сделок с учётом кэша
Future<void> _fetchDealStatuses(FetchDealStatuses event, Emitter<DealState> emit) async {
  emit(DealLoading());

  // Сначала пробуем получить данные из кэша
  final cachedStatuses = await DealCache.getDealStatuses();
  if (cachedStatuses.isNotEmpty) {
    emit(DealLoaded(
      cachedStatuses.map((status) => DealStatus.fromJson(status)).toList(),
      dealCounts: Map.from(_dealCounts),
    ));
  }

  // Затем запрашиваем данные из API
  if (!await _checkInternetConnection()) {
    emit(DealError('Нет подключения к интернету'));
    return;
  }

  try {
    final response = await apiService.getDealStatuses();
    if (response.isEmpty) {
      emit(DealError('Нет статусов'));
      return;
    }

    // Сохраняем статусы в кэш
    await DealCache.cacheDealStatuses(
      response.map((status) => {'id': status.id, 'title': status.title}).toList(),
    );

    // Параллельно загружаем количество сделок для каждого статуса
    final futures = response.map((status) {
      return apiService.getDeals(status.id, page: 1, perPage: 1);
    }).toList();

    final dealCountsResults = await Future.wait(futures);

    // Обновляем количество сделок
    for (int i = 0; i < response.length; i++) {
      _dealCounts[response[i].id] = dealCountsResults[i].length;
    }

    emit(DealLoaded(response, dealCounts: Map.from(_dealCounts)));
  } catch (e) {
    emit(DealError('Не удалось загрузить данные!'));
  }
}


  Future<void> _fetchMoreDeals(
      FetchMoreDeals event, Emitter<DealState> emit) async {
    if (allDealsFetched)
      return; // Если все сделки уже загружены, ничего не делаем

    if (!await _checkInternetConnection()) {
      emit(DealError('Нет подключения к интернету'));
      return;
    }

    try {
      final deals = await apiService.getDeals(event.statusId,
          page: event.currentPage + 1);
      if (deals.isEmpty) {
        allDealsFetched = true;
        return;
      }
      if (state is DealDataLoaded) {
        final currentState = state as DealDataLoaded;
        emit(currentState.merge(deals)); // Объединяем старые и новые сделки
      }
    } catch (e) {
      emit(DealError('Не удалось загрузить дополнительные сделки!'));
    }
  }

  Future<void> _createDealStatus(
      CreateDealStatus event, Emitter<DealState> emit) async {
    emit(DealLoading());

    if (!await _checkInternetConnection()) {
      emit(DealError('Нет подключения к интернету'));
      return;
    }

    try {
      final result = await apiService.createDealStatus(
          event.title, event.color, event.day);

      if (result['success']) {
        emit(DealSuccess(result['message']));
        add(FetchDealStatuses());
      } else {
        emit(DealError(result['message']));
      }
    } catch (e) {
      emit(DealError('Ошибка создания статуса Сделки!'));
    }
  }

  Future<void> _createDeal(CreateDeal event, Emitter<DealState> emit) async {
    emit(DealLoading());
    if (!await _checkInternetConnection()) {
      emit(DealError('Нет подключения к интернету'));
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
      );
      if (result['success']) {
        emit(DealSuccess('Сделка успешно создана'));
        // add(FetchDeals(event.dealStatusId));
      } else {
        emit(DealError(result['message']));
      }
    } catch (e) {
      emit(DealError('Ошибка создания сделки!'));
    }
  }

  Future<void> _updateDeal(UpdateDeal event, Emitter<DealState> emit) async {
    emit(DealLoading());

    if (!await _checkInternetConnection()) {
      emit(DealError('Нет подключения к интернету'));
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
        sum: event.sum,
        description: event.description,
        dealtypeId: event.dealtypeId,
        leadId: event.leadId,
        customFields: event.customFields,
      );

      if (result['success']) {
        emit(DealSuccess('Сделка успешно обновлена'));
        // add(FetchDeals(event.dealStatusId));
      } else {
        emit(DealError(result['message']));
      }
    } catch (e) {
      emit(DealError('Ошибка обновления сделки!'));
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
        emit(DealDeleted('Сделка успешно удалена'));
      } else {
        emit(DealError('Ошибка удаления сделки'));
      }
    } catch (e) {
      emit(DealError('Ошибка удаления сделки!'));
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
        emit(DealDeleted('Статус сделки успешно удален'));
      } else {
        emit(DealError('Ошибка удаления статуса сделки'));
      }
    } catch (e) {
      emit(DealError('Ошибка удаления статуса сделки!'));
    }
  }
}
