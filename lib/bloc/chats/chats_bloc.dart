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
  endPoint = event.endPoint;
  emit(ChatsLoading());

  if (await _checkInternetConnection()) {
    try {
      chatsPagination = await apiService.getAllChats(event.endPoint, 1, event.query);
      print('ChatsBloc._fetchChatsEvent: Fetched ${chatsPagination!.data.length} chats for endpoint ${event.endPoint}, page 1');
      print('ChatsBloc._fetchChatsEvent: Chat IDs: ${chatsPagination!.data.map((chat) => chat.id).toList()}');
      
      // Сортируем чаты
      final sortedChats = _sortChats(chatsPagination!.data, event.endPoint);
      chatsPagination = PaginationDTO(
        data: sortedChats,
        count: chatsPagination!.count,
        total: chatsPagination!.total,
        perPage: chatsPagination!.perPage,
        currentPage: chatsPagination!.currentPage,
        totalPage: chatsPagination!.totalPage,
      );
      emit(ChatsLoaded(chatsPagination!));
    } catch (e) {
      print('ChatsBloc._fetchChatsEvent: Error: $e');
      emit(ChatsError(e.toString()));
    }
  } else {
    emit(ChatsError('Нет подключения к интернету'));
  }
}

  // Перезагрузка чатов
  Future<void> _refetchChatsEvent(RefreshChats event, Emitter<ChatsState> emit) async {
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
    if (state.chatsPagination.currentPage < state.chatsPagination.totalPage) {
      print('ChatsBloc._getNextPageChatsEvent: Loading page ${state.chatsPagination.currentPage + 1} for endpoint $endPoint');
      
      if (await _checkInternetConnection()) {
        try {
          final nextPageChats = await apiService.getAllChats(
            endPoint,
            state.chatsPagination.currentPage + 1,
          );
          print('ChatsBloc._getNextPageChatsEvent: Fetched ${nextPageChats.data.length} chats for page ${nextPageChats.currentPage}');
          print('ChatsBloc._getNextPageChatsEvent: New chat IDs: ${nextPageChats.data.map((chat) => chat.id).toList()}');

          // Сортируем новые данные
          final sortedNewChats = _sortChats(nextPageChats.data, endPoint);

          // Объединяем с текущими данными
          chatsPagination = state.chatsPagination.merge(
            PaginationDTO(
              data: sortedNewChats,
              count: nextPageChats.count,
              total: nextPageChats.total,
              perPage: nextPageChats.perPage,
              currentPage: nextPageChats.currentPage,
              totalPage: nextPageChats.totalPage,
            ),
          );
          print('ChatsBloc._getNextPageChatsEvent: Total chats after merge: ${chatsPagination!.data.length}');
          print('ChatsBloc._getNextPageChatsEvent: All chat IDs after merge: ${chatsPagination!.data.map((chat) => chat.id).toList()}');

          emit(ChatsLoaded(chatsPagination!));
        } catch (e) {
          print('ChatsBloc._getNextPageChatsEvent: Error: $e');
          emit(ChatsError(e.toString()));
        }
      } else {
        emit(ChatsError('Нет подключения к интернету'));
      }
    } else {
      print('ChatsBloc._getNextPageChatsEvent: No more pages to load (current: ${state.chatsPagination.currentPage}, total: ${state.chatsPagination.totalPage})');
    }
  }
}
  // Обновление чатов через сокеты
  Future<void> _updateChatsFromSocketFetch(UpdateChatsFromSocket event, Emitter<ChatsState> emit) async {
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
  emit(ChatsInitial());
}
}