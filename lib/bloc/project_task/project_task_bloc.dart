
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetTaskProjectBloc extends Bloc<GetTaskProjectEvent, GetTaskProjectState> {
  GetTaskProjectBloc() : super(GetTaskProjectInitial() as GetTaskProjectState) {
    on<GetTaskProjectEv>(_getProjects);
  }

  Future<void> _getProjects(GetTaskProjectEv event, Emitter<GetTaskProjectState> emit) async {
    emit(GetTaskProjectLoading());

    if (await _checkInternetConnection()) {
      try {
        var res = await ApiService().getTaskProject();
        emit(GetTaskProjectSuccess(dataProject: res));
      } catch (e) {
        emit(GetTaskProjectError(message: e.toString()));
      }
    } else {
      emit(GetTaskProjectError(message: 'Нет подключения к интернету'));
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
