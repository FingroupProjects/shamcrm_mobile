import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:meta/meta.dart';

part 'get_all_client_event.dart';
part 'get_all_client_state.dart';

class GetAllClientBloc extends Bloc<GetAllClientEvent, GetAllClientState> {
  final ApiService apiService;

  GetAllClientBloc({required this.apiService}) : super(GetAllClientInitial()) {
    on<GetAllClientEv>(_getUsers);
    on<GetAnotherClientEv>(_getAnotherUsers);
    on<GetUsersNotInChatEv>(_getUsersNotInChat);  
    on<GetUsersWithoutCorporateChatEv>(_getUsersWithoutCorporateChat);
  }

  Future<void> _getUsers(
      GetAllClientEv event, Emitter<GetAllClientState> emit) async {
    try {
      emit(GetAllClientLoading());
      var res = await apiService.getAllUser();
      emit(GetAllClientSuccess(dataUser: res));
    } catch (e) {
      emit(GetAllClientError(message: e.toString()));
    }
  }

  Future<void> _getAnotherUsers(
      GetAnotherClientEv event, Emitter<GetAllClientState> emit) async {
    try {
      emit(GetAllClientLoading());
      var res = await apiService.getAnotherUsers();
      emit(GetAllClientSuccess(dataUser: res));
    } catch (e) {
      emit(GetAllClientError(message: e.toString()));
    }
  }
  Future<void> _getUsersWithoutCorporateChat(
      GetUsersWithoutCorporateChatEv event, Emitter<GetAllClientState> emit) async {
    try {
      emit(GetAllClientLoading());
      var res = await apiService.getUsersWihtoutCorporateChat();
      emit(GetAllClientSuccess(dataUser: res));
    } catch (e) {
      emit(GetAllClientError(message: e.toString()));
    }
  }

  Future<void> _getUsersNotInChat(
      GetUsersNotInChatEv event, Emitter<GetAllClientState> emit) async {
    try {
      emit(GetAllClientLoading());
      var res = await apiService.getUsersNotInChat(event.chatId);
      emit(GetAllClientSuccess(dataUser: res));
    } catch (e) {
      emit(GetAllClientError(message: e.toString()));
    }
  }

}

