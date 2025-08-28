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
  int _lastFetchedPage = 0;
  Map<String, dynamic>? _currentFilters;
  int? _currentSalesFunnelId;
  String? _currentQuery;
  bool _isFetching = false;

  ChatsBloc(this.apiService) : super(ChatsInitial()) {
    on<FetchChats>(_fetchChatsEvent);
    on<RefreshChats>(_refetchChatsEvent);
    on<GetNextPageChats>(_getNextPageChatsEvent);
    on<UpdateChatsFromSocket>(_updateChatsFromSocketFetch);
    on<DeleteChat>(_deleteChat);
    on<ClearChats>(_clearChatsEvent);
    on<ResetUnreadCount>(_resetUnreadCount); // Новое событие
  }

  // Функция сортировки чатов
  List<Chats> _sortChats(List<Chats> chats) {
    chats.sort((a, b) {
      if (a.type == 'support') return -1;
      if (b.type == 'support') return 1;
      return 0;
    });
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

  // Сохраняем параметры последнего запроса
  void _updateFetchParameters(FetchChats event) {
    endPoint = event.endPoint;
    _currentFilters = event.filters;
    _currentSalesFunnelId = event.salesFunnelId;
    _currentQuery = event.query;
  }

  // Начальная загрузка чатов
  Future<void> _fetchChatsEvent(FetchChats event, Emitter<ChatsState> emit) async {
    if (_isFetching) {
      print('ChatsBloc._fetchChatsEvent: Skipping fetch, another fetch is in progress');
      return;
    }
    _isFetching = true;
    print('ChatsBloc._fetchChatsEvent: Starting fetch - endpoint: ${event.endPoint}, query: ${event.query}, salesFunnelId: ${event.salesFunnelId}, filters: ${event.filters}');

    _updateFetchParameters(event);
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

        final sortedChats = _sortChats(pagination.data);
        chatsPagination = PaginationDTO(
          data: sortedChats,
          count: pagination.count,
          total: pagination.total,
          perPage: pagination.perPage,
          currentPage: pagination.currentPage,
          totalPage: pagination.totalPage,
        );
        _lastFetchedPage = 1;
        emit(ChatsLoaded(chatsPagination!));
      } catch (e) {
        print('ChatsBloc._fetchChatsEvent: Error: $e, Type: ${e.runtimeType}');
        emit(ChatsError(e.toString()));
      }
    } else {
      print('ChatsBloc._fetchChatsEvent: No internet connection');
      emit(ChatsError('No internet connection'));
    }
    _isFetching = false;
  }

  // Перезагрузка чатов
  Future<void> _refetchChatsEvent(RefreshChats event, Emitter<ChatsState> emit) async {
    _lastFetchedPage = 0;
    emit(ChatsLoading());

    if (await _checkInternetConnection()) {
      try {
        chatsPagination = await apiService.getAllChats(endPoint, 1, _currentQuery, _currentSalesFunnelId, _currentFilters);
        final sortedChats = _sortChats(chatsPagination!.data);
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
        print('ChatsBloc._getNextPageChatsEvent: Loading page $nextPage for endpoint $endPoint');

        if (await _checkInternetConnection()) {
          try {
            final nextPageChats = await apiService.getAllChats(endPoint, nextPage, _currentQuery, _currentSalesFunnelId, _currentFilters);
            print('ChatsBloc._getNextPageChatsEvent: Fetched ${nextPageChats.data.length} chats for page ${nextPageChats.currentPage}');
            print('ChatsBloc._getNextPageChatsEvent: New chat IDs: ${nextPageChats.data.map((chat) => chat.id).toList()}');

            final sortedNewChats = _sortChats(nextPageChats.data);
            chatsPagination = state.chatsPagination.merge(nextPageChats);
            final sortedMergedChats = _sortChats(chatsPagination!.data);
            chatsPagination = PaginationDTO(
              data: sortedMergedChats,
              count: chatsPagination!.count,
              total: chatsPagination!.total,
              perPage: chatsPagination!.perPage,
              currentPage: nextPageChats.currentPage,
              totalPage: chatsPagination!.totalPage,
            );
            _lastFetchedPage = nextPage;
            emit(ChatsLoaded(chatsPagination!));
          } catch (e) {
            print('ChatsBloc._getNextPageChatsEvent: Error: $e');
            emit(ChatsError(e.toString()));
          }
        } else {
          emit(ChatsError('Нет подключения к интернету'));
        }
      } else {
        print('ChatsBloc._getNextPageChatsEvent: No more pages to load or page already fetched (current: ${state.chatsPagination.currentPage}, total: ${state.chatsPagination.totalPage}, lastFetched: $_lastFetchedPage)');
      }
    }
  }

 Future<void> _updateChatsFromSocketFetch(UpdateChatsFromSocket event, Emitter<ChatsState> emit) async {
  print('ChatsBloc._updateChatsFromSocketFetch: Updating chat via socket: ${event.chat.id}, type: ${event.chat.type}, unreadCount: ${event.chat.unreadCount}');

  if (state is ChatsLoaded) {
    final currentState = state as ChatsLoaded;
    final currentChats = currentState.chatsPagination.data;
    final updatedChats = List<Chats>.from(currentChats);
    final chatIndex = updatedChats.indexWhere((chat) => chat.id == event.chat.id);

    if (chatIndex != -1) {
      updatedChats[chatIndex] = event.chat;
      print('ChatsBloc._updateChatsFromSocketFetch: Updated existing chat ID: ${event.chat.id}, new unreadCount: ${event.chat.unreadCount}');
    } else {
      updatedChats.insert(0, event.chat);
      print('ChatsBloc._updateChatsFromSocketFetch: Added new chat ID: ${event.chat.id}, unreadCount: ${event.chat.unreadCount}');
    }

    final sortedChats = _sortChats(updatedChats);
    chatsPagination = PaginationDTO(
      data: sortedChats,
      count: currentState.chatsPagination.count + (chatIndex == -1 ? 1 : 0),
      total: currentState.chatsPagination.total + (chatIndex == -1 ? 1 : 0),
      perPage: currentState.chatsPagination.perPage,
      currentPage: currentState.chatsPagination.currentPage,
      totalPage: currentState.chatsPagination.totalPage,
    );

    emit(ChatsLoaded(chatsPagination!));
  } else if (state is ChatsInitial || state is ChatsError) {
    if (_isFetching) {
      print('ChatsBloc._updateChatsFromSocketFetch: Skipping fetch, another fetch is in progress');
      return;
    }
    _isFetching = true;
    try {
      chatsPagination = await apiService.getAllChats(
        endPoint,
        1,
        _currentQuery,
        _currentSalesFunnelId,
        _currentFilters,
      );
      final sortedChats = _sortChats(chatsPagination!.data);
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
      print('ChatsBloc._updateChatsFromSocketFetch: Error: $e');
      emit(ChatsError(e.toString()));
    }
    _isFetching = false;
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
  Future<void> _resetUnreadCount(ResetUnreadCount event, Emitter<ChatsState> emit) async {
    if (state is ChatsLoaded) {
      final currentState = state as ChatsLoaded;
      final updatedChats = List<Chats>.from(currentState.chatsPagination.data);
      final chatIndex = updatedChats.indexWhere((chat) => chat.id == event.chatId);

      if (chatIndex != -1) {
        updatedChats[chatIndex] = updatedChats[chatIndex].copyWith(unreadCount: 0);
        print('ChatsBloc._resetUnreadCount: Reset unreadCount for chat ID: ${event.chatId}');
        chatsPagination = PaginationDTO(
          data: _sortChats(updatedChats),
          count: currentState.chatsPagination.count,
          total: currentState.chatsPagination.total,
          perPage: currentState.chatsPagination.perPage,
          currentPage: currentState.chatsPagination.currentPage,
          totalPage: currentState.chatsPagination.totalPage,
        );
        emit(ChatsLoaded(chatsPagination!));
      }
    }
  }
}
