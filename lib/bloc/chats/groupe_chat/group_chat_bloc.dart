import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'group_chat_event.dart';
import 'group_chat_state.dart';

class GroupChatBloc extends Bloc<GroupChatEvent, GroupChatState> {
  final ApiService apiService;

  GroupChatBloc(this.apiService) : super(GroupChatInitial()) {
    on<CreateGroupChat>(_createGroupChat);
  }

  Future<void> _createGroupChat(CreateGroupChat event, Emitter<GroupChatState> emit) async {
    emit(GroupChatLoading());

    if (!await _checkInternetConnection()) {
      emit(GroupChatError('Нет подключения к интернету'));
      return;
    }

    try {
      final result = await apiService.createGroupChat(
        name: event.name,
        userId: event.userId,
      );

      if (result['success']) {
        emit(GroupChatSuccess('Групповой чат успешно создана'));
      } else {
        emit(GroupChatError(result['message']));
      }
    } catch (e) {
      emit(GroupChatError('Ошибка создания гр. чата: ${e.toString()}'));
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
