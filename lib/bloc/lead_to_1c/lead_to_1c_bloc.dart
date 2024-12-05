import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_event.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadToCBloc extends Bloc<LeadToCEvent, LeadToCState> {
  final ApiService apiService; // Replace with your API service class

  LeadToCBloc({required this.apiService}) : super(LeadToCInitial()) {
    on<FetchLeadToC>(_onFetchLeadToC);
  }

  Future<void> _onFetchLeadToC(FetchLeadToC event, Emitter<LeadToCState> emit) async {
    emit(LeadToCLoading());
    try {
      final leadData = await apiService.postLeadToC(event.leadId);
      emit(LeadToCLoaded(leadData));
    } catch (e) {
      emit(LeadToCError(e.toString()));
    }
  }
}