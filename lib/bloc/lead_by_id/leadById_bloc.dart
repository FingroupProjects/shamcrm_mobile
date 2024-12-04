import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_event.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadByIdBloc extends Bloc<LeadByIdEvent, LeadByIdState> {
  final ApiService apiService;

  LeadByIdBloc(this.apiService) : super(LeadByIdInitial()) {
    on<FetchLeadByIdEvent>(_getLeadById);
  }

Future<void> _getLeadById(FetchLeadByIdEvent event, Emitter<LeadByIdState> emit) async {
  emit(LeadByIdLoading());

  try {
    final lead = await apiService.getLeadById(event.leadId);
    emit(LeadByIdLoaded(lead));
  } catch (e) {
    emit(LeadByIdError('Не удалось загрузить данные лида: ${e.toString()}'));
  }
}

}
