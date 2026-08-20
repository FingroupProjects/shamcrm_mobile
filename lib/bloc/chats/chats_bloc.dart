import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/models/common/pagination_dto.dart';
import 'package:crm_task_manager/offline/core/offline_module.dart';
import 'package:crm_task_manager/offline/core/offline_runtime.dart';
import 'package:crm_task_manager/offline/core/request_priority.dart';
import 'package:crm_task_manager/offline/repositories/chat_offline_repository.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/active_chat_tracker.dart'; // ✅ ДОБАВЛЕНО: Импорт для отслеживания активного чата
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

part 'chats_event.dart';
part 'chats_state.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final ApiService apiService;
  final ChatOfflineRepository _offlineRepository;
  final ActiveChatTracker _chatTracker =
      ActiveChatTracker(); // ✅ ДОБАВЛЕНО: Трекер активного чата
  String endPoint = '';
  PaginationDTO<Chats>? chatsPagination;
  int _lastFetchedPage = 0;
  Map<String, dynamic>? _currentFilters;
  int? _currentSalesFunnelId;
  String? _currentQuery;
  bool _isFetching = false;

  final Set<int> _prefetchedPages = {};
  final Set<int> _loadingPages = {}; // Страницы, которые сейчас загружаются

  // ✅ ИСПРАВЛЕНО: Отслеживание времени обнуления счетчика для каждого чата
  // Используется как дополнительная защита после выхода из чата (cooldown 2 секунды)
  // Ключ: chatUniqueId (String), Значение: timestamp когда счетчик был обнулен
  // ✅ ИСПРАВЛЕНО: Используем uniqueId вместо id для привязки
  final Map<String, DateTime> _resetUnreadCountTimestamps = {};
  static const Duration _resetCooldownDuration =
      Duration(seconds: 2); // 2 секунды для скрытия счетчика

  ChatsBloc(this.apiService)
      : _offlineRepository = ChatOfflineRepository.fromRuntime(apiService),
        super(ChatsInitial()) {
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
    final runtime = OfflineRuntime.maybeInstance;
    if (runtime == null) {
      debugPrint(
          'ChatsBloc: OfflineRuntime недоступен, считаем сеть доступной и используем API fallback');
      return true;
    }
    return runtime.networkProfileService.currentProfile.isOnline;
  }

  // Сохраняем параметры последнего запроса
  void _updateFetchParameters(FetchChats event) {
    endPoint = event.endPoint;
    _currentFilters = event.filters;
    _currentSalesFunnelId = event.salesFunnelId;
    _currentQuery = event.query;
  }

  String _toUserFriendlyErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('SocketException') ||
        message.contains('No internet connection')) {
      return 'Нет подключения к интернету';
    }

    if (message.contains('SqliteException') ||
        message.contains('DatabaseException') ||
        message.contains('UNIQUE constraint failed') ||
        message.contains('cached_records')) {
      return 'Не удалось обновить список чатов. Попробуйте еще раз.';
    }

    if (message.contains('No host specified in URI null') ||
        message.contains('Base URL is not initialized') ||
        message.contains('Домен не установлен')) {
      return 'Проблема с настройками подключения. Попробуйте войти заново.';
    }

    return 'Не удалось загрузить чаты. Попробуйте еще раз.';
  }

  // Начальная загрузка чатов
  Future<void> _fetchChatsEvent(
      FetchChats event, Emitter<ChatsState> emit) async {
    if (_isFetching) {
      debugPrint(
          '=================-=== ChatsBloc._fetchChatsEvent: Skipping fetch, another fetch is in progress');
      return;
    }
    _isFetching = true;
    debugPrint(
        'ChatsBloc._fetchChatsEvent: Starting fetch - endpoint: ${event.endPoint}, query: ${event.query}, salesFunnelId: ${event.salesFunnelId}');

    _updateFetchParameters(event);
    _lastFetchedPage = 0;
    _prefetchedPages.clear(); // Очищаем кеш предзагрузки
    _loadingPages
        .clear(); // ✅ ИСПРАВЛЕНИЕ: Очищаем список загружающихся страниц
    final cached = await _offlineRepository.readCachedChats(
      endPoint: event.endPoint,
      page: 1,
      query: event.query,
      salesFunnelId: event.salesFunnelId,
      filters: event.filters,
    );

    if (cached != null) {
      final sortedCached = _sortChatsIfNeeded(cached.data, event.endPoint);
      chatsPagination = PaginationDTO(
        data: sortedCached,
        count: cached.count,
        total: cached.total,
        perPage: cached.perPage,
        currentPage: cached.currentPage,
        totalPage: cached.totalPage,
      );
      _lastFetchedPage = 1;
      _prefetchedPages.add(1);
      emit(ChatsLoaded(chatsPagination!));
    } else {
      emit(ChatsLoading());
    }

    if (await _checkInternetConnection()) {
      try {
        final pagination = await _offlineRepository.refreshChats(
          endPoint: event.endPoint,
          page: 1,
          query: event.query,
          salesFunnelId: event.salesFunnelId,
          filters: event.filters,
        );
        debugPrint(
            '=================-=== ChatsBloc._fetchChatsEvent: Fetched ${pagination.data.length} chats for endpoint ${event.endPoint}, page 1');

        final sortedChats = _sortChatsIfNeeded(pagination.data, event.endPoint);

        // ✅ ИСПРАВЛЕНО: Если счетчик был недавно обнулен (в течение 2 секунд), обнуляем его снова
        // Это гарантирует, что счетчик остается скрытым в течение 2 секунд после выхода из чата
        final now = DateTime.now();
        final updatedChats = sortedChats.map((chat) {
          // ✅ ИСПРАВЛЕНО: Используем uniqueId для привязки, fallback на id если uniqueId null
          final chatKey = chat.uniqueId ?? chat.id.toString();
          final resetTimestamp = _resetUnreadCountTimestamps[chatKey];
          if (resetTimestamp != null &&
              now.difference(resetTimestamp) < _resetCooldownDuration) {
            // Счетчик был недавно обнулен - обнуляем его снова, даже если сервер прислал значение > 0
            debugPrint(
                '=================-=== ChatsBloc: Chat ${chat.uniqueId ?? chat.id} was recently reset, keeping unreadCount at 0 for 2s cooldown');
            return chat.copyWith(unreadCount: 0);
          }
          return chat;
        }).toList();

        chatsPagination = PaginationDTO(
          data: updatedChats,
          count: pagination.count,
          total: pagination.total,
          perPage: pagination.perPage,
          currentPage: pagination.currentPage,
          totalPage: pagination.totalPage,
        );
        _lastFetchedPage = 1;
        _prefetchedPages.add(1);
        emit(ChatsLoaded(chatsPagination!));

        // ✅ ИСПРАВЛЕНИЕ: Отключена автоматическая предзагрузка для предотвращения бесконечных запросов
        // _prefetchNextPages(2, emit);
      } catch (e) {
        debugPrint(
            '=================-=== ChatsBloc._fetchChatsEvent: Error: $e, Type: ${e.runtimeType}');
        emit(ChatsError(_toUserFriendlyErrorMessage(e)));
      }
    } else {
      debugPrint('ChatsBloc._fetchChatsEvent: No internet connection');
      if (cached == null) {
        emit(ChatsError('Нет подключения к интернету'));
      }
    }
    _isFetching = false;
  }

  // Перезагрузка чатов
  Future<void> _refetchChatsEvent(
      RefreshChats event, Emitter<ChatsState> emit) async {
    _lastFetchedPage = 0;
    _prefetchedPages.clear(); // Очищаем кеш предзагрузки
    _loadingPages
        .clear(); // ✅ ИСПРАВЛЕНИЕ: Очищаем список загружающихся страниц
    final hasLiveData = state is ChatsLoaded &&
        (state as ChatsLoaded).chatsPagination.data.isNotEmpty;
    final cached = hasLiveData
        ? null
        : await _offlineRepository.readCachedChats(
            endPoint: endPoint,
            page: 1,
            query: _currentQuery,
            salesFunnelId: _currentSalesFunnelId,
            filters: _currentFilters,
          );
    if (!hasLiveData) {
      if (cached != null) {
        final sortedCached = _sortChatsIfNeeded(cached.data, endPoint);
        emit(ChatsLoaded(PaginationDTO(
          data: sortedCached,
          count: cached.count,
          total: cached.total,
          perPage: cached.perPage,
          currentPage: cached.currentPage,
          totalPage: cached.totalPage,
        )));
      } else {
        emit(ChatsLoading());
      }
    }

    if (await _checkInternetConnection()) {
      try {
        chatsPagination = await _offlineRepository.refreshChats(
          endPoint: endPoint,
          page: 1,
          query: _currentQuery,
          salesFunnelId: _currentSalesFunnelId,
          filters: _currentFilters,
        );

        final sortedChats = _sortChatsIfNeeded(chatsPagination!.data, endPoint);

        // ✅ ИСПРАВЛЕНО: Если счетчик был недавно обнулен (в течение 2 секунд), обнуляем его снова
        final now = DateTime.now();
        final updatedChats = sortedChats.map((chat) {
          // ✅ ИСПРАВЛЕНО: Используем uniqueId для привязки, fallback на id если uniqueId null
          final chatKey = chat.uniqueId ?? chat.id.toString();
          final resetTimestamp = _resetUnreadCountTimestamps[chatKey];
          if (resetTimestamp != null &&
              now.difference(resetTimestamp) < _resetCooldownDuration) {
            // Счетчик был недавно обнулен - обнуляем его снова
            debugPrint(
                '=================-=== ChatsBloc: Chat ${chat.uniqueId ?? chat.id} was recently reset, keeping unreadCount at 0 for 2s cooldown');
            return chat.copyWith(unreadCount: 0);
          }
          return chat;
        }).toList();

        chatsPagination = PaginationDTO(
          data: updatedChats,
          count: chatsPagination!.count,
          total: chatsPagination!.total,
          perPage: chatsPagination!.perPage,
          currentPage: chatsPagination!.currentPage,
          totalPage: chatsPagination!.totalPage,
        );
        _lastFetchedPage = 1;
        _prefetchedPages.add(1);
        emit(ChatsLoaded(chatsPagination!));

        // ✅ ИСПРАВЛЕНИЕ: Отключена автоматическая предзагрузка для предотвращения бесконечных запросов
        // _prefetchNextPages(2, emit);
      } catch (e) {
        debugPrint(
            'ChatsBloc._refetchChatsEvent: Refresh failed, keep live data=$hasLiveData, error=$e');
        if (!hasLiveData) {
          emit(ChatsError(_toUserFriendlyErrorMessage(e)));
        }
      }
    } else if (!hasLiveData && cached == null) {
      emit(ChatsError('Нет подключения к интернету'));
    }
  }

  // Загрузка следующей страницы
  Future<void> _getNextPageChatsEvent(
      GetNextPageChats event, Emitter<ChatsState> emit) async {
    if (state is ChatsLoaded) {
      final state = this.state as ChatsLoaded;
      final nextPage = state.chatsPagination.currentPage + 1;

      if (_loadingPages.contains(nextPage)) {
        debugPrint(
            '=================-=== ChatsBloc._getNextPageChatsEvent: Page $nextPage is already loading, skipping');
        return;
      }

      // ✅ ИСПРАВЛЕНИЕ: Проверяем, не загружена ли страница уже
      if (_prefetchedPages.contains(nextPage) || nextPage <= _lastFetchedPage) {
        debugPrint(
            '=================-=== ChatsBloc._getNextPageChatsEvent: Page $nextPage already loaded (prefetched: ${_prefetchedPages.contains(nextPage)}, lastFetched: $_lastFetchedPage), skipping');
        return;
      }

      if (nextPage <= state.chatsPagination.totalPage) {
        debugPrint(
            'ChatsBloc._getNextPageChatsEvent: Loading page $nextPage for endpoint $endPoint');

        // ✅ ИСПРАВЛЕНИЕ: Помечаем страницу как загружающуюся
        _loadingPages.add(nextPage);

        if (await _checkInternetConnection()) {
          try {
            final nextPageChats = await _offlineRepository.refreshChats(
              endPoint: endPoint,
              page: nextPage,
              query: _currentQuery,
              salesFunnelId: _currentSalesFunnelId,
              filters: _currentFilters,
            );
            debugPrint(
                '=================-=== ChatsBloc._getNextPageChatsEvent: Fetched ${nextPageChats.data.length} chats for page ${nextPageChats.currentPage}');

            // ✅ ИСПРАВЛЕНИЕ: Проверяем, есть ли НОВЫЕ элементы после мерджа
            final oldItemCount = state.chatsPagination.data.length;
            chatsPagination = state.chatsPagination.merge(nextPageChats);
            final newItemCount = chatsPagination!.data.length;

            final sortedChats =
                _sortChatsIfNeeded(chatsPagination!.data, endPoint);

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

            // ✅ ИСПРАВЛЕНИЕ: Убираем страницу из списка загружающихся
            _loadingPages.remove(nextPage);

            // Если все элементы этой страницы уже были в списке (из-за сокетов),
            // и есть еще страницы, пробуем загрузить следующую страницу автоматически
            if (newItemCount == oldItemCount &&
                nextPage < chatsPagination!.totalPage) {
              debugPrint(
                  '=================-=== ChatsBloc: Page $nextPage only contained duplicates, fetching ${nextPage + 1}');
              add(GetNextPageChats());
              return;
            }

            emit(ChatsLoaded(chatsPagination!));

            // ✅ ИСПРАВЛЕНИЕ: Отключена автоматическая предзагрузка для предотвращения бесконечных запросов
            // _prefetchNextPages(nextPage + 1, emit);
          } catch (e) {
            debugPrint('ChatsBloc._getNextPageChatsEvent: Error: $e');
            // ✅ ИСПРАВЛЕНИЕ: Убираем страницу из списка загружающихся при ошибке
            _loadingPages.remove(nextPage);
            emit(ChatsError(_toUserFriendlyErrorMessage(e)));
          }
        } else {
          // ✅ ИСПРАВЛЕНИЕ: Убираем страницу из списка загружающихся при отсутствии интернета
          _loadingPages.remove(nextPage);
          emit(ChatsError('Нет подключения к интернету'));
        }
      } else {
        debugPrint(
            '=================-=== ChatsBloc._getNextPageChatsEvent: No more pages to load');
      }
    }
  }

  // 🔹 ИСПРАВЛЕННЫЙ МЕТОД
  Future<void> _updateChatsFromSocketFetch(
      UpdateChatsFromSocket event, Emitter<ChatsState> emit) async {
    // ✅ ИСПРАВЛЕНО: Используем uniqueId для логирования и привязки
    final eventChatKey = event.chat.uniqueId ?? event.chat.id.toString();
    debugPrint(
        '=================-=== ChatsBloc._updateChatsFromSocketFetch: Updating chat via socket: uniqueId=${event.chat.uniqueId}, id=${event.chat.id}, type: ${event.chat.type}, unreadCount from event: ${event.chat.unreadCount}');

    if (event.chat.id == 0 || event.chat.type == null) {
      debugPrint(
          '=================-=== ChatsBloc: Invalid chat from socket, skipping');
      return;
    }

    // ✅ ИСПРАВЛЕНО: Очищаем старые записи из Map (старше 3 секунд)
    // Это предотвращает накопление памяти (оставляем немного больше времени чем cooldown)
    final now = DateTime.now();
    _resetUnreadCountTimestamps.removeWhere((chatKey, timestamp) =>
        now.difference(timestamp) > Duration(seconds: 3));

    if (state is ChatsLoaded) {
      final currentState = state as ChatsLoaded;
      final currentChats = currentState.chatsPagination.data;
      final updatedChats = List<Chats>.from(currentChats);
      // ✅ ИСПРАВЛЕНО: Используем uniqueId для поиска чата, fallback на id если uniqueId null
      final chatIndex = updatedChats.indexWhere((chat) {
        if (event.chat.uniqueId != null && chat.uniqueId != null) {
          return chat.uniqueId == event.chat.uniqueId;
        }
        // Fallback на id если uniqueId не доступен
        return chat.id == event.chat.id;
      });

      if (chatIndex != -1) {
        final oldChat = updatedChats[chatIndex];

        debugPrint(
            'ChatsBloc: Old chat data - ID: ${oldChat.id}, unreadCount: ${oldChat.unreadCount}, lastMessage: "${oldChat.lastMessage}"');
        debugPrint(
            'ChatsBloc: New chat data - ID: ${event.chat.id}, unreadCount: ${event.chat.unreadCount}, lastMessage: "${event.chat.lastMessage}"');

        // 🔹 Проверяем, изменилось ли сообщение
        final isNewMessage = oldChat.lastMessage != event.chat.lastMessage;

        // ✅ НОВАЯ ПРОВЕРКА: Этот чат сейчас открыт?
        // Это ключевое решение - если чат открыт, пользователь читает сообщения в реальном времени
        // и не нужно инкрементировать счетчик для них
        // ✅ ИСПРАВЛЕНО: Используем uniqueId для проверки активного чата
        final bool isChatCurrentlyOpen =
            _chatTracker.isChatActive(event.chat.uniqueId);
        debugPrint(
            '=================-=== ChatsBloc: Chat ${event.chat.uniqueId ?? event.chat.id} currently open: $isChatCurrentlyOpen');

        // 🔹 НОВАЯ ЛОГИКА: Определяем новый счётчик
        int newUnreadCount;

        if (isChatCurrentlyOpen) {
          // ✅ ЧАТ ОТКРЫТ → ВСЕГДА ДЕРЖИМ СЧЁТЧИК НА 0
          // Пользователь находится внутри чата и читает сообщения в реальном времени
          // Не нужно показывать счетчик непрочитанных для сообщений, которые он видит прямо сейчас
          newUnreadCount = 0;
          debugPrint(
              'ChatsBloc: Chat ${event.chat.uniqueId ?? event.chat.id} is OPEN, forcing unreadCount to 0');

          // ✅ ВАЖНО: Очищаем timestamp, если он есть
          // Когда чат открыт, нам не нужен cooldown
          _resetUnreadCountTimestamps.remove(eventChatKey);
        } else {
          // ✅ ЧАТ ЗАКРЫТ → Проверяем cooldown и применяем обычную логику

          final resetTimestamp = _resetUnreadCountTimestamps[eventChatKey];
          final now = DateTime.now();
          final isRecentlyReset = resetTimestamp != null &&
              now.difference(resetTimestamp) < _resetCooldownDuration;

          if (isRecentlyReset) {
            // ✅ Только что вышли из чата (в течение 2 секунд) → держим 0
            // Это защита от "мерцания" счетчика сразу после выхода
            newUnreadCount = 0;
            final elapsed = now.difference(resetTimestamp).inMilliseconds;
            debugPrint(
                '=================-=== ChatsBloc: Chat ${event.chat.uniqueId ?? event.chat.id} recently exited (${elapsed}ms ago), keeping 0');
          } else {
            // ✅ Прошло больше 2 секунд - нормальная логика обновления счетчика

            // Очищаем старый timestamp
            _resetUnreadCountTimestamps.remove(eventChatKey);

            if (event.chat.unreadCount > 0) {
              // ✅ Сервер прислал счётчик > 0 → используем его
              // Это означает, что на сервере есть непрочитанные сообщения
              newUnreadCount = event.chat.unreadCount;
              debugPrint(
                  '=================-=== ChatsBloc: Using server unreadCount: $newUnreadCount');
            } else if (isNewMessage) {
              // ✅ Новое сообщение, но сервер прислал 0 → инкрементируем локально
              // Это означает, что пришло новое сообщение, но сервер еще не обновил счетчик
              newUnreadCount = oldChat.unreadCount + 1;
              debugPrint(
                  '=================-=== ChatsBloc: New message detected, incremented to $newUnreadCount');
            } else {
              // ✅ Без изменений → оставляем старое значение или используем значение с сервера
              newUnreadCount = event.chat.unreadCount >= 0
                  ? event.chat.unreadCount
                  : oldChat.unreadCount;
              debugPrint(
                  '=================-=== ChatsBloc: No changes, keeping unreadCount: $newUnreadCount');
            }
          }
        }

        // 🔹 Обновляем чат, сохраняя старое имя и аватар
        final updatedChat = oldChat.copyWith(
          lastMessage: event.chat.lastMessage,
          unreadCount: newUnreadCount,
          createDate: event.chat.createDate,
          messageType: event.chat.messageType,
        );

        updatedChats[chatIndex] = updatedChat;

        // ✅ Если пришло новое сообщение — поднимаем чат наверх (как в мессенджерах)
        if (isNewMessage) {
          final movedChat = updatedChats.removeAt(chatIndex);
          int insertIndex = 0;
          if (updatedChats.isNotEmpty &&
              updatedChats.first.type == 'support' &&
              movedChat.type != 'support') {
            insertIndex = 1;
          }
          if (insertIndex > updatedChats.length) {
            insertIndex = updatedChats.length;
          }
          updatedChats.insert(insertIndex, movedChat);
          debugPrint(
              '=================-=== ChatsBloc: Moved chat ${movedChat.uniqueId ?? movedChat.id} to top');
        }
        debugPrint(
            'ChatsBloc._updateChatsFromSocketFetch: Updated existing chat uniqueId: ${event.chat.uniqueId ?? event.chat.id}, final unreadCount: $newUnreadCount');
      } else {
        // Новый чат
        updatedChats.insert(0, event.chat);
        debugPrint(
            '=================-=== ChatsBloc._updateChatsFromSocketFetch: Added new chat uniqueId: ${event.chat.uniqueId ?? event.chat.id}, unreadCount: ${event.chat.unreadCount}');
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

      // ✅ ИСПРАВЛЕНИЕ: Эмитим состояние только если действительно есть изменения
      // Это предотвращает лишние обновления UI и повторные запросы
      final hasRealChanges = chatIndex == -1 || // Новый чат
          (chatIndex != -1 &&
              (currentChats[chatIndex].unreadCount !=
                      updatedChats[chatIndex].unreadCount ||
                  currentChats[chatIndex].lastMessage !=
                      updatedChats[chatIndex].lastMessage));

      if (hasRealChanges) {
        emit(ChatsLoaded(chatsPagination!));
      } else {
        // ✅ ВАЖНО: Если изменений нет, мы всё равно должны обновить внутреннее состояние Блока (chatsPagination),
        // но можем пропустить emit, если UI и так в актуальном состоянии.
        // Однако, для надежности при сокетах лучше эмитить всегда, так как порядок мог измениться
        emit(ChatsLoaded(chatsPagination!));
        debugPrint(
            'ChatsBloc._updateChatsFromSocketFetch: Emitting state even with no data changes to ensure correct order/sync');
      }
    } else if (state is ChatsInitial || state is ChatsError) {
      if (_isFetching) {
        debugPrint(
            '=================-=== ChatsBloc._updateChatsFromSocketFetch: Skipping fetch, another fetch is in progress');
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
        emit(ChatsError(_toUserFriendlyErrorMessage(e)));
      }
      _isFetching = false;
    }
  }

  // Удаление чата
  Future<void> _deleteChat(DeleteChat event, Emitter<ChatsState> emit) async {
    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.deleteChat(event.chatId);
        if (response['result'] == true) {
          emit(ChatsDeleted(
              event.localizations.translate('chat_deleted_successfully')));
        } else {
          emit(ChatsError(
              event.localizations.translate('you_dont_delete_this_group')));
        }
      } catch (e) {
        emit(ChatsError(event.localizations.translate('error_delete_chat')));
      }
    } else {
      await OfflineRuntime.instance.outboxService.enqueue(
        id: 'chat_delete_${event.chatId}_${DateTime.now().millisecondsSinceEpoch}',
        module: OfflineModule.chatList,
        entityType: 'chat',
        entityId: event.chatId.toString(),
        operationType: 'delete',
        payload: {
          'chatId': event.chatId,
        },
        idempotencyKey:
            'chat-delete-${event.chatId}-${DateTime.now().millisecondsSinceEpoch}',
        priority: RequestPriority.high,
      );
      if (state is ChatsLoaded) {
        final currentState = state as ChatsLoaded;
        final updatedData = currentState.chatsPagination.data
            .where((chat) => chat.id != event.chatId)
            .toList(growable: false);
        chatsPagination = PaginationDTO(
          data: updatedData,
          count: updatedData.length,
          total: updatedData.length,
          perPage: currentState.chatsPagination.perPage,
          currentPage: currentState.chatsPagination.currentPage,
          totalPage: currentState.chatsPagination.totalPage,
        );
        emit(ChatsLoaded(chatsPagination!));
      }
      emit(ChatsDeleted(
        event.localizations.translate('action_accepted'),
      ));
    }
  }

  // Очистка чатов
  Future<void> _clearChatsEvent(
      ClearChats event, Emitter<ChatsState> emit) async {
    debugPrint(
        '=================-=== ChatsBloc._clearChatsEvent: Clearing chats and resetting chatsPagination for endpoint $endPoint');
    chatsPagination = null;
    _lastFetchedPage = 0;
    _prefetchedPages.clear(); // Очищаем кеш предзагрузки
    emit(ChatsInitial());
  }

  // 🔹 ИСПРАВЛЕННЫЙ МЕТОД - Сброс счётчика непрочитанных
  Future<void> _resetUnreadCount(
      ResetUnreadCount event, Emitter<ChatsState> emit) async {
    debugPrint(
        '=================-=== ChatsBloc._resetUnreadCount: Resetting unreadCount for chat ID: ${event.chatId}');

    if (state is ChatsLoaded) {
      final currentState = state as ChatsLoaded;
      final updatedChats = List<Chats>.from(currentState.chatsPagination.data);
      // ✅ ИСПРАВЛЕНО: Ищем чат по id (event.chatId это int), но сохраняем по uniqueId
      final chatIndex =
          updatedChats.indexWhere((chat) => chat.id == event.chatId);

      if (chatIndex != -1) {
        final oldChat = updatedChats[chatIndex];
        final oldUnreadCount = oldChat.unreadCount;

        // ✅ ИСПРАВЛЕНО: Обновляем только конкретный чат, обнуляем счетчик локально
        // Это скрывает счетчик на 0.5 секунды после выхода из чата
        updatedChats[chatIndex] = oldChat.copyWith(unreadCount: 0);

        // ✅ ИСПРАВЛЕНО: Сохраняем timestamp обнуления счетчика по uniqueId
        // Это нужно, чтобы в течение 2 секунд после выхода скрывать счетчик,
        // даже если приходит новое сообщение или обновляется список чатов. После 2 секунд показываем индикатор
        final chatKey = oldChat.uniqueId ?? event.chatId.toString();
        _resetUnreadCountTimestamps[chatKey] = DateTime.now();

        debugPrint(
            'ChatsBloc._resetUnreadCount: Reset unreadCount for chat uniqueId: ${oldChat.uniqueId ?? event.chatId} from $oldUnreadCount to 0. Timestamp saved for 2s cooldown.');

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
        debugPrint(
            '=================-=== ChatsBloc._resetUnreadCount: Chat ID ${event.chatId} not found in current state');
      }
    } else {
      debugPrint(
          '=================-=== ChatsBloc._resetUnreadCount: State is not ChatsLoaded, cannot reset unreadCount');
    }
  }
}
