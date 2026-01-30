import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'messaging_state.dart';

class MessagingCubit extends Cubit<MessagingState> {
  final ApiService apiService;
  Message? selectedMessage;
  Message? _editingMessage;

  MessagingCubit(this.apiService) : super(MessagingInitial());

  /// ✅ НОВЫЙ МЕТОД: Показать кэшированные сообщения (без загрузки с API)
  /// Используется для мгновенной загрузки чата из кэша, пока идут запросы к серверу
  void showCachedMessages(List<Message> cachedMessages) {
    debugPrint('=================-=== ✅ MessagingCubit: Showing ${cachedMessages.length} cached messages');
    
    List<Message> pinnedMessages = [];
    for (var message in cachedMessages) {
      if (message.isPinned) {
        pinnedMessages.add(message);
      }
    }

    if (pinnedMessages.isNotEmpty) {
      // Для закрепленных сообщений нужен специальный стейт, но пока используем обычный
      emit(MessagesLoadedState(messages: cachedMessages, isFromCache: true));
    } else {
      emit(MessagesLoadedState(messages: cachedMessages, isFromCache: true));
    }
  }

  Future<void> getMessages(int chatId, {String? search, String? chatType}) async {
    try {
      emit(MessagesLoadingState());
      
      // Проверяем инициализацию ApiService
      await _ensureApiServiceInitialized();
      
      final messages = await apiService.getMessages(chatId, search: search, chatType: chatType);

      List<Message> pinnedMessages = [];
      for (var message in messages) {
        if (message.isPinned) {
          pinnedMessages.add(message);
        }
      }

      if (pinnedMessages.isNotEmpty) {
        emit(PinnedMessagesState(pinnedMessages: pinnedMessages, messages: messages));
      } else {
        emit(MessagesLoadedState(messages: messages, isFromCache: false)); // ✅ Явно указываем что не из кэша
      }
    } catch (e) {
      debugPrint('MessagingCubit: getMessages error: $e');
      emit(MessagesErrorState(error: e.toString()));
    }
  }

  Future<void> getMessagesWithFallback(int chatId, {String? search, String? chatType}) async {
    emit(MessagesLoadingState());
    
    try {
      // Основная попытка загрузки
      await _ensureApiServiceInitialized();
      final messages = await apiService.getMessages(chatId, search: search, chatType: chatType);

      List<Message> pinnedMessages = [];
      for (var message in messages) {
        if (message.isPinned) {
          pinnedMessages.add(message);
        }
      }

      if (pinnedMessages.isNotEmpty) {
        emit(PinnedMessagesState(pinnedMessages: pinnedMessages, messages: messages));
      } else {
        emit(MessagesLoadedState(messages: messages, isFromCache: false)); // ✅ Явно указываем что не из кэша
      }
      
      debugPrint('=================-=== MessagingCubit: Successfully loaded ${messages.length} messages');
    } catch (e) {
      debugPrint('MessagingCubit: Primary getMessages failed: $e');
      
      // Если ошибка связана с URL, пытаемся инициализировать заново
      if (_isUrlError(e.toString())) {
        debugPrint('=================-=== MessagingCubit: URL error detected, attempting recovery...');
        
        try {
          // Попытка 1: Принудительная инициализация
          await apiService.initialize();
          final messages = await apiService.getMessages(chatId, search: search, chatType: chatType);
          
          List<Message> pinnedMessages = [];
          for (var message in messages) {
            if (message.isPinned) {
              pinnedMessages.add(message);
            }
          }

          if (pinnedMessages.isNotEmpty) {
            emit(PinnedMessagesState(pinnedMessages: pinnedMessages, messages: messages));
          } else {
            emit(MessagesLoadedState(messages: messages));
          }
          
          debugPrint('MessagingCubit: Recovery attempt successful!');
          return;
        } catch (e2) {
          debugPrint('=================-=== MessagingCubit: Recovery attempt failed: $e2');
        }
        
        // Показываем частичную ошибку с возможностью повтора
        emit(MessagesPartialErrorState(
          error: 'Проблема с подключением к серверу. Проверьте настройки домена.',
          canRetry: true
        ));
      } else {
        // Для других ошибок показываем стандартное сообщение
        emit(MessagesErrorState(error: _getReadableError(e.toString())));
      }
    }
  }

