
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_event.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SourceLeadBloc extends Bloc<SourceLeadEvent, SourceLeadState> {
  final ApiService apiService;
  
  SourceLeadBloc(this.apiService) : super(SourceLeadInitial() as SourceLeadState) {
    on<FetchSourceLead>((event, emit) async {
      emit(SourceLeadLoading() as SourceLeadState);
      try {
        final sourceLead = await apiService.getSourceLead();
        print('Полученные статусы в блоке: $sourceLead');

        emit(SourceLeadLoaded(sourceLead));
      } catch (e) {
        emit(SourceLeadError('Ошибка при загрузке Имя Статусов'));
      }
    });
  }
}

