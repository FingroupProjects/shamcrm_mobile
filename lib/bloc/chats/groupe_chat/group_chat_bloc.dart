import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'group_chat_event.dart';
import 'group_chat_state.dart';

class GroupChatBloc extends Bloc<GroupChatEvent, GroupChatState> {
  final ApiService apiService;

  GroupChatBloc(this.apiService) : super(GroupChatInitial()) {
    on<CreateGroupChat>(_createGroupChat);
    on<AddUserToGroup>(_addUserToGroup);
    on<DeleteUserFromGroup>(_deleteUserFromGroup);
  }

  Future<void> _createGroupChat(
      CreateGroupChat event, Emitter<GroupChatState> emit) async {
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
        emit(GroupChatSuccess('Групповой чат успешно создан'));
      } else {
        emit(GroupChatError(result['message']));
      }
    } catch (e) {
      emit(GroupChatError('Ошибка создания гр. чата!'));
    }
  }

  Future<void> _addUserToGroup(AddUserToGroup event, Emitter<GroupChatState> emit) async {
    emit(AddUserToGroupLoading());

    if (!await _checkInternetConnection()) {
      emit(AddUserToGroupError('Нет подключения к интернету'));
      return;
    }

    try {
  final result = await apiService.addUserToGroup(chatId: event.chatId, userId: event.userId);

  if (result['success']) {
    emit(AddUserToGroupSuccess(result['Пользователь успешно добавленв группу!']));
  } else {
    emit(AddUserToGroupError(result['Ошибка доб поль']));
  }
} on SocketException {
  emit(AddUserToGroupError('Проблема с интернет-соединением.'));
}
 catch (e) {
      emit(AddUserToGroupError(
          'Ошибка добавления пользователя!'));
    }
  }

  // Новый метод для удаления пользователя из группы
  Future<void> _deleteUserFromGroup(
      DeleteUserFromGroup event, Emitter<GroupChatState> emit) async {
    emit(GroupChatLoading());

    if (!await _checkInternetConnection()) {
      emit(GroupChatError('Нет подключения к интернету'));
      return;
    }

    try {
        final result = await apiService.deleteUserFromGroup(chatId: event.chatId, userId: event.userId);

        // if (result['result'] == true) {
  if (result['success']) {
          
        emit(GroupChatDeleted('Пользователь успешно удален из группы'));
      } else {
        emit(GroupChatError(result['Нельзя удалить участника']));
      }
    } catch (e) {
      emit(GroupChatError('Ошибка удаления пользователя!'));
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
