import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_event.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_state.dart';

class MainFieldBloc extends Bloc<MainFieldEvent, MainFieldState> {
  MainFieldBloc() : super(MainFieldInitial()) {
    on<FetchMainFields>(_fetchMainFields);
  }

  Future<void> _fetchMainFields(
      FetchMainFields event, Emitter<MainFieldState> emit) async {
    emit(MainFieldLoading());

    try {
      final internetAvailable = await _checkInternetConnection();
      if (!internetAvailable) {
        emit(MainFieldError(message: 'Нет подключения к интернету'));
        return;
      }

      final mainFields = await ApiService().getMainFields(event.directoryId);
      emit(MainFieldSuccess(mainFields: mainFields));
    } catch (e) {
      emit(MainFieldError(message: e.toString()));
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