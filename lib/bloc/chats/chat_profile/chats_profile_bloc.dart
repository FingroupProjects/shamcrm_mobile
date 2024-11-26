import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_event.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatProfileBloc extends Bloc<ChatProfileEvent, ChatProfileState> {
  final ApiService apiService;

  ChatProfileBloc(this.apiService) : super(ChatProfileInitial()) {
    on<FetchChatProfileEvent>(_onFetchChatProfile);
  }

  Future<void> _onFetchChatProfile(
    FetchChatProfileEvent event, 
    Emitter<ChatProfileState> emit
  ) async {
    emit(ChatProfileLoading());
    try {
      final profile = await apiService.getChatProfileByChat(event.chatId);
      emit(ChatProfileLoaded(profile));
    } catch (e) {
      emit(ChatProfileError('Не удалось загрузить профиль чата: $e'));
    }
  }
}