  // Вспомогательный метод для обеспечения инициализации ApiService
  Future<void> _ensureApiServiceInitialized() async {
    try {
      // Проверяем, инициализирован ли baseUrl
      final baseUrl = await apiService.getDynamicBaseUrl();
      if (baseUrl.isEmpty || baseUrl == 'null') {
        debugPrint('MessagingCubit: BaseURL empty, forcing initialization');
        await apiService.initialize();
      }
    } catch (e) {
      debugPrint('=================-=== MessagingCubit: Error ensuring API initialization: $e');
      throw Exception('Не удалось инициализировать подключение к серверу');
    }
  }

  // Проверяет, связана ли ошибка с URL
  bool _isUrlError(String error) {
    return error.contains('No host specified in URI null') || 
           error.contains('Base URL is not initialized') ||
           error.contains('Домен не установлен') ||
           error.contains('type \'Null\' is not a subtype of type \'String\'');
  }

  // Преобразует техническую ошибку в понятную пользователю
  String _getReadableError(String error) {
    if (error.contains('type \'Null\' is not a subtype of type \'String\'')) {
      return 'Ошибка обработки данных с сервера';
    }
    if (error.contains('No host specified in URI null')) {
      return 'Проблема с настройками подключения';
    }
    return error;
  }

  void showEmptyChat() {
    emit(MessagesLoadedState(messages: []));
    debugPrint('MessagingCubit: Showing empty chat interface');
  }

