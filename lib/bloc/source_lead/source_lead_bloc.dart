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

    try {
      final sourceLead = await apiService.getSourceLead(); 
      allSourceLeadFetched = sourceLead.isEmpty;
      emit(SourceLeadLoaded(sourceLead)); 
    } catch (e) {
      emit(SourceLeadError('Не удалось загрузить список Источников: ${e.toString()}'));
    }
  }

}


