import 'dart:async';

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
    try {
      emit(CreateClientLoading());

      var res = await ApiService().createNewClient(event.userId);

      emit(CreateClientSuccess());
    } catch(e) {
      emit(CreateClientError(message: e.toString()));
    }
  }
}
