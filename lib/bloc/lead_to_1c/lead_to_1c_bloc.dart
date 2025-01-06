import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_event.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

class LeadToCBloc extends Bloc<LeadToCEvent, LeadToCState> {
  final ApiService apiService; // Replace with your API service class

  LeadToCBloc({required this.apiService}) : super(LeadToCInitial()) {
    on<FetchLeadToC>(_onFetchLeadToC);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

Future<void> _onFetchLeadToC(FetchLeadToC event, Emitter<LeadToCState> emit) async {
  emit(LeadToCLoading());
  if (await _checkInternetConnection()) {
    try {
      await apiService.postLeadToC(event.leadId);
      emit(LeadToCSuccess());
    } catch (e) {
      emit(LeadToCError(e.toString()));
    }
  } else {
    emit(LeadToCError('Нет соединения с интернетом'));
  }
}

  // Future<void> _onFetchLeadToC(FetchLeadToC event, Emitter<LeadToCState> emit) async {
  //   emit(LeadToCLoading());

  //   if (await _checkInternetConnection()) {
  //     try {
  //       final leadData = await apiService.postLeadToC(event.leadId);
  //       emit(LeadToCLoaded(leadData));
  //     } catch (e) {
  //       emit(LeadToCError(e.toString()));
  //     }
  //   } else {
  //     emit(LeadToCError('Нет соединения с интернетом'));
  //   }
  // }
}
