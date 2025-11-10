import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/source_list_model.dart';
import 'package:crm_task_manager/models/source_model.dart';
import 'package:meta/meta.dart';

part 'source_event.dart';
part 'source_state.dart';

class GetAllSourceBloc extends Bloc<GetAllSourceEvent, GetAllSourceState> {
  GetAllSourceBloc() : super(GetAllSourceInitial()) {
    on<GetAllSourceEv>(_getSources);
  }

  Future<void> _getSources(GetAllSourceEv event, Emitter<GetAllSourceState> emit) async {
    emit(GetAllSourceLoading());

    if (await _checkInternetConnection()) {
      try {
        var res = await ApiService().getAllSource();
        emit(GetAllSourceSuccess(dataSource: res));
      } catch (e) {
        emit(GetAllSourceError(message: e.toString()));
      }
    } else {
      emit(GetAllSourceError(message: 'Нет подключения к интернету'));
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
