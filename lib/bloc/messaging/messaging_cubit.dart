import 'dart:collection';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chat_messages_page.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/message_reaction_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'messaging_state.dart';

class MessagingCubit extends Cubit<MessagingState> {
  MessagingCubit(this.apiService) : super(MessagingInitial());

  final ApiService apiService;

  Message? selectedMessage;
  Message? _editingMessage;

  Future<void> loadInitialPage(
    int chatId, {
    String? search,
    String? chatType,
  }) async {
    final normalizedSearch = _normalizeSearch(search);
    final currentCollection = _currentCollectionOrNull();

    if (currentCollection == null || currentCollection.messages.isEmpty) {
      emit(MessagesLoadingState());
    } else {
      _emitCollection(
        currentCollection.copyWith(
          isLoadingInitial: true,
          searchQuery: normalizedSearch,
        ),
      );
    }

    try {
      final page = await _fetchMessagesPageWithFallback(
        chatId,
        page: 1,
        search: normalizedSearch,
        chatType: chatType,
      );

      _emitCollection(
        _createCollectionFromPage(
          page,
          searchQuery: normalizedSearch,
          isFromCache: false,
          previousPinnedMessages: currentCollection?.pinnedMessages,
        ),
      );
    } catch (e) {
      debugPrint('MessagingCubit.loadInitialPage error: $e');

      if (currentCollection != null && currentCollection.messages.isNotEmpty) {
        _emitCollection(
          currentCollection.copyWith(
            isLoadingInitial: false,
            searchQuery: normalizedSearch,
          ),
        );
        return;
      }

      if (_isUrlError(e.toString())) {
        emit(
          const MessagesPartialErrorState(
            error:
                'Проблема с подключением к серверу. Проверьте настройки домена.',
            canRetry: true,
          ),
        );
      } else {
        emit(MessagesErrorState(error: _getReadableError(e.toString())));
      }
    }
  }

