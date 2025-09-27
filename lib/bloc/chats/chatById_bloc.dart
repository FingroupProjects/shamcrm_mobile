

// chatById_bloc.dart
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chatById_event.dart';
import 'package:crm_task_manager/bloc/chats/chatById_state.dart';
import 'package:crm_task_manager/models/chatById_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatByIdBloc extends Bloc<ChatByIdEvent, ChatByIdState> {
  final ApiService apiService;
  final AppLocalizations localizations;

  ChatByIdBloc({
    required this.apiService,
    required this.localizations,
  }) : super(ChatByIdInitial()) {
    on<FetchChatByIdEvent>(_getChatById);
  }

  Future<void> _getChatById(FetchChatByIdEvent event, Emitter<ChatByIdState> emit) async {
    emit(ChatByIdLoading());

    if (await _checkInternetConnection()) {
      try {
        // Используем новый метод с интеграцией
        final chat = await apiService.getChatByIdWithIntegration(event.chatId);
        emit(ChatByIdLoaded(chat as ChatById));
      } catch (e) {
        emit(ChatByIdError(localizations.translate('cannot_data_load_chat')));
      }
    } else {
      emit(ChatByIdError(localizations.translate('error_internet_connection')));
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