import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'messaging_state.dart';

class MessagingCubit extends Cubit<MessagingState> {
  final ApiService apiService;
  Message? selectedMessage;
  Message? _editingMessage;
  MessagingCubit(this.apiService) : super(MessagingInitial());

  Future<void> getMessages(final int chatId) async {
    try {
      emit(MessagesLoadingState());
      final messages = await apiService.getMessages(chatId);

      Message? pinnedMessage;
      for (var message in messages) {
        if (message.isPinned) {
          pinnedMessage = message;
          break;
        }
      }

      if (pinnedMessage != null) {
        emit(PinnedMessageState(
            pinnedMessage: pinnedMessage, messages: messages));
      } else {
        emit(MessagesLoadedState(messages: messages));
      }
    } catch (e) {
      emit(MessagesErrorState(error: e.toString()));
    }
  }

void updateMessageReadStatus(int messageId, int userId, DateTime readAt) {
  if (state is MessagesLoadedState) {
    final currentState = state as MessagesLoadedState;
    final messages = currentState.messages;
    // Находим сообщение по ID
    final index = messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      final message = messages[index];
      // Создаем новый объект Message с обновленным readStatus
      final updatedMessage = Message(
        id: message.id,
        text: message.text,
        type: message.type,
        isMyMessage: message.isMyMessage,
        isRead: true, // Обновляем статус прочтения
        createMessateTime: message.createMessateTime,
        senderName: message.senderName,
        readStatus: ReadStatus(
          read: [
            ...(message.readStatus?.read ?? []),
            User(
              id: userId,
              name: '',
              lastname: '',
              login: '',
              email: '',
              phone: '',
              image: '',
              lastSeen: null,
              fullName: 'User $userId',
              readAt: readAt,
            ),
          ],
          unread: message.readStatus?.unread ?? [],
        ),
      );
      // Обновляем сообщение в списке
      messages[index] = updatedMessage;
      // Эмитим обновление состояния с новым списком сообщений
      emit(MessagesLoadedState(messages: messages));
    }
  } else if (state is PinnedMessageState) {
    final currentState = state as PinnedMessageState;
    final messages = currentState.messages;
    final index = messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      final message = messages[index];
      final updatedMessage = Message(
        id: message.id,
        text: message.text,
        type: message.type,
        isMyMessage: message.isMyMessage,
        isRead: true,
        createMessateTime: message.createMessateTime,
        senderName: message.senderName,
        readStatus: ReadStatus(
          read: [
            ...(message.readStatus?.read ?? []),
            User(
              id: userId,
              name: '',
              lastname: '',
              login: '',
              email: '',
              phone: '',
              image: '',
              lastSeen: null,
              fullName: 'User $userId',
              readAt: readAt,
            ),
          ],
          unread: message.readStatus?.unread ?? [],
        ),
      );
      messages[index] = updatedMessage;
      emit(PinnedMessageState(
        pinnedMessage: currentState.pinnedMessage,
        messages: messages,
      ));
    }
  }
}


  void addMessageFormSocket(Message message) {
    if (state is MessagesLoadedState) {
      final currentState = state as MessagesLoadedState;
      final messages = currentState.messages;
      messages.insert(0, message);
      emit(MessagesLoadedState(messages: messages));
    } else if (state is PinnedMessageState) {
      final currentState = state as PinnedMessageState;
      final messages = currentState.messages;
      messages.insert(0, message);
      emit(PinnedMessageState(
          pinnedMessage: currentState.pinnedMessage, messages: messages));
    }
  }

void updateMessageFromSocket(Message updatedMessage) {
  if (state is MessagesLoadedState) {
    final currentState = state as MessagesLoadedState;
    final messages = currentState.messages;
    final index = messages.indexWhere((msg) => msg.id == updatedMessage.id);
    if (index != -1) {
      messages[index] = updatedMessage;
      emit(MessagesLoadedState(messages: messages));
    }
  } else if (state is PinnedMessageState) {
    final currentState = state as PinnedMessageState;
    final messages = currentState.messages;
    final index = messages.indexWhere((msg) => msg.id == updatedMessage.id);
    if (index != -1) {
      messages[index] = updatedMessage;
      emit(PinnedMessageState(
          pinnedMessage: currentState.pinnedMessage, messages: messages));
    }
  } else if (state is EditingMessageState) {
    final currentState = state as EditingMessageState;
    final messages = currentState.messages;
    final index = messages.indexWhere((msg) => msg.id == updatedMessage.id);
    if (index != -1) {
      messages[index] = updatedMessage;
      emit(EditingMessageState(
        editingMessage: currentState.editingMessage,
        messages: messages,
        pinnedMessage: currentState.pinnedMessage,
      ));
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
      pinnedMessage: null, 
    ));
  } else if (state is PinnedMessageState) {
    final currentState = state as PinnedMessageState;
    emit(EditingMessageState(
      editingMessage: message,
      messages: currentState.messages,
      pinnedMessage: currentState.pinnedMessage,
    ));
  }
}

  void clearEditingMessage() {
    _editingMessage = null;
    if (state is EditingMessageState) {
      final messages = (state as EditingMessageState).messages;
      final pinnedMessage = (state as EditingMessageState).pinnedMessage;

      if (pinnedMessage != null) {
        emit(PinnedMessageState(
            pinnedMessage: pinnedMessage, messages: messages));
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
    if (state is MessagesLoadedState || state is PinnedMessageState) {
      final messages = (state is MessagesLoadedState)
          ? (state as MessagesLoadedState).messages
          : (state as PinnedMessageState).messages;

      final pinnedMessage = (state is PinnedMessageState)
          ? (state as PinnedMessageState).pinnedMessage
          : null;

      emit(
        ReplyingToMessageState(
          replyingMessage: message,
          messages: messages,
          pinnedMessage: pinnedMessage,
        ),
      );
    }
  }

  void clearReplyMessage() {
    if (state is ReplyingToMessageState) {
      final messages = (state as ReplyingToMessageState).messages;
      final pinnedMessage = (state as ReplyingToMessageState).pinnedMessage;

      if (pinnedMessage != null) {
        emit(PinnedMessageState(
            pinnedMessage: pinnedMessage, messages: messages));
      } else {
        emit(MessagesLoadedState(messages: messages));
      }
    }
  }

  void pinMessage(Message message) {
    if (state is MessagesLoadedState) {
      final messages = (state as MessagesLoadedState).messages;
      emit(PinnedMessageState(pinnedMessage: message, messages: messages));
      apiService.pinMessage(message.id.toString());
    }
  }

  void unpinMessage() {
    if (state is PinnedMessageState) {
      final messages = (state as PinnedMessageState).messages;
      final pinnedMessageId = (state as PinnedMessageState).pinnedMessage.id;
      apiService.unpinMessage(pinnedMessageId.toString());
      emit(MessagesLoadedState(messages: messages));
    }
  }

void pinMessageFromSocket(Message message) {
  if (state is MessagesLoadedState) {
    final currentState = state as MessagesLoadedState;
    final messages = currentState.messages;
    final existingMessage = messages.firstWhere(
      (msg) => msg.id == message.id,
    );
    if (existingMessage == null) {
      messages.add(message);
    }
    emit(PinnedMessageState(pinnedMessage: message, messages: messages));
  }
}

void unpinMessageFromSocket(int messageId) {
  if (state is PinnedMessageState) {
    final currentState = state as PinnedMessageState;
    final messages = currentState.messages;
    final updatedMessages = List<Message>.from(messages);
    emit(MessagesLoadedState(messages: updatedMessages));
  }
}

}
