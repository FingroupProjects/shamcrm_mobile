import 'dart:async';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/city_model.dart';
import 'package:meta/meta.dart';

part 'city_event.dart';
part 'city_state.dart';

class GetAllCityBloc extends Bloc<GetAllCityEvent, GetAllCityState> {
  GetAllCityBloc() : super(GetAllCityInitial()) {
    on<GetAllCityEv>(_getCities);
  }

  Future<void> _getCities(
      GetAllCityEv event, Emitter<GetAllCityState> emit) async {
    emit(GetAllCityLoading());

    if (await _checkInternetConnection()) {
      try {
        final res = await ApiService().getAllCity();
        emit(GetAllCitySuccess(dataCity: res.result ?? const []));
      } catch (e) {
        emit(GetAllCityError(message: friendlyError(e)));
      }
    } else {
      emit(GetAllCityError(message: 'Нет подключения к интернету'));
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
