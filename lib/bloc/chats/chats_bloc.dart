import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/pagination_dto.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

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
  
  // 🚀 УМНАЯ ПАГИНАЦИЯ: Предзагрузка страниц
  final Set<int> _prefetchedPages = {};
  bool _isPrefetching = false;
  static const int _prefetchCount = 3; // Количество страниц для предзагрузки

  ChatsBloc(this.apiService) : super(ChatsInitial()) {
    on<FetchChats>(_fetchChatsEvent);
    on<RefreshChats>(_refetchChatsEvent);
    on<GetNextPageChats>(_getNextPageChatsEvent);
    on<UpdateChatsFromSocket>(_updateChatsFromSocketFetch);
    on<DeleteChat>(_deleteChat);
    on<ClearChats>(_clearChatsEvent);
    on<ResetUnreadCount>(_resetUnreadCount);
  }

  // Сортировка только для corporate
  List<Chats> _sortChatsIfNeeded(List<Chats> chats, String endPoint) {
    if (endPoint == 'corporate') {
      final indexedChats = chats.asMap().entries.toList();
      
      indexedChats.sort((a, b) {
        if (a.value.type == 'support' && b.value.type != 'support') return -1;
        if (a.value.type != 'support' && b.value.type == 'support') return 1;
        return a.key.compareTo(b.key);
      });
      
      return indexedChats.map((e) => e.value).toList();
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
      debugPrint('ChatsBloc._fetchChatsEvent: Skipping fetch, another fetch is in progress');
      return;
    }
    _isFetching = true;
    debugPrint('ChatsBloc._fetchChatsEvent: Starting fetch - endpoint: ${event.endPoint}, query: ${event.query}, salesFunnelId: ${event.salesFunnelId}');

    _updateFetchParameters(event);
    _lastFetchedPage = 0;
    _prefetchedPages.clear(); // Очищаем кеш предзагрузки
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
        debugPrint('ChatsBloc._fetchChatsEvent: Fetched ${pagination.data.length} chats for endpoint ${event.endPoint}, page 1');

        final sortedChats = _sortChatsIfNeeded(pagination.data, event.endPoint);
        
        chatsPagination = PaginationDTO(
          data: sortedChats,
          count: pagination.count,
          total: pagination.total,
          perPage: pagination.perPage,
          currentPage: pagination.currentPage,
          totalPage: pagination.totalPage,
        );
        _lastFetchedPage = 1;
        _prefetchedPages.add(1);
        emit(ChatsLoaded(chatsPagination!));
        
        // 🚀 УМНАЯ ПАГИНАЦИЯ: Запускаем предзагрузку следующих 3 страниц фоново
        _prefetchNextPages(2, emit);
      } catch (e) {
        debugPrint('ChatsBloc._fetchChatsEvent: Error: $e, Type: ${e.runtimeType}');
        emit(ChatsError(e.toString()));
      }
    } else {
      debugPrint('ChatsBloc._fetchChatsEvent: No internet connection');
      emit(ChatsError('No internet connection'));
    }
    _isFetching = false;
  }

  // Перезагрузка чатов
  Future<void> _refetchChatsEvent(RefreshChats event, Emitter<ChatsState> emit) async {
    _lastFetchedPage = 0;
    _prefetchedPages.clear(); // Очищаем кеш предзагрузки
    emit(ChatsLoading());

    if (await _checkInternetConnection()) {
      try {
        chatsPagination = await apiService.getAllChats(
          endPoint, 1, _currentQuery, _currentSalesFunnelId, _currentFilters
        );
        
        final sortedChats = _sortChatsIfNeeded(chatsPagination!.data, endPoint);
        
        chatsPagination = PaginationDTO(
          data: sortedChats,
          count: chatsPagination!.count,
          total: chatsPagination!.total,
          perPage: chatsPagination!.perPage,
          currentPage: chatsPagination!.currentPage,
          totalPage: chatsPagination!.totalPage,
        );
        _lastFetchedPage = 1;
        _prefetchedPages.add(1);
        emit(ChatsLoaded(chatsPagination!));
        
        // 🚀 УМНАЯ ПАГИНАЦИЯ: Запускаем предзагрузку следующих 3 страниц фоново
        _prefetchNextPages(2, emit);
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
        debugPrint('ChatsBloc._getNextPageChatsEvent: Loading page $nextPage for endpoint $endPoint');

        if (await _checkInternetConnection()) {
          try {
            final nextPageChats = await apiService.getAllChats(
              endPoint, nextPage, _currentQuery, _currentSalesFunnelId, _currentFilters
            );
            debugPrint('ChatsBloc._getNextPageChatsEvent: Fetched ${nextPageChats.data.length} chats for page ${nextPageChats.currentPage}');

            chatsPagination = state.chatsPagination.merge(nextPageChats);
            
            final sortedChats = _sortChatsIfNeeded(chatsPagination!.data, endPoint);
            
            chatsPagination = PaginationDTO(
              data: sortedChats,
              count: chatsPagination!.count,
              total: chatsPagination!.total,
              perPage: chatsPagination!.perPage,
              currentPage: nextPageChats.currentPage,
              totalPage: chatsPagination!.totalPage,
            );
            _lastFetchedPage = nextPage;
            _prefetchedPages.add(nextPage);
            emit(ChatsLoaded(chatsPagination!));
            
            // 🚀 УМНАЯ ПАГИНАЦИЯ: Предзагружаем следующие 3 страницы
            _prefetchNextPages(nextPage + 1, emit);
          } catch (e) {
            debugPrint('ChatsBloc._getNextPageChatsEvent: Error: $e');
            emit(ChatsError(e.toString()));
          }
        } else {
          emit(ChatsError('Нет подключения к интернету'));
        }
      } else {
        debugPrint('ChatsBloc._getNextPageChatsEvent: No more pages to load');
      }
    }
  }

  // 🚀 УМНАЯ ПАГИНАЦИЯ: Фоновая предзагрузка следующих страниц
  Future<void> _prefetchNextPages(int startPage, Emitter<ChatsState> emit) async {
    if (_isPrefetching || chatsPagination == null) return;
    
    _isPrefetching = true;
    debugPrint('ChatsBloc._prefetchNextPages: Starting prefetch from page $startPage for endpoint $endPoint');

    try {
      for (int i = 0; i < _prefetchCount; i++) {
        final pageToFetch = startPage + i;
        
        // Проверяем что страница существует и еще не загружена
        if (pageToFetch > chatsPagination!.totalPage) {
          debugPrint('ChatsBloc._prefetchNextPages: Page $pageToFetch exceeds totalPage ${chatsPagination!.totalPage}, stopping prefetch');
          break;
        }
        
        if (_prefetchedPages.contains(pageToFetch)) {
          debugPrint('ChatsBloc._prefetchNextPages: Page $pageToFetch already prefetched, skipping');
          continue;
        }

        // Проверяем интернет перед каждым запросом
        if (!await _checkInternetConnection()) {
          debugPrint('ChatsBloc._prefetchNextPages: No internet connection, stopping prefetch');
          break;
        }

        try {
          debugPrint('ChatsBloc._prefetchNextPages: Fetching page $pageToFetch in background');
          final prefetchedData = await apiService.getAllChats(
            endPoint, 
            pageToFetch, 
            _currentQuery, 
            _currentSalesFunnelId, 
            _currentFilters
          );
          
          // Мержим данные в основную пагинацию БЕЗ изменения currentPage
          if (state is ChatsLoaded && chatsPagination != null) {
            chatsPagination = chatsPagination!.merge(prefetchedData);
            
            final sortedChats = _sortChatsIfNeeded(chatsPagination!.data, endPoint);
            
            chatsPagination = PaginationDTO(
              data: sortedChats,
              count: chatsPagination!.count,
              total: chatsPagination!.total,
              perPage: chatsPagination!.perPage,
              currentPage: chatsPagination!.currentPage, // НЕ меняем currentPage!
              totalPage: chatsPagination!.totalPage,
            );
            
            _prefetchedPages.add(pageToFetch);
            debugPrint('ChatsBloc._prefetchNextPages: Successfully prefetched page $pageToFetch (${prefetchedData.data.length} chats)');
            
            // НЕ вызываем emit, чтобы UI не обновлялся и пользователь не заметил
          }
          
          // Небольшая задержка между запросами чтобы не перегружать сервер
          await Future.delayed(const Duration(milliseconds: 300));
          
        } catch (e) {
          debugPrint('ChatsBloc._prefetchNextPages: Error prefetching page $pageToFetch: $e');
          // Продолжаем со следующей страницей даже если текущая не загрузилась
        }
      }
      
      debugPrint('ChatsBloc._prefetchNextPages: Prefetch completed. Total prefetched pages: ${_prefetchedPages.length}');
    } finally {
      _isPrefetching = false;
    }
  }

  // 🔹 ИСПРАВЛЕННЫЙ МЕТОД
  Future<void> _updateChatsFromSocketFetch(UpdateChatsFromSocket event, Emitter<ChatsState> emit) async {
    debugPrint('ChatsBloc._updateChatsFromSocketFetch: Updating chat via socket: ${event.chat.id}, type: ${event.chat.type}, unreadCount from event: ${event.chat.unreadCount}');
    
    if (event.chat.id == 0 || event.chat.type == null) {
      debugPrint('ChatsBloc: Invalid chat from socket, skipping');
      return;
    }
    
    if (state is ChatsLoaded) {
      final currentState = state as ChatsLoaded;
      final currentChats = currentState.chatsPagination.data;
      final updatedChats = List<Chats>.from(currentChats);
      final chatIndex = updatedChats.indexWhere((chat) => chat.id == event.chat.id);

      if (chatIndex != -1) {
        final oldChat = updatedChats[chatIndex];
        
        debugPrint('ChatsBloc: Old chat data - ID: ${oldChat.id}, unreadCount: ${oldChat.unreadCount}, lastMessage: "${oldChat.lastMessage}"');
        debugPrint('ChatsBloc: New chat data - ID: ${event.chat.id}, unreadCount: ${event.chat.unreadCount}, lastMessage: "${event.chat.lastMessage}"');
        
        // 🔹 Проверяем, изменилось ли сообщение
        final isNewMessage = oldChat.lastMessage != event.chat.lastMessage;
        
        // 🔹 Определяем новый счётчик
        int newUnreadCount;
        
        if (event.chat.unreadCount > 0) {
          // Если сервер прислал счётчик > 0, используем его
          newUnreadCount = event.chat.unreadCount;
          debugPrint('ChatsBloc: Using unreadCount from server: $newUnreadCount for chat ID: ${event.chat.id}');
        } else if (isNewMessage) {
          // Если сообщение изменилось, но сервер прислал 0, инкрементируем локально
          newUnreadCount = oldChat.unreadCount + 1;
          debugPrint('ChatsBloc: New message detected, incremented unreadCount from ${oldChat.unreadCount} to $newUnreadCount for chat ID: ${event.chat.id}');
        } else {
          // Сообщение не изменилось, оставляем старый счётчик
          newUnreadCount = oldChat.unreadCount;
          debugPrint('ChatsBloc: No changes detected, keeping unreadCount: $newUnreadCount for chat ID: ${event.chat.id}');
        }

        // 🔹 Обновляем чат, сохраняя старое имя и аватар
        final updatedChat = oldChat.copyWith(
          lastMessage: event.chat.lastMessage,
          unreadCount: newUnreadCount,
          createDate: event.chat.createDate,
          messageType: event.chat.messageType,
        );

        updatedChats[chatIndex] = updatedChat;
        debugPrint('ChatsBloc._updateChatsFromSocketFetch: Updated existing chat ID: ${event.chat.id}, final unreadCount: $newUnreadCount');

      } else {
        // Новый чат
        updatedChats.insert(0, event.chat);
        debugPrint('ChatsBloc._updateChatsFromSocketFetch: Added new chat ID: ${event.chat.id}, unreadCount: ${event.chat.unreadCount}');
      }

      // ПРИМЕНЯЕМ УСЛОВНУЮ СОРТИРОВКУ
      final sortedChats = _sortChatsIfNeeded(updatedChats, endPoint);

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
        debugPrint('ChatsBloc._updateChatsFromSocketFetch: Skipping fetch, another fetch is in progress');
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
        
        final sortedChats = _sortChatsIfNeeded(chatsPagination!.data, endPoint);
        
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
        debugPrint('ChatsBloc._updateChatsFromSocketFetch: Error: $e');
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
    debugPrint('ChatsBloc._clearChatsEvent: Clearing chats and resetting chatsPagination for endpoint $endPoint');
    chatsPagination = null;
    _lastFetchedPage = 0;
    _prefetchedPages.clear(); // Очищаем кеш предзагрузки
    _isPrefetching = false; // Сбрасываем флаг предзагрузки
    emit(ChatsInitial());
  }

  // 🔹 ИСПРАВЛЕННЫЙ МЕТОД - Сброс счётчика непрочитанных
  Future<void> _resetUnreadCount(ResetUnreadCount event, Emitter<ChatsState> emit) async {
    debugPrint('ChatsBloc._resetUnreadCount: Resetting unreadCount for chat ID: ${event.chatId}');
    
    if (state is ChatsLoaded) {
      final currentState = state as ChatsLoaded;
      final updatedChats = List<Chats>.from(currentState.chatsPagination.data);
      final chatIndex = updatedChats.indexWhere((chat) => chat.id == event.chatId);

      if (chatIndex != -1) {
        final oldUnreadCount = updatedChats[chatIndex].unreadCount;
        
        // Обновляем только конкретный чат
        updatedChats[chatIndex] = updatedChats[chatIndex].copyWith(unreadCount: 0);
        
        debugPrint('ChatsBloc._resetUnreadCount: Reset unreadCount for chat ID: ${event.chatId} from $oldUnreadCount to 0');
        
        // НЕ пересортировываем, сохраняем порядок
        chatsPagination = PaginationDTO(
          data: updatedChats,
          count: currentState.chatsPagination.count,
          total: currentState.chatsPagination.total,
          perPage: currentState.chatsPagination.perPage,
          currentPage: currentState.chatsPagination.currentPage,
          totalPage: currentState.chatsPagination.totalPage,
        );
        emit(ChatsLoaded(chatsPagination!));
      } else {
        debugPrint('ChatsBloc._resetUnreadCount: Chat ID ${event.chatId} not found in current state');
      }
    } else {
      debugPrint('ChatsBloc._resetUnreadCount: State is not ChatsLoaded, cannot reset unreadCount');
    }
  }
}