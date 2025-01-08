import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_event.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteMessageBloc extends Bloc<DeleteMessageEvent, DeleteMessageState> {
  final ApiService apiService;

  DeleteMessageBloc(this.apiService) : super(DeleteMessageInitial()) {
    on<DeleteMessage>(_deleteMessage); 
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _deleteMessage(DeleteMessage event, Emitter<DeleteMessageState> emit) async {
    if (await _checkInternetConnection()) {
      try {
        await apiService.DeleteMessage(messageId: event.messageId);
      } catch (e) {
        emit(DeleteMessageError('Ошибка удаления уведомления!'));
      }
    } else {
      emit(DeleteMessageError('Нет подключения к интернету'));
    }
  }
}
