import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'deal_event.dart';
import 'deal_state.dart';

class DealBloc extends Bloc<DealEvent, DealState> {
  final ApiService apiService;
  bool allDealsFetched =
      false; // Переменная для отслеживания статуса завершения загрузки сделок

  DealBloc(this.apiService) : super(DealInitial()) {
    on<FetchDealStatuses>(_fetchDealStatuses);
    on<FetchDeals>(_fetchDeals);
    on<CreateDeal>(_createDeal);
    on<FetchMoreDeals>(_fetchMoreDeals);
    on<CreateDealStatus>(_createDealStatus);
    // on<UpdateDeal>(_updateDeal);
  }

  Future<void> _fetchDealStatuses(
      FetchDealStatuses event, Emitter<DealState> emit) async {
    emit(DealLoading());

    await Future.delayed(Duration(milliseconds: 500)); // Небольшая задержка

    if (!await _checkInternetConnection()) {
      emit(DealError('Нет подключения к интернету'));
      return;
    }

    try {
      final response = await apiService.getDealStatuses();
      if (response.isEmpty) {
        emit(DealError('Ответ пустой'));
        return;
      }
      emit(DealLoaded(response));
    } catch (e) {
      emit(DealError('Не удалось загрузить данные: ${e.toString()}'));
    }
  }

  // Метод для загрузки лидов
  Future<void> _fetchDeals(FetchDeals event, Emitter<DealState> emit) async {
    emit(DealLoading());
    if (!await _checkInternetConnection()) {
      emit(DealError('Нет подключения к интернету'));
      return;
    }

    try {
      final deals = await apiService.getDeals(event.statusId);
      allDealsFetched = deals.isEmpty; // Если сделок нет, устанавливаем флаг
      emit(DealDataLoaded(deals,
          currentPage: 1)); // Устанавливаем текущую страницу на 1
    } catch (e) {
      emit(DealError('Не удалось загрузить лиды: ${e.toString()}'));
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
        allDealsFetched = true; // Если пришли пустые данные, устанавливаем флаг
        return; // Выходим, так как данных больше нет
      }
      if (state is DealDataLoaded) {
        final currentState = state as DealDataLoaded;
        emit(currentState.merge(deals)); // Объединяем старые и новые сделки
      }
    } catch (e) {
      emit(DealError(
          'Не удалось загрузить дополнительные сделки: ${e.toString()}'));
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
      final result =
          await apiService.createDealStatus(event.title, event.color);

      if (result['success']) {
        emit(DealSuccess(result['message']));
        add(FetchDealStatuses());
      } else {
        emit(DealError(result['message']));
      }
    } catch (e) {
      emit(DealError('Ошибка создания статуса Сделки: ${e.toString()}'));
    }
  }

  Future<void> _createDeal(CreateDeal event, Emitter<DealState> emit) async {
    emit(DealLoading());

    // Проверка подключения к интернету
    if (!await _checkInternetConnection()) {
      emit(DealError('Нет подключения к интернету'));
      return;
    }

    try {
      // Вызов метода создания лида
      final result = await apiService.createDeal(
        name: event.name,
        dealStatusId: event.dealStatusId,
        managerId: event.managerId,
        startDate: event.startDate,
        endDate: event.endDate,
        sum: event.sum,
        description: event.description,
        organizationId: event.organizationId,
        dealtypeId: event.dealtypeId,
        leadId: event.leadId,
        currencyId: event.currencyId, 
      );

      // Если успешно, то обновляем состояние
      if (result['success']) {
        emit(DealSuccess('Сделка создан успешно'));
        add(FetchDeals(event.dealStatusId));
      } else {
        // Если есть ошибка, отображаем сообщение об ошибке
        emit(DealError(result['message']));
      }
    } catch (e) {
      // Логирование ошибки
      emit(DealError('Ошибка создания сделки: ${e.toString()}'));
    }
  }

// Future<void> _updateDeal(UpdateDeal event, Emitter<DealState> emit) async {
//   emit(DealLoading());

//   // Проверка подключения к интернету
//   if (!await _checkInternetConnection()) {
//     emit(DealError('Нет подключения к интернету'));
//     return;
//   }

//   try {
//     // Вызов метода обновления лида
//     final result = await apiService.updateDeal(
//       dealId: event.dealId,
//       name: event.name,
//       dealStatusId: event.dealStatusId,
//       managerId: event.managerId,
//       description: event.description,
//       organizationId: event.organizationId,
//     );

//     // Если успешно, то обновляем состояние
//     if (result['success']) {
//       emit(DealSuccess('Лид обновлен успешно'));
//       add(FetchDeal(event.dealStatusId)); // Обновляем список лидов
//     } else {
//       emit(DealError(result['message']));
//     }
//   } catch (e) {
//     emit(DealError('Ошибка обновления лида: ${e.toString()}'));
//   }
// }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
