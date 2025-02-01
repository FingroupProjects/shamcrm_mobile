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
      emit(MessagesLoadedState(messages: messages));
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
    }
  }

Future<void> setReplyMessage(Message message) async {
  if (state is MessagesLoadedState) {
    final messages = (state as MessagesLoadedState).messages;
    emit(ReplyingToMessageState(replyingMessage: message, messages: messages));
    
  }
}

  // Метод для сброса состояния ответа
  void clearReplyMessage() {
  if (state is ReplyingToMessageState) {
    final messages = (state as ReplyingToMessageState).messages;
    emit(MessagesLoadedState(messages: messages));
    
  }
}

}
