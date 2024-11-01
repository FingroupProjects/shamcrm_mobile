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
    // on<CreateLead>(_createLead);
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
          'Не удалось загрузить дополнительные лиды: ${e.toString()}'));
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

//   Future<void> _createLead(CreateLead event, Emitter<LeadState> emit) async {
//     emit(LeadLoading());

//     // Проверка подключения к интернету
//     if (!await _checkInternetConnection()) {
//       emit(LeadError('Нет подключения к интернету'));
//       return;
//     }

//     try {
//       // Вызов метода создания лида
//       final result = await apiService.createLead(
//         name: event.name,
//         leadStatusId: event.leadStatusId,
//         phone: event.phone,
//         regionId: event.regionId,
//         managerId: event.managerId,
//         instaLogin: event.instaLogin,
//         facebookLogin: event.facebookLogin,
//         tgNick: event.tgNick,
//         birthday: event.birthday,
//         description: event.description,
//         organizationId: event.organizationId,
//         waPhone: event.waPhone,
//       );

//       // Если успешно, то обновляем состояние
//       if (result['success']) {
//         emit(LeadSuccess('Лид создан успешно'));
//         // Передаем статус лида (event.leadStatusId) в событие FetchLeads
//         add(FetchLeads(event.leadStatusId));
//       } else {
//         // Если есть ошибка, отображаем сообщение об ошибке
//         emit(LeadError(result['message']));
//       }
//     } catch (e) {
//       // Логирование ошибки
//       emit(LeadError('Ошибка создания лида: ${e.toString()}'));
//     }
//   }

 
  
// Future<void> _updateLead(UpdateLead event, Emitter<LeadState> emit) async {
//   emit(LeadLoading());

//   // Проверка подключения к интернету
//   if (!await _checkInternetConnection()) {
//     emit(LeadError('Нет подключения к интернету'));
//     return;
//   }

//   try {
//     // Вызов метода обновления лида
//     final result = await apiService.updateLead(
//       leadId: event.leadId,
//       name: event.name,
//       leadStatusId: event.leadStatusId,
//       phone: event.phone,
//       regionId: event.regionId,
//       managerId: event.managerId,
//       instaLogin: event.instaLogin,
//       facebookLogin: event.facebookLogin,
//       tgNick: event.tgNick,
//       birthday: event.birthday,
//       description: event.description,
//       organizationId: event.organizationId,
//       waPhone: event.waPhone,
//     );

//     // Если успешно, то обновляем состояние
//     if (result['success']) {
//       emit(LeadSuccess('Лид обновлен успешно'));
//       add(FetchLeads(event.leadStatusId)); // Обновляем список лидов
//     } else {
//       emit(LeadError(result['message']));
//     }
//   } catch (e) {
//     emit(LeadError('Ошибка обновления лида: ${e.toString()}'));
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