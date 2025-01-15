import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_event.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_state.dart';
import 'package:crm_task_manager/models/chatById_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:crm_task_manager/api/service/api_service.dart';

class ChatProfileBloc extends Bloc<ChatProfileEvent, ChatProfileState> {
  final ApiService apiService;

  ChatProfileBloc(this.apiService) : super(ChatProfileInitial()) {
    on<FetchChatProfile>((event, emit) async {
      emit(ChatProfileLoading());
      try {
        final profile = await apiService.getChatProfile(event.chatId);
        emit(ChatProfileLoaded(profile));
      } catch (e) {
        if (e.toString() == "Такого Лида не существует") {
          emit(ChatProfileError("Такого Лида не существует"));
        } else {
          emit(ChatProfileError("Ошибка!"));
        }
      }
    });
  }
}
