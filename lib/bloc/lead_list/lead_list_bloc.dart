import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';

class GetAllLeadBloc extends Bloc<GetAllLeadEvent, GetAllLeadState> {
  GetAllLeadBloc() : super(GetAllLeadInitial()) {
    on<GetAllLeadEv>(_getLeads);
  }

  Future<void> _getLeads(GetAllLeadEv event, Emitter<GetAllLeadState> emit) async {
    try {
      emit(GetAllLeadLoading());

      var res = await ApiService().getAllLead();

      emit(GetAllLeadSuccess(dataLead: res));
    } catch (e) {
      emit(GetAllLeadError(message: e.toString()));
    }
  }
}
