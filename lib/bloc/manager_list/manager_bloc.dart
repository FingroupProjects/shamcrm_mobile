import 'dart:io';
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

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _getManagers(GetAllManagerEv event, Emitter<GetAllManagerState> emit) async {
    emit(GetAllManagerLoading());

    if (await _checkInternetConnection()) {
      try {
        var res = await ApiService().getAllManager();
        emit(GetAllManagerSuccess(dataManager: res));
      } catch (e) {
        emit(GetAllManagerError(message: e.toString()));
      }
    } else {
      emit(GetAllManagerError(message: 'Нет подключения к интернету'));
    }
  }
}
