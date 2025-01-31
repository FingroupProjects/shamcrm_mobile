import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'messaging_state.dart';

class MessagingCubit extends Cubit<MessagingState> {
  final ApiService apiService;

  Message? selectedMessage;

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
      pinnedMessage: currentState.pinnedMessage, 
      messages: messages
    ));
  }
}


void setReplyMessage(Message message) {
  if (state is MessagesLoadedState || state is PinnedMessageState) {
    final messages = (state is MessagesLoadedState)
        ? (state as MessagesLoadedState).messages
        : (state as PinnedMessageState).messages;
    emit(
      ReplyingToMessageState(replyingMessage: message, messages: messages),
    );
  }
}

  void clearReplyMessage() {
    if (state is ReplyingToMessageState) {
      final messages = (state as ReplyingToMessageState).messages;
      emit(MessagesLoadedState(messages: messages));
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
      apiService.pinMessage(pinnedMessageId.toString());
      emit(MessagesLoadedState(messages: messages));
    }
  }
}