  Future<void> loadOlderPage(
    int chatId, {
    String? chatType,
  }) async {
    final currentCollection = _currentCollectionOrNull();
    if (currentCollection == null ||
        currentCollection.isFromCache ||
        currentCollection.isLoadingMore ||
        currentCollection.isLoadingInitial ||
        currentCollection.hasReachedMax) {
      return;
    }

    final nextPage = currentCollection.lastLoadedPage + 1;
    _emitCollection(currentCollection.copyWith(isLoadingMore: true));

    try {
      final page = await _fetchMessagesPageWithFallback(
        chatId,
        page: nextPage,
        search: currentCollection.searchQuery,
        chatType: chatType,
      );

      final mergedMessages = _mergeOlderPage(
        currentCollection.messages,
        page.data,
      );

      _emitCollection(
        currentCollection.copyWith(
          messages: mergedMessages,
          pinnedMessages: _buildPinnedMessages(
            mergedMessages,
            previousPinnedMessages: currentCollection.pinnedMessages,
          ),
          hasReachedMax: _hasReachedMax(page),
          isLoadingMore: false,
          loadedPages: {
            ...currentCollection.loadedPages,
            page.meta.currentPage
          },
          lastLoadedPage: nextPage,
          isFromCache: false,
        ),
      );
    } catch (e) {
      debugPrint('MessagingCubit.loadOlderPage error: $e');
      _emitCollection(currentCollection.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refreshLatestPage(
    int chatId, {
    String? chatType,
  }) async {
    final currentCollection = _currentCollectionOrNull();

    try {
      final page = await _fetchMessagesPageWithFallback(
        chatId,
        page: 1,
        search: currentCollection?.searchQuery,
        chatType: chatType,
      );

      final currentMessages = currentCollection?.messages ?? const <Message>[];
      final mergedMessages = _mergeLatestPage(currentMessages, page.data);

      _emitCollection(
        (currentCollection ?? const MessagesCollection()).copyWith(
          messages: mergedMessages,
          pinnedMessages: _buildPinnedMessages(
            mergedMessages,
            previousPinnedMessages: currentCollection?.pinnedMessages,
          ),
          hasReachedMax: _hasReachedMax(page),
          isLoadingInitial: false,
          isLoadingMore: false,
          loadedPages: {
            ...?currentCollection?.loadedPages,
            1,
          },
          lastLoadedPage: (currentCollection?.lastLoadedPage ?? 1) < 1
              ? 1
              : (currentCollection?.lastLoadedPage ?? 1),
          searchQuery: currentCollection?.searchQuery,
          isFromCache: false,
        ),
      );
    } catch (e) {
      debugPrint('MessagingCubit.refreshLatestPage error: $e');
      if (currentCollection != null) {
        _emitCollection(
          currentCollection.copyWith(
            isLoadingInitial: false,
            isLoadingMore: false,
          ),
        );
      }
    }
  }

  Future<void> resetAndSearch(
    int chatId, {
    String? search,
    String? chatType,
  }) async {
    await loadInitialPage(
      chatId,
      search: search,
      chatType: chatType,
    );
  }

  void showCachedMessages(List<Message> cachedMessages) {
    final normalizedMessages = _normalizeMessages(cachedMessages);
    _emitCollection(
      MessagesCollection(
        messages: normalizedMessages,
        pinnedMessages: _buildPinnedMessages(
          normalizedMessages,
          previousPinnedMessages: _currentCollectionOrNull()?.pinnedMessages,
        ),
        isFromCache: true,
        isLoadingInitial: false,
        isLoadingMore: false,
        hasReachedMax: false,
        loadedPages: const {},
        searchQuery: null,
        lastLoadedPage: 0,
      ),
    );
  }

  Future<void> getMessages(
    int chatId, {
    String? search,
    String? chatType,
  }) async {
    await loadInitialPage(
      chatId,
      search: search,
      chatType: chatType,
    );
  }

  Future<void> getMessagesWithFallback(
    int chatId, {
    String? search,
    String? chatType,
  }) async {
    await loadInitialPage(
      chatId,
      search: search,
      chatType: chatType,
    );
  }

  void showEmptyChat() {
    _emitCollection(const MessagesCollection());
    debugPrint('MessagingCubit: Showing empty chat interface');
  }

  Future<void> syncMessagesInBackground(
    int chatId, {
    String? chatType,
  }) async {
    await refreshLatestPage(chatId, chatType: chatType);
  }

  void addLocalMessage(Message message) {
    final currentCollection = _currentCollectionOrEmpty();
    final mergedMessages = _mergeIncomingAtTop(
      currentCollection.messages,
      message,
      searchQuery: currentCollection.searchQuery,
    );

    _emitCollection(
      currentCollection.copyWith(
        messages: mergedMessages,
        pinnedMessages: _buildPinnedMessages(
          mergedMessages,
          previousPinnedMessages: currentCollection.pinnedMessages,
        ),
        isFromCache: false,
      ),
    );
  }

  void addMessageFormSocket(Message message) {
    mergeIncomingMessage(message);
  }

  void mergeIncomingMessage(Message message) {
    final currentCollection = _currentCollectionOrEmpty();
    final mergedMessages = _mergeIncomingAtTop(
      currentCollection.messages,
      message,
      searchQuery: currentCollection.searchQuery,
    );

    if (identical(mergedMessages, currentCollection.messages)) {
      return;
    }

    _emitCollection(
      currentCollection.copyWith(
        messages: mergedMessages,
        pinnedMessages: _buildPinnedMessages(
          mergedMessages,
          previousPinnedMessages: currentCollection.pinnedMessages,
        ),
        isFromCache: false,
      ),
    );
  }

  void mergeMessageUpdate(Message updatedMessage) {
    final currentCollection = _currentCollectionOrNull();
    if (currentCollection == null) return;

    final updatedMessages =
        _replaceMessageById(currentCollection.messages, updatedMessage);
    if (_listEqualsByIdentity(updatedMessages, currentCollection.messages)) {
      return;
    }

    _emitCollection(
      currentCollection.copyWith(
        messages: updatedMessages,
        pinnedMessages: _buildPinnedMessages(
          updatedMessages,
          previousPinnedMessages: currentCollection.pinnedMessages,
        ),
      ),
    );
  }

  void updateMessageFromSocket(Message updatedMessage) {
    mergeIncomingMessage(updatedMessage);
  }

  void removeMessageLocally(int messageId) {
    final currentCollection = _currentCollectionOrNull();
    if (currentCollection == null) return;

    final updatedMessages = currentCollection.messages
        .where((message) => message.id != messageId)
        .toList(growable: false);

    _emitCollection(
      currentCollection.copyWith(
        messages: updatedMessages,
        pinnedMessages: currentCollection.pinnedMessages
            .where((message) => message.id != messageId)
            .toList(growable: false),
      ),
    );
  }

  void startEditingMessage(Message message) {
    _editingMessage = message;
    final collection = _currentCollectionOrNull();
    if (collection == null) return;

    emit(
      EditingMessageState(
        editingMessage: message,
        collection: collection,
      ),
    );
  }

  void clearEditingMessage() {
    _editingMessage = null;
    final currentState = state;
    if (currentState is EditingMessageState) {
      _emitBaseCollectionState(currentState.collection);
    }
  }

  Future<void> editMessage(String newMessage) async {
    if (_editingMessage == null) return;

    final editingMessage = _editingMessage!;

    try {
      await apiService.editMessage(editingMessage.id.toString(), newMessage);
      mergeMessageUpdate(
        editingMessage.copyWith(
          text: newMessage,
          isChanged: true,
        ),
      );
      clearEditingMessage();
    } catch (e) {
      debugPrint('MessagingCubit.editMessage error: $e');
    }
  }

  void setReplyMessage(Message message) {
    final collection = _currentCollectionOrNull();
    if (collection == null) return;

    emit(
      ReplyingToMessageState(
        replyingMessage: message,
        collection: collection,
      ),
    );
  }

  void clearReplyMessage() {
    final currentState = state;
    if (currentState is ReplyingToMessageState) {
      _emitBaseCollectionState(currentState.collection);
    }
  }

  Future<void> pinMessage(Message message) async {
    final currentCollection = _currentCollectionOrNull();
    if (currentCollection == null) return;

    try {
      await apiService.pinMessage(message.id.toString());
      mergeMessageUpdate(message.copyWith(isPinned: true));
    } catch (e) {
      debugPrint('MessagingCubit.pinMessage error: $e');
    }
  }

  void updatePinnedMessages(List<Message> updatedPinnedMessages) {
    final currentCollection = _currentCollectionOrNull();
    if (currentCollection == null) return;

    _emitCollection(
      currentCollection.copyWith(
        pinnedMessages: List<Message>.unmodifiable(updatedPinnedMessages),
      ),
    );
  }

  Future<void> unpinMessage(Message message) async {
    final currentCollection = _currentCollectionOrNull();
    if (currentCollection == null) return;

    try {
      await apiService.unpinMessage(message.id.toString());
      mergeMessageUpdate(message.copyWith(isPinned: false));
    } catch (e) {
      debugPrint('MessagingCubit.unpinMessage error: $e');
    }
  }

  void pinMessageFromSocket(Message message) {
    mergeMessageUpdate(message.copyWith(isPinned: true));
  }

  void unpinMessageFromSocket(int messageId) {
    final existing = findMessageById(messageId);
    if (existing == null) return;
    mergeMessageUpdate(existing.copyWith(isPinned: false));
  }

  void updateMessageReadStatusFromSocket(Map readData) {
    final currentCollection = _currentCollectionOrNull();
    if (currentCollection == null) return;

    final messageIds = (readData['messages'] as List?) ?? const [];
    final userData = readData['user'] as Map?;
    if (userData == null) return;

    final userId = userData['id'];
    final userFullName = "${userData['name']} ${userData['lastname']}".trim();
    final readAtRaw = readData['read_at']?.toString();
    final parsedReadAt = readAtRaw == null
        ? null
        : DateTime.tryParse(readAtRaw)?.add(const Duration(hours: 5));
    final lastSeenRaw = userData['last_seen'];
    final lastSeen =
        lastSeenRaw is String ? DateTime.tryParse(lastSeenRaw) : null;

    final readUser = User(
      id: userId is int ? userId : int.tryParse(userId?.toString() ?? '') ?? 0,
      name: userData['name']?.toString() ?? '',
      lastname: userData['lastname']?.toString() ?? '',
      login: userData['login']?.toString(),
      email: userData['email']?.toString(),
      phone: userData['phone']?.toString(),
      image: userData['image']?.toString(),
      lastSeen: lastSeen,
      fullName: userFullName,
      readAt: parsedReadAt,
    );

    final updatedMessages = currentCollection.messages.map((message) {
      if (!messageIds.contains(message.id)) {
        return message;
      }

      final currentReadStatus = message.readStatus;
      final read = [
        ...?currentReadStatus?.read.where((user) => user.id != readUser.id),
        readUser,
      ];
      final unread = [
        ...?currentReadStatus?.unread.where((user) => user.id != readUser.id),
      ];

      return message.copyWith(
        readStatus: ReadStatus(read: read, unread: unread),
        isRead: true,
      );
    }).toList(growable: false);

    _emitCollection(
      currentCollection.copyWith(messages: updatedMessages),
    );
  }

  void updateMessageReactionsFromSocket({
    required int messageId,
    required List<MessageReaction> reactions,
  }) {
    final currentCollection = _currentCollectionOrNull();
    if (currentCollection == null) return;

    final updatedMessages = currentCollection.messages.map((message) {
      if (message.id != messageId) return message;
      return message.copyWith(reactions: reactions);
    }).toList(growable: false);

    _emitCollection(
      currentCollection.copyWith(messages: updatedMessages),
    );
  }

  Message? findMessageById(int messageId) {
    final currentCollection = _currentCollectionOrNull();
    if (currentCollection == null) return null;

    for (final message in currentCollection.messages) {
      if (message.id == messageId) {
        return message;
      }
    }

    return null;
  }

  Future<ChatMessagesPage> _fetchMessagesPageWithFallback(
    int chatId, {
    required int page,
    String? search,
    String? chatType,
  }) async {
    try {
      await _ensureApiServiceInitialized();
      return await apiService.getMessagesPage(
        chatId,
        page: page,
        search: search,
        chatType: chatType,
      );
    } catch (e) {
      debugPrint('MessagingCubit: page fetch failed: $e');

      if (_isUrlError(e.toString())) {
        await apiService.initialize();
        return apiService.getMessagesPage(
          chatId,
          page: page,
          search: search,
          chatType: chatType,
        );
      }

      rethrow;
    }
  }

  Future<void> _ensureApiServiceInitialized() async {
    try {
      final baseUrl = await apiService.getDynamicBaseUrl();
      if (baseUrl.isEmpty || baseUrl == 'null') {
        await apiService.initialize();
      }
    } catch (e) {
      debugPrint('MessagingCubit: Error ensuring API initialization: $e');
      throw Exception('Не удалось инициализировать подключение к серверу');
    }
  }

  bool _isUrlError(String error) {
    return error.contains('No host specified in URI null') ||
        error.contains('Base URL is not initialized') ||
        error.contains('Домен не установлен') ||
        error.contains('type \'Null\' is not a subtype of type \'String\'');
  }

  String _getReadableError(String error) {
    if (error.contains('type \'Null\' is not a subtype of type \'String\'')) {
      return 'Ошибка обработки данных с сервера';
    }
    if (error.contains('No host specified in URI null')) {
      return 'Проблема с настройками подключения';
    }
    return error;
  }

  MessagesCollection? _currentCollectionOrNull() {
    final currentState = state;
    if (currentState is MessagesCollectionState) {
      return currentState.collection;
    }
    return null;
  }

  MessagesCollection _currentCollectionOrEmpty() {
    return _currentCollectionOrNull() ?? const MessagesCollection();
  }

  MessagesCollection _createCollectionFromPage(
    ChatMessagesPage page, {
    required String? searchQuery,
    required bool isFromCache,
    List<Message>? previousPinnedMessages,
  }) {
    final messages = _normalizeMessages(page.data);
    return MessagesCollection(
      messages: messages,
      pinnedMessages: _buildPinnedMessages(
        messages,
        previousPinnedMessages: previousPinnedMessages,
      ),
      isFromCache: isFromCache,
      isLoadingInitial: false,
      isLoadingMore: false,
      hasReachedMax: _hasReachedMax(page),
      loadedPages: const {1},
      searchQuery: searchQuery,
      lastLoadedPage: 1,
    );
  }

  bool _hasReachedMax(ChatMessagesPage page) {
    return page.meta.currentPage >= page.meta.totalPages ||
        page.data.isEmpty ||
        page.meta.totalPages <= 1 && page.meta.currentPage >= 1;
  }

  String? _normalizeSearch(String? search) {
    final normalized = search?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  void _emitCollection(MessagesCollection collection) {
    final normalizedCollection = collection.copyWith(
      messages: _normalizeMessages(collection.messages),
      pinnedMessages: _buildPinnedMessages(
        collection.messages,
        previousPinnedMessages: collection.pinnedMessages,
      ),
    );

    final currentState = state;
    if (currentState is EditingMessageState) {
      final updatedEditingMessage = normalizedCollection.messages
          .where((message) => message.id == currentState.editingMessage.id)
          .cast<Message?>()
          .firstWhere(
            (message) => message != null,
            orElse: () => null,
          );

      if (updatedEditingMessage != null) {
        emit(
          EditingMessageState(
            editingMessage: updatedEditingMessage,
            collection: normalizedCollection,
          ),
        );
        return;
      }
    }

    if (currentState is ReplyingToMessageState) {
      final updatedReplyMessage = normalizedCollection.messages
          .where((message) => message.id == currentState.replyingMessage.id)
          .cast<Message?>()
          .firstWhere(
            (message) => message != null,
            orElse: () => currentState.replyingMessage,
          );

      emit(
        ReplyingToMessageState(
          replyingMessage: updatedReplyMessage!,
          collection: normalizedCollection,
        ),
      );
      return;
    }

    if (normalizedCollection.pinnedMessages.isNotEmpty) {
      emit(PinnedMessagesState(collection: normalizedCollection));
      return;
    }

    emit(MessagesLoadedState(collection: normalizedCollection));
  }

  void _emitBaseCollectionState(MessagesCollection collection) {
    final normalizedCollection = collection.copyWith(
      messages: _normalizeMessages(collection.messages),
      pinnedMessages: _buildPinnedMessages(
        collection.messages,
        previousPinnedMessages: collection.pinnedMessages,
      ),
    );

    if (normalizedCollection.pinnedMessages.isNotEmpty) {
      emit(PinnedMessagesState(collection: normalizedCollection));
      return;
    }

    emit(MessagesLoadedState(collection: normalizedCollection));
  }

  List<Message> _normalizeMessages(List<Message> messages) {
    final seenIds = <int>{};
    final normalized = <Message>[];

    final sortedMessages = List<Message>.from(messages)
      ..sort((a, b) => _compareMessagesByCreatedAtDesc(a, b));

    for (final message in sortedMessages) {
      if (seenIds.add(message.id)) {
        normalized.add(message);
      }
    }

    return List<Message>.unmodifiable(normalized);
  }

  List<Message> _buildPinnedMessages(
    List<Message> messages, {
    List<Message>? previousPinnedMessages,
  }) {
    final pinnedById = <int, Message>{
      for (final message in messages)
        if (message.isPinned) message.id: message,
    };

    if (pinnedById.isEmpty) {
      return const <Message>[];
    }

    final ordered = <Message>[];
    final seenIds = <int>{};

    if (previousPinnedMessages != null) {
      for (final message in previousPinnedMessages) {
        final updated = pinnedById[message.id];
        if (updated != null && seenIds.add(updated.id)) {
          ordered.add(updated);
        }
      }
    }

    for (final message in messages) {
      final updated = pinnedById[message.id];
      if (updated != null && seenIds.add(updated.id)) {
        ordered.add(updated);
      }
    }

    return List<Message>.unmodifiable(ordered);
  }

  List<Message> _mergeLatestPage(
    List<Message> currentMessages,
    List<Message> latestPageMessages,
  ) {
    final normalizedLatest = _normalizeMessages(latestPageMessages);
    final seenIds = <int>{};
    final merged = <Message>[];

    for (final message in normalizedLatest) {
      if (seenIds.add(message.id)) {
        merged.add(message);
      }
    }

    for (final message in currentMessages) {
      if (seenIds.add(message.id)) {
        merged.add(message);
      }
    }

    return List<Message>.unmodifiable(merged);
  }

  List<Message> _mergeOlderPage(
    List<Message> currentMessages,
    List<Message> olderPageMessages,
  ) {
    final merged = List<Message>.from(currentMessages);
    final indexById = <int, int>{
      for (int index = 0; index < merged.length; index++)
        merged[index].id: index,
    };

    for (final message in _normalizeMessages(olderPageMessages)) {
      final existingIndex = indexById[message.id];
      if (existingIndex != null) {
        merged[existingIndex] = message;
      } else {
        indexById[message.id] = merged.length;
        merged.add(message);
      }
    }

    return List<Message>.unmodifiable(merged);
  }

  List<Message> _mergeIncomingAtTop(
    List<Message> currentMessages,
    Message incomingMessage, {
    String? searchQuery,
  }) {
    if (searchQuery != null &&
        !_matchesSearch(incomingMessage, searchQuery) &&
        !currentMessages.any((message) => message.id == incomingMessage.id)) {
      return currentMessages;
    }

    final updatedMessages = List<Message>.from(currentMessages);
    final pendingIndex =
        _findPendingLocalMessageIndex(updatedMessages, incomingMessage);

    if (pendingIndex != -1) {
      updatedMessages[pendingIndex] = incomingMessage;
      return List<Message>.unmodifiable(updatedMessages);
    }

    final existingIndex = updatedMessages
        .indexWhere((message) => message.id == incomingMessage.id);
    if (existingIndex != -1) {
      updatedMessages[existingIndex] = incomingMessage;
      return List<Message>.unmodifiable(updatedMessages);
    }

    updatedMessages.insert(0, incomingMessage);
    return List<Message>.unmodifiable(updatedMessages);
  }

  int _findPendingLocalMessageIndex(
    List<Message> messages,
    Message incomingMessage,
  ) {
    for (int index = 0; index < messages.length; index++) {
      final message = messages[index];
      if (message.id >= 0 ||
          message.type != incomingMessage.type ||
          message.isMyMessage != incomingMessage.isMyMessage) {
        continue;
      }

      if (incomingMessage.text.isNotEmpty &&
          message.text == incomingMessage.text) {
        return index;
      }

      if (incomingMessage.filePath != null &&
          message.filePath == incomingMessage.filePath) {
        return index;
      }
    }

    return -1;
  }

  List<Message> _replaceMessageById(
    List<Message> source,
    Message updatedMessage,
  ) {
    final index =
        source.indexWhere((message) => message.id == updatedMessage.id);
    if (index == -1) {
      return source;
    }

    final messages = List<Message>.from(source);
    messages[index] = updatedMessage;
    return List<Message>.unmodifiable(messages);
  }

  bool _matchesSearch(Message message, String searchQuery) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return message.text.toLowerCase().contains(normalizedQuery) ||
        message.senderName.toLowerCase().contains(normalizedQuery);
  }

  bool _listEqualsByIdentity(List<Message> left, List<Message> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (int index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  int _compareMessagesByCreatedAtDesc(Message left, Message right) {
    final leftDate = _tryParseMessageDate(left.createMessateTime);
    final rightDate = _tryParseMessageDate(right.createMessateTime);

    if (leftDate != null && rightDate != null) {
      return rightDate.compareTo(leftDate);
    }
    if (leftDate != null) return -1;
    if (rightDate != null) return 1;
    return right.createMessateTime.compareTo(left.createMessateTime);
  }

  DateTime? _tryParseMessageDate(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized)?.toUtc();
  }
}
