import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chatById_event.dart';
import 'package:crm_task_manager/bloc/chats/chatById_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatByIdBloc extends Bloc<ChatByIdEvent, ChatByIdState> {
  final ApiService apiService;

  ChatByIdBloc(this.apiService) : super(ChatByIdInitial()) {
    on<FetchChatByIdEvent>(_getChatById);
  }

  Future<void> _getChatById(FetchChatByIdEvent event, Emitter<ChatByIdState> emit) async {
    emit(ChatByIdLoading());

    if (await _checkInternetConnection()) {
      try {
        final chat = await apiService.getChatById(event.chatId);
        emit(ChatByIdLoaded(chat));
      } catch (e) {
        emit(ChatByIdError('Не удалось загрузить данные чата: ${e.toString()}'));
      }
    } else {
      emit(ChatByIdError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
