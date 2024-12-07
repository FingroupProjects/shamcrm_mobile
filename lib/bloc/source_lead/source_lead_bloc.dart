import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_event.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_state.dart';

class SourceLeadBloc extends Bloc<SourceLeadEvent, SourceLeadState> {
  final ApiService apiService;
  bool allSourceLeadFetched = false;

  SourceLeadBloc(this.apiService) : super(SourceLeadInitial()) {
    on<FetchSourceLead>(_fetchSourceLead);
  }

  Future<void> _fetchSourceLead(FetchSourceLead event, Emitter<SourceLeadState> emit) async {
    emit(SourceLeadLoading());

    if (await _checkInternetConnection()) {
      try {
        final sourceLead = await apiService.getSourceLead(); 
        allSourceLeadFetched = sourceLead.isEmpty;
        emit(SourceLeadLoaded(sourceLead)); 
      } catch (e) {
        print('Ошибка при загрузке источников: $e'); // For debugging
        emit(SourceLeadError('Не удалось загрузить список Источников: ${e.toString()}'));
      }
    } else {
      emit(SourceLeadError('Нет подключения к интернету'));
    }
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      return false;
    }
  }
}
