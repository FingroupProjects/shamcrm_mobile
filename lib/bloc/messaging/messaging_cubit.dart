import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'messaging_state.dart';

class MessagingCubit extends Cubit<MessagingState> {
  final ApiService apiService;
  
  MessagingCubit(this.apiService) : super(MessagingInitial());

  Future<void> getMessages(final int chatId) async {
    try {
      emit(MessagesLoadingState());
      final messages = await apiService.getMessages(chatId);
      
      // Извлекаем ID сообщений
      final messageIds = messages.map((msg) => msg.id).toList();
      
      // Отправляем ID прочитанных сообщений на сервер
      await apiService.readChatMessages(chatId, messageIds);
      
      emit(MessagesLoadedState(messages: messages));
    } catch (e) {
      emit(MessagesErrorState(error: e.toString()));
    }
  }

  void addMessageFormSocket(Message message) {
    if (state is MessagesLoadedState) {
      final state = this.state as MessagesLoadedState;
      final messages = state.messages;
      messages.insert(0, message);
      emit(MessagesLoadedState(messages: messages));
    }
  }
}