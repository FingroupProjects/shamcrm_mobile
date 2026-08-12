import 'dart:io';
import 'package:crm_task_manager/utils/user_friendly_error.dart';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/lead/advertising_campaign_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'advertising_campaign_event.dart';
part 'advertising_campaign_state.dart';

class GetAllAdvertisingCampaignBloc extends Bloc<GetAllAdvertisingCampaignEvent,
    GetAllAdvertisingCampaignState> {
  GetAllAdvertisingCampaignBloc() : super(GetAllAdvertisingCampaignInitial()) {
    on<GetAllAdvertisingCampaignEv>(_getCampaigns);
  }

  Future<void> _getCampaigns(
    GetAllAdvertisingCampaignEv event,
    Emitter<GetAllAdvertisingCampaignState> emit,
  ) async {
    emit(GetAllAdvertisingCampaignLoading());

    if (await _checkInternetConnection()) {
      try {
        final res = await ApiService().getAllAdvertisingCampaigns();
        emit(GetAllAdvertisingCampaignSuccess(dataCampaigns: res));
      } catch (e) {
        emit(GetAllAdvertisingCampaignError(message: friendlyError(e)));
      }
    } else {
      emit(GetAllAdvertisingCampaignError(
        message: 'Нет подключения к интернету',
      ));
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
