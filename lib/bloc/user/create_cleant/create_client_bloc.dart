import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:meta/meta.dart';

part 'create_client_event.dart';
part 'create_client_state.dart';

class CreateClientBloc extends Bloc<CreateClientEvent, CreateClientState> {
  CreateClientBloc() : super(CreateClientInitial()) {
    on<CreateClientEv>(_createClientFun);
  }

 Future<void> _createClientFun(CreateClientEv event, Emitter<CreateClientState> emit) async {
  if (await _checkInternetConnection()) {
    try {
      emit(CreateClientLoading());
      var res = await ApiService().createNewClient(event.userId);
      var chatId = res['chatId'];
      emit(CreateClientSuccess(chatId: chatId));
    } catch (e) {
      print('ApiService: Error creating client: $e');
      emit(CreateClientError(message: 'Ошибка при создании чата: $e'));
    }
  } else {
    emit(CreateClientError(message: 'Нет подключения к интернету'));
  }
}


  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      //print('Нет интернета!'); // For debugging
      return false;
    }
  }
}
