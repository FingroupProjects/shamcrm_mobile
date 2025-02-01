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
      emit(GroupChatError(event.localizations.translate('no_internet_connection')));
      return;
    }

    try {
      final result = await apiService.createGroupChat(
        name: event.name,
        userId: event.userId,
      );

      if (result['success']) {
        emit(GroupChatSuccess(event.localizations.translate('group_chat_created_successfully')));
      } else {
        emit(GroupChatError(result['message']));
      }
    } catch (e) {
      emit(GroupChatError(event.localizations.translate('error_create_group_chat')));
    }
  }

  Future<void> _addUserToGroup(AddUserToGroup event, Emitter<GroupChatState> emit) async {
    emit(AddUserToGroupLoading());

    if (!await _checkInternetConnection()) {
      emit(AddUserToGroupError(event.localizations.translate('no_internet_connection')));
      return;
    }

    try {
  final result = await apiService.addUserToGroup(chatId: event.chatId, userId: event.userId);

  if (result['success']) {
    emit(AddUserToGroupSuccess(result[event.localizations.translate('user_added_successfully')]));
  } else {
    emit(AddUserToGroupError(result[event.localizations.translate('error_add_user')]));
  }
} on SocketException {
  emit(AddUserToGroupError(event.localizations.translate('no_internet_connection')));
}
 catch (e) {
      emit(AddUserToGroupError(event.localizations.translate('error_add_user')));
    }
  }

  // Новый метод для удаления пользователя из группы
  Future<void> _deleteUserFromGroup(
      DeleteUserFromGroup event, Emitter<GroupChatState> emit) async {
    emit(GroupChatLoading());

    if (!await _checkInternetConnection()) {
      emit(GroupChatError(event.localizations.translate('no_internet_connection')));
      return;
    }

    try {
        final result = await apiService.deleteUserFromGroup(chatId: event.chatId, userId: event.userId);

        // if (result['result'] == true) {
  if (result['success']) {
          
        emit(GroupChatDeleted(event.localizations.translate('user_delete_successfully')));
      } else {
        emit(GroupChatError(result[event.localizations.translate('cannot_delete_user')]));
      }
    } catch (e) {
      emit(GroupChatError(event.localizations.translate('error_delete_user')));
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
