import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:meta/meta.dart';

part 'manager_event.dart';
part 'manager_state.dart';

class GetAllManagerBloc extends Bloc<GetAllManagerEvent, GetAllManagerState> {
  GetAllManagerBloc() : super(GetAllManagerInitial()) {
    on<GetAllManagerEv>(_getManagers);
  }

  Future<void> _getManagers(GetAllManagerEv event, Emitter<GetAllManagerState> emit) async {

    try {
      emit(GetAllManagerLoading());

      var res = await ApiService().getAllManager();

      emit(GetAllManagerSuccess(dataManager: res));
    } catch(e) {
      emit(GetAllManagerError(message: e.toString()));
    }

  }
}
