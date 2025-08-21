  import 'dart:io';
  import 'package:crm_task_manager/api/service/api_service.dart';
  import 'package:crm_task_manager/models/chats_model.dart';
  import 'package:crm_task_manager/models/pagination_dto.dart';
  import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
  import 'package:equatable/equatable.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';

  part 'chats_event.dart';
  part 'chats_state.dart';

  class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
    final ApiService apiService;
    String endPoint = '';
    PaginationDTO<Chats>? chatsPagination;
    int _lastFetchedPage = 0; // Храним последнюю загруженную страницу

    ChatsBloc(this.apiService) : super(ChatsInitial()) {
      on<FetchChats>(_fetchChatsEvent);
      on<RefreshChats>(_refetchChatsEvent);
      on<GetNextPageChats>(_getNextPageChatsEvent);
      on<UpdateChatsFromSocket>(_updateChatsFromSocketFetch);
      on<DeleteChat>(_deleteChat);
      on<ClearChats>(_clearChatsEvent);
    }

    // Функция сортировки чатов
    List<Chats> _sortChats(List<Chats> chats, String endPoint) {
      if (endPoint == 'corporate') {
        chats.sort((a, b) {
          if (a.type == 'support') return -1; // support всегда первый
          if (b.type == 'support') return 1;
          return 0; // остальные чаты сохраняют порядок
        });
      }
      return chats;
    }

    // Проверка подключения к интернету
    Future<bool> _checkInternetConnection() async {
      try {
        final result = await InternetAddress.lookup('example.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException {
        return false;
      }
    }

    // Загрузка чатов
Future<void> _fetchChatsEvent(FetchChats event, Emitter<ChatsState> emit) async {
  print('ChatsBloc._fetchChatsEvent: Received event - endpoint: ${event.endPoint}, query: ${event.query}, salesFunnelId: ${event.salesFunnelId}, filters: ${event.filters}');
  endPoint = event.endPoint;
  _lastFetchedPage = 0;
  emit(ChatsLoading());

  if (await _checkInternetConnection()) {
    try {
      final pagination = await apiService.getAllChats(
        event.endPoint,
        1,
        event.query,
        event.salesFunnelId,
        event.filters,
      );
      print('ChatsBloc._fetchChatsEvent: Fetched ${pagination.data.length} chats for endpoint ${event.endPoint}, page 1');
      print('ChatsBloc._fetchChatsEvent: Chat IDs: ${pagination.data.map((chat) => chat.id).toList()}');
      emit(ChatsLoaded(pagination));
    } catch (e) {
      print('ChatsBloc._fetchChatsEvent: Error: $e, Type: ${e.runtimeType}');
      emit(ChatsError(e.toString()));
    }
  } else {
    print('ChatsBloc._fetchChatsEvent: No internet connection');
    emit(ChatsError('No internet connection'));
  }
}

    // Перезагрузка чатов
    Future<void> _refetchChatsEvent(RefreshChats event, Emitter<ChatsState> emit) async {
      _lastFetchedPage = 0; // Сбрасываем последнюю страницу
      emit(ChatsInitial());

      if (await _checkInternetConnection()) {
        try {
          chatsPagination = await apiService.getAllChats(endPoint);
          // Сортируем чаты
          final sortedChats = _sortChats(chatsPagination!.data, endPoint);
          chatsPagination = PaginationDTO(
            data: sortedChats,
            count: chatsPagination!.count,
            total: chatsPagination!.total,
            perPage: chatsPagination!.perPage,
            currentPage: chatsPagination!.currentPage,
            totalPage: chatsPagination!.totalPage,
          );
          _lastFetchedPage = 1;
          emit(ChatsLoaded(chatsPagination!));
        } catch (e) {
          emit(ChatsError(e.toString()));
        }
      } else {
        emit(ChatsError('Нет подключения к интернету'));
      }
    }

    // Загрузка следующей страницы
    Future<void> _getNextPageChatsEvent(GetNextPageChats event, Emitter<ChatsState> emit) async {
      if (state is ChatsLoaded) {
        final state = this.state as ChatsLoaded;
        final nextPage = state.chatsPagination.currentPage + 1;

        if (nextPage <= state.chatsPagination.totalPage && nextPage > _lastFetchedPage) {
          // print('ChatsBloc._getNextPageChatsEvent: Loading page $nextPage for endpoint $endPoint');

          if (await _checkInternetConnection()) {
            try {
              final nextPageChats = await apiService.getAllChats(endPoint, nextPage);
              // print('ChatsBloc._getNextPageChatsEvent: Fetched ${nextPageChats.data.length} chats for page ${nextPageChats.currentPage}');
              // print('ChatsBloc._getNextPageChatsEvent: New chat IDs: ${nextPageChats.data.map((chat) => chat.id).toList()}');

              // Сортируем новые данные
              final sortedNewChats = _sortChats(nextPageChats.data, endPoint);

              // Объединяем с текущими данными
              chatsPagination = state.chatsPagination.merge(nextPageChats);
              // print('ChatsBloc._getNextPageChatsEvent: Total chats after merge: ${chatsPagination!.data.length}');
              // print('ChatsBloc._getNextPageChatsEvent: All chat IDs after merge: ${chatsPagination!.data.map((chat) => chat.id).toList()}');

              _lastFetchedPage = nextPage;
              emit(ChatsLoaded(chatsPagination!));
            } catch (e) {
              // print('ChatsBloc._getNextPageChatsEvent: Error: $e');
              emit(ChatsError(e.toString()));
            }
          } else {
            emit(ChatsError('Нет подключения к интернету'));
          }
        } else {
          // print('ChatsBloc._getNextPageChatsEvent: No more pages to load or page already fetched (current: ${state.chatsPagination.currentPage}, total: ${state.chatsPagination.totalPage}, lastFetched: $_lastFetchedPage)');
        }
      }
    }

    // Обновление чатов через сокеты
    Future<void> _updateChatsFromSocketFetch(UpdateChatsFromSocket event, Emitter<ChatsState> emit) async {
      _lastFetchedPage = 0; // Сбрасываем последнюю страницу
      if (await _checkInternetConnection()) {
        try {
          chatsPagination = await apiService.getAllChats(endPoint);
          // Сортируем чаты
          final sortedChats = _sortChats(chatsPagination!.data, endPoint);
          chatsPagination = PaginationDTO(
            data: sortedChats,
            count: chatsPagination!.count,
            total: chatsPagination!.total,
            perPage: chatsPagination!.perPage,
            currentPage: chatsPagination!.currentPage,
            totalPage: chatsPagination!.totalPage,
          );
          _lastFetchedPage = 1;
          emit(ChatsInitial());
          emit(ChatsLoaded(chatsPagination!));
        } catch (e) {
          emit(ChatsError(e.toString()));
        }
      } else {
        emit(ChatsError('Нет подключения к интернету'));
      }
    }

    // Удаление чата
    Future<void> _deleteChat(DeleteChat event, Emitter<ChatsState> emit) async {
      emit(ChatsLoading());

      if (await _checkInternetConnection()) {
        try {
          final response = await apiService.deleteChat(event.chatId);
          if (response['result'] == true) {
            emit(ChatsDeleted(event.localizations.translate('chat_deleted_successfully')));
          } else {
            emit(ChatsError(event.localizations.translate('you_dont_delete_this_group')));
          }
        } catch (e) {
          emit(ChatsError(event.localizations.translate('error_delete_chat')));
        }
      } else {
        emit(ChatsError(event.localizations.translate('no_internet_connection')));
      }
    }

    // Очистка чатов
    Future<void> _clearChatsEvent(ClearChats event, Emitter<ChatsState> emit) async {
      print('ChatsBloc._clearChatsEvent: Clearing chats and resetting chatsPagination for endpoint $endPoint');
      chatsPagination = null;
      _lastFetchedPage = 0;
      emit(ChatsInitial());
    }
  }