  Future<void> syncMessagesInBackground(int chatId, {String? chatType}) async {
    try {
      final messages = await apiService.getMessages(chatId, chatType: chatType);
      if (state is MessagesLoadedState) {
        final currentMessages = (state as MessagesLoadedState).messages;
        final updatedMessages = _mergeMessages(currentMessages, messages);
        emit(MessagesLoadedState(messages: updatedMessages));
        debugPrint('=================-=== MessagingCubit: Synced messages in background, new count: ${updatedMessages.length}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error syncing messages in background: $e, StackTrace: $stackTrace');
    }
  }

  void addLocalMessage(Message message) {
    if (state is MessagesLoadedState) {
      final currentState = state as MessagesLoadedState;
      final messages = List<Message>.from(currentState.messages);
      messages.insert(0, message);
      emit(MessagesLoadedState(messages: messages));
    } else if (state is PinnedMessagesState) {
      final currentState = state as PinnedMessagesState;
      final messages = List<Message>.from(currentState.messages);
      messages.insert(0, message);
      emit(PinnedMessagesState(
        pinnedMessages: currentState.pinnedMessages, 
        messages: messages,
      ));
    }
  }

  void addMessageFormSocket(Message message) {
    if (state is MessagesLoadedState) {
      final currentState = state as MessagesLoadedState;
      final messages = currentState.messages;
      messages.insert(0, message);
      emit(MessagesLoadedState(messages: messages));
    } else if (state is PinnedMessagesState) {
      final currentState = state as PinnedMessagesState;
      final messages = currentState.messages;
      messages.insert(0, message);
      emit(PinnedMessagesState(
        pinnedMessages: currentState.pinnedMessages, messages: messages));
    }
  }

  void updateMessageFromSocket(Message updatedMessage) {
  debugPrint('🔄 MessagingCubit.updateMessageFromSocket: Processing message id=${updatedMessage.id}, isMyMessage=${updatedMessage.isMyMessage}');
  debugPrint('🔍 ДИАГНОСТИКА: senderName ДО добавления: "${updatedMessage.senderName}"');  // ← ДОБАВЬ ЭТУ СТРОКУ
  
  if (state is MessagesLoadedState) {
    final currentState = state as MessagesLoadedState;
    final messages = List<Message>.from(currentState.messages);

    final localMessageIndex = messages.indexWhere((msg) => msg.id < 0);

    if (localMessageIndex != -1) {
      debugPrint('🔄 MessagingCubit: Replacing local temp message at index $localMessageIndex');
      messages[localMessageIndex] = updatedMessage;
      debugPrint('🔍 ДИАГНОСТИКА: senderName ПОСЛЕ замены: "${messages[localMessageIndex].senderName}"');  // ← ДОБАВЬ ЭТУ СТРОКУ
      emit(MessagesLoadedState(messages: messages));
    } else {
      final index = messages.indexWhere((msg) => msg.id == updatedMessage.id);
      
      if (index != -1) {
        debugPrint('🔄 MessagingCubit: Updating existing message at index $index');
        debugPrint('🔍 ДИАГНОСТИКА: Старый senderName: "${messages[index].senderName}"');  // ← ДОБАВЬ ЭТУ СТРОКУ
        messages[index] = updatedMessage;
        debugPrint('🔍 ДИАГНОСТИКА: Новый senderName: "${messages[index].senderName}"');  // ← ДОБАВЬ ЭТУ СТРОКУ
        emit(MessagesLoadedState(messages: messages));
      } else {
        debugPrint('🔄 MessagingCubit: Adding new message to list');
        messages.insert(0, updatedMessage);
        debugPrint('🔍 ДИАГНОСТИКА: senderName нового сообщения: "${messages[0].senderName}"');  // ← ДОБАВЬ ЭТУ СТРОКУ
        emit(MessagesLoadedState(messages: messages));
      }
    }
  
    
    debugPrint('=================-=== ✅ MessagingCubit.updateMessageFromSocket: Completed, total messages: ${messages.length}');
  } else if (state is PinnedMessagesState) {
    final currentState = state as PinnedMessagesState;
    final messages = List<Message>.from(currentState.messages);

    final localMessageIndex = messages.indexWhere((msg) => msg.id < 0);

    if (localMessageIndex != -1) {
      debugPrint('=================-=== 🔄 MessagingCubit (Pinned): Replacing local temp message');
      messages[localMessageIndex] = updatedMessage;
      emit(PinnedMessagesState(
        pinnedMessages: currentState.pinnedMessages,
        messages: messages,
      ));
    } else {
      final index = messages.indexWhere((msg) => msg.id == updatedMessage.id);
      
      if (index != -1) {
        debugPrint('🔄 MessagingCubit (Pinned): Updating existing message');
        
        final oldMessage = messages[index];
        if (oldMessage.isMyMessage != updatedMessage.isMyMessage) {
          debugPrint('⚠️ MessagingCubit (Pinned): isMyMessage CHANGED from ${oldMessage.isMyMessage} to ${updatedMessage.isMyMessage}');
        }
        
        messages[index] = updatedMessage;
        emit(PinnedMessagesState(
          pinnedMessages: currentState.pinnedMessages,
          messages: messages,
        ));
      } else {
        debugPrint('=================-=== 🔄 MessagingCubit (Pinned): Adding new message');
        messages.insert(0, updatedMessage);
        emit(PinnedMessagesState(
          pinnedMessages: currentState.pinnedMessages,
          messages: messages,
        ));
      }
    }
  } else if (state is EditingMessageState) {
    final currentState = state as EditingMessageState;
    final messages = List<Message>.from(currentState.messages);

    final localMessageIndex = messages.indexWhere((msg) => msg.id < 0);

    if (localMessageIndex != -1) {
      debugPrint('=================-=== 🔄 MessagingCubit (Editing): Replacing local temp message');
      messages[localMessageIndex] = updatedMessage;
      emit(EditingMessageState(
        editingMessage: currentState.editingMessage,
        messages: messages,
        pinnedMessages: currentState.pinnedMessages,
      ));
    } else {
      final index = messages.indexWhere((msg) => msg.id == updatedMessage.id);
      
      if (index != -1) {
        debugPrint('🔄 MessagingCubit (Editing): Updating existing message');
        
        final oldMessage = messages[index];
        if (oldMessage.isMyMessage != updatedMessage.isMyMessage) {
          debugPrint('⚠️ MessagingCubit (Editing): isMyMessage CHANGED from ${oldMessage.isMyMessage} to ${updatedMessage.isMyMessage}');
        }
        
        messages[index] = updatedMessage;
        emit(EditingMessageState(
          editingMessage: currentState.editingMessage,
          messages: messages,
          pinnedMessages: currentState.pinnedMessages,
        ));
      } else {
        debugPrint('=================-=== 🔄 MessagingCubit (Editing): Adding new message');
        messages.insert(0, updatedMessage);
        emit(EditingMessageState(
          editingMessage: currentState.editingMessage,
          messages: messages,
          pinnedMessages: currentState.pinnedMessages,
        ));
      }
    }
  } else {
    debugPrint('=================-=== ⚠️ MessagingCubit.updateMessageFromSocket: Invalid state: ${state.runtimeType}');
  }
}

  void startEditingMessage(Message message) {
    _editingMessage = message;
    if (state is MessagesLoadedState) {
      final currentState = state as MessagesLoadedState;
      emit(EditingMessageState(
        editingMessage: message,
        messages: currentState.messages,
        pinnedMessages: [], 
      ));
    } else if (state is PinnedMessagesState) {
      final currentState = state as PinnedMessagesState;
      emit(EditingMessageState(
        editingMessage: message,
        messages: currentState.messages,
        pinnedMessages: currentState.pinnedMessages,
      ));
    }
  }

  void clearEditingMessage() {
    _editingMessage = null;
    if (state is EditingMessageState) {
      final messages = (state as EditingMessageState).messages;
      final pinnedMessages = (state as EditingMessageState).pinnedMessages;
      if (pinnedMessages.isNotEmpty) {
        emit(PinnedMessagesState(
          pinnedMessages: pinnedMessages, messages: messages));
      } else {
        emit(MessagesLoadedState(messages: messages));
      }
    }
  }

  Future<void> editMessage(String newMessage) async {
    if (_editingMessage != null) {
      try {
        await apiService.editMessage(_editingMessage!.id.toString(), newMessage);
        clearEditingMessage();
      } catch (e) {
        emit(MessagesErrorState(error: e.toString()));
      }
    }
  }

  void setReplyMessage(Message message) {
    if (state is MessagesLoadedState || state is PinnedMessagesState) {
      final messages = (state is MessagesLoadedState)
          ? (state as MessagesLoadedState).messages
          : (state as PinnedMessagesState).messages;
      final pinnedMessages = (state is PinnedMessagesState)
          ? (state as PinnedMessagesState).pinnedMessages
          : <Message>[];
      emit(
        ReplyingToMessageState(
          replyingMessage: message,
          messages: messages,
          pinnedMessages: pinnedMessages,
        ),
      );
    }
  }

  void clearReplyMessage() {
    if (state is ReplyingToMessageState) {
      final messages = (state as ReplyingToMessageState).messages;
      final pinnedMessages = (state as ReplyingToMessageState).pinnedMessages;
      if (pinnedMessages.isNotEmpty) {
        emit(PinnedMessagesState(
          pinnedMessages: pinnedMessages, messages: messages));
      } else {
        emit(MessagesLoadedState(messages: messages));
      }
    }
  }

  void pinMessage(Message message) {
    if (state is MessagesLoadedState) {
      apiService.pinMessage(message.id.toString());
    } else if (state is PinnedMessagesState) {
      apiService.pinMessage(message.id.toString());
    }
  }
  
  void updatePinnedMessages(List<Message> updatedPinnedMessages) {
    if (state is MessagesLoadedState) {
      final messages = (state as MessagesLoadedState).messages;
      emit(PinnedMessagesState(pinnedMessages: updatedPinnedMessages, messages: messages));
    } else if (state is PinnedMessagesState) {
      final currentState = state as PinnedMessagesState;
      final messages = currentState.messages;
      emit(PinnedMessagesState(pinnedMessages: updatedPinnedMessages, messages: messages));
    }
  }

  void unpinMessage(Message message) {
    if (state is PinnedMessagesState) {
      final currentState = state as PinnedMessagesState;
      final messages = currentState.messages;
      final pinnedMessages = List<Message>.from(currentState.pinnedMessages)..remove(message);
      if (pinnedMessages.isEmpty) {
        emit(MessagesLoadedState(messages: messages));
      } else {
        emit(PinnedMessagesState(pinnedMessages: pinnedMessages, messages: messages));
      }
      apiService.unpinMessage(message.id.toString());
    }
  }

  void pinMessageFromSocket(Message message) {
    if (state is MessagesLoadedState) {
      final currentState = state as MessagesLoadedState;
      final messages = currentState.messages;
      final pinnedMessages = [message];
      emit(PinnedMessagesState(pinnedMessages: pinnedMessages, messages: messages));
    } else if (state is PinnedMessagesState) {
      final currentState = state as PinnedMessagesState;
      final messages = currentState.messages;
      final pinnedMessages = List<Message>.from(currentState.pinnedMessages)..add(message);
      emit(PinnedMessagesState(pinnedMessages: pinnedMessages, messages: messages));
    }
  }

  void unpinMessageFromSocket(int messageId) {
    if (state is PinnedMessagesState) {
      final currentState = state as PinnedMessagesState;
      final messages = currentState.messages;
      final pinnedMessages = List<Message>.from(currentState.pinnedMessages)
        ..removeWhere((msg) => msg.id == messageId);
      if (pinnedMessages.isEmpty) {
        emit(MessagesLoadedState(messages: messages));
      } else {
        emit(PinnedMessagesState(pinnedMessages: pinnedMessages, messages: messages));
      }
    }
  }

  void updateMessageReadStatusFromSocket(Map readData) {
    if (state is MessagesLoadedState || state is PinnedMessagesState || state is EditingMessageState) {
      final messages = state is MessagesLoadedState
          ? (state as MessagesLoadedState).messages
          : state is PinnedMessagesState
              ? (state as PinnedMessagesState).messages
              : (state as EditingMessageState).messages;
      final List messageIds = readData['messages'];
      final userId = readData['user']['id'];
      final userFullName = "${readData['user']['name']} ${readData['user']['lastname']}";
      final readAt = DateTime.parse(readData['read_at']).add(Duration(hours: 5));
      for (var messageId in messageIds) {
        final messageIndex = messages.indexWhere((msg) => msg.id == messageId);
        if (messageIndex != -1) {
          final message = messages[messageIndex];
          final readStatus = message.readStatus ?? ReadStatus(read: [], unread: []);
          final readUser = ReadUser(
            userId: userId,
            readAt: readAt.toString(),
            user: User(
              id: userId,
              name: readData['user']['name'],
              lastname: readData['user']['lastname'],
              login: readData['user']['login'],
              email: readData['user']['email'],
              phone: readData['user']['phone'],
              image: readData['user']['image'],
              lastSeen: readData['user']['last_seen'],
              online: readData['user']['online'],
              fullName: userFullName,
              readAt: readAt,
            ),
          );
          readStatus.read.add(readUser.user);
          readStatus.unread.removeWhere((user) => user.id == userId);
          final updatedMessage = message.copyWith(
            readStatus: readStatus,
            isRead: true,
          );
          messages[messageIndex] = updatedMessage;
        }
      }
      if (state is MessagesLoadedState) {
        emit(MessagesLoadedState(messages: messages));
      } else if (state is PinnedMessagesState) {
        emit(PinnedMessagesState(
          pinnedMessages: (state as PinnedMessagesState).pinnedMessages,
          messages: messages,
        ));
      } else if (state is EditingMessageState) {
        emit(EditingMessageState(
          editingMessage: (state as EditingMessageState).editingMessage,
          messages: messages,
          pinnedMessages: (state as EditingMessageState).pinnedMessages,
        ));
      }
    }
  }

  List<Message> _mergeMessages(List<Message> currentMessages, List<Message> newMessages) {
    final merged = <Message>[];
    final currentMap = {for (var msg in currentMessages) msg.id: msg};

    for (var newMsg in newMessages) {
      currentMap[newMsg.id] = newMsg;
    }

    merged.addAll(currentMap.values);
    merged.sort((a, b) => (b.createMessateTime ?? '').compareTo(a.createMessateTime ?? ''));
    return merged;
  }
}