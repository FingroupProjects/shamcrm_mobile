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

  Future<void> getMessages(int chatId, {String? search}) async {
    try {
      emit(MessagesLoadingState());
      final messages = await apiService.getMessages(chatId, search: search);

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
    } catch (e) {
      emit(MessagesErrorState(error: e.toString()));
    }
  }
Future<void> syncMessagesInBackground(int chatId) async {
    try {
      final messages = await apiService.getMessages(chatId);
      if (state is MessagesLoadedState) {
        // Обновляем сообщения только если текущее состояние MessagesLoadedState
        final currentMessages = (state as MessagesLoadedState).messages;
        // Обновляем только новые или изменённые сообщения
        final updatedMessages = _mergeMessages(currentMessages, messages);
        emit(MessagesLoadedState(messages: updatedMessages));
        debugPrint('MessagingCubit: Synced messages in background, new count: ${updatedMessages.length}');
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
  if (state is MessagesLoadedState) {
    final currentState = state as MessagesLoadedState;
    final messages = List<Message>.from(currentState.messages);

    final localMessageIndex = messages.indexWhere((msg) => msg.id < 0);

    if (localMessageIndex != -1) {
      messages[localMessageIndex] = updatedMessage;
      emit(MessagesLoadedState(messages: messages));
    } else {
      final index = messages.indexWhere((msg) => msg.id == updatedMessage.id);
      if (index != -1) {
        messages[index] = updatedMessage;
        emit(MessagesLoadedState(messages: messages));
      } else {
        messages.insert(0, updatedMessage);
        emit(MessagesLoadedState(messages: messages));
      }
    }
  } else if (state is PinnedMessagesState) {
    final currentState = state as PinnedMessagesState;
    final messages = List<Message>.from(currentState.messages);

    final localMessageIndex = messages.indexWhere((msg) => msg.id < 0);

    if (localMessageIndex != -1) {
      messages[localMessageIndex] = updatedMessage;
      emit(PinnedMessagesState(
        pinnedMessages: currentState.pinnedMessages,
        messages: messages,
      ));
    } else {
      final index = messages.indexWhere((msg) => msg.id == updatedMessage.id);
      if (index != -1) {
        messages[index] = updatedMessage;
        emit(PinnedMessagesState(
          pinnedMessages: currentState.pinnedMessages,
          messages: messages,
        ));
      } else {
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
      messages[localMessageIndex] = updatedMessage;
      emit(EditingMessageState(
        editingMessage: currentState.editingMessage,
        messages: messages,
        pinnedMessages: currentState.pinnedMessages,
      ));
    } else {
      final index = messages.indexWhere((msg) => msg.id == updatedMessage.id);
      if (index != -1) {
        messages[index] = updatedMessage;
        emit(EditingMessageState(
          editingMessage: currentState.editingMessage,
          messages: messages,
          pinnedMessages: currentState.pinnedMessages,
        ));
      } else {
        messages.insert(0, updatedMessage);
        emit(EditingMessageState(
          editingMessage: currentState.editingMessage,
          messages: messages,
          pinnedMessages: currentState.pinnedMessages,
        ));
      }
    }
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
      // final messages = (state as MessagesLoadedState).messages;
      // final pinnedMessages = [message];
      // emit(PinnedMessagesState(pinnedMessages: pinnedMessages, messages: messages));
      apiService.pinMessage(message.id.toString());
    } else if (state is PinnedMessagesState) {
      // final currentState = state as PinnedMessagesState;
      // final messages = currentState.messages;
      // final pinnedMessages = List<Message>.from(currentState.pinnedMessages)..add(message);
      // emit(PinnedMessagesState(pinnedMessages: pinnedMessages, messages: messages));
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

    // Добавляем новые сообщения и обновляем существующие
    for (var newMsg in newMessages) {
      currentMap[newMsg.id] = newMsg;
    }

    // Преобразуем в список и сортируем по времени (если есть createMessateTime)
    merged.addAll(currentMap.values);
    merged.sort((a, b) => (b.createMessateTime ?? '').compareTo(a.createMessateTime ?? ''));
    return merged;
  }
}
