import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/directory_bloc/directory_event.dart';
import 'package:crm_task_manager/bloc/directory_bloc/directory_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetDirectoryBloc extends Bloc<GetDirectoryEvent, GetDirectoryState> {
  GetDirectoryBloc() : super(GetDirectoryInitial()) {
    on<GetDirectoryEv>(_getDirectories);
  }

  Future<void> _getDirectories(GetDirectoryEv event, Emitter<GetDirectoryState> emit) async {
    emit(GetDirectoryLoading());

    if (await _checkInternetConnection()) {
      try {
        var res = await ApiService().getDirectory();
        emit(GetDirectorySuccess(dataDirectory: res));
      } catch (e) {
        emit(GetDirectoryError(message: e.toString()));
      }
    } else {
      emit(GetDirectoryError(message: 'Нет подключения к интернету'));
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