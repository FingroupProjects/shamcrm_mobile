import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:meta/meta.dart';

part 'region_event.dart';
part 'region_state.dart';

class GetAllRegionBloc extends Bloc<GetAllRegionEvent, GetAllRegionState> {
  GetAllRegionBloc() : super(GetAllRegionInitial()) {
    on<GetAllRegionEv>(_getRegions);
  }

  Future<void> _getRegions(GetAllRegionEv event, Emitter<GetAllRegionState> emit) async {
    emit(GetAllRegionLoading());

    if (await _checkInternetConnection()) {
      try {
        var res = await ApiService().getAllRegion();
        emit(GetAllRegionSuccess(dataRegion: res));
      } catch (e) {
        emit(GetAllRegionError(message: e.toString()));
      }
    } else {
      emit(GetAllRegionError(message: 'Нет подключения к интернету'));
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
