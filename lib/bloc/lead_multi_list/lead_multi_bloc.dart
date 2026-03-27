import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:meta/meta.dart';

part 'lead_multi_event.dart';
part 'lead_multi_state.dart';

class GetAllLeadMultiBloc extends Bloc<GetAllLeadEvent, GetAllLeadState> {
  GetAllLeadMultiBloc() : super(GetAllLeadInitial()) {
    on<GetAllLeadEv>(_getLeads);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _getLeads(GetAllLeadEv event, Emitter<GetAllLeadState> emit) async {
    emit(GetAllLeadLoading());

    if (await _checkInternetConnection()) {
      try {
        var res = await ApiService().getAllLeadMulti();
        emit(GetAllLeadSuccess(dataLead: res));
      } catch (e) {
        emit(GetAllLeadError(message: e.toString()));
      }
    } else {
      emit(GetAllLeadError(message: 'Нет подключения к интернету'));
    }
  }
}
