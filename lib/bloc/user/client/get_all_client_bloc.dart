import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:meta/meta.dart';

part 'get_all_client_event.dart';
part 'get_all_client_state.dart';

class GetAllClientBloc extends Bloc<GetAllClientEvent, GetAllClientState> {
  GetAllClientBloc() : super(GetAllClientInitial()) {
    on<GetAllClientEv>(_getUsers);
  }

  Future<void> _getUsers(GetAllClientEv event, Emitter<GetAllClientState> emit) async {

    try {
      emit(GetAllClientLoading());

      var res = await ApiService().getAllUser();

      emit(GetAllClientSuccess(dataUser: res));
    } catch(e) {
      emit(GetAllClientError(message: e.toString()));
    }

  }
}
