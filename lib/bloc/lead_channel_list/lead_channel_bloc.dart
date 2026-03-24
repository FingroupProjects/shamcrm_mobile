import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/lead_filter_channel_model.dart';
import 'package:meta/meta.dart';

part 'lead_channel_event.dart';
part 'lead_channel_state.dart';

class GetAllLeadChannelBloc
    extends Bloc<GetAllLeadChannelEvent, GetAllLeadChannelState> {
  GetAllLeadChannelBloc() : super(GetAllLeadChannelInitial()) {
    on<GetAllLeadChannelEv>(_getChannels);
  }

  Future<void> _getChannels(
    GetAllLeadChannelEv event,
    Emitter<GetAllLeadChannelState> emit,
  ) async {
    emit(GetAllLeadChannelLoading());

    if (await _checkInternetConnection()) {
      try {
        final res = await ApiService().getLeadFilterChannels();
        emit(GetAllLeadChannelSuccess(dataChannels: res));
      } catch (e) {
        emit(GetAllLeadChannelError(message: e.toString()));
      }
    } else {
      emit(GetAllLeadChannelError(message: 'Нет подключения к интернету'));
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
