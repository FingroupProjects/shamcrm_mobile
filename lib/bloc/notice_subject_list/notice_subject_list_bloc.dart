import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_event.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetAllSubjectBloc extends Bloc<GetAllSubjectEvent, GetAllSubjectState> {
  GetAllSubjectBloc() : super(GetAllSubjectInitial()) {
    on<GetAllSubjectEv>(_getSubjects);
  }

  Future<void> _getSubjects(
    GetAllSubjectEv event,
    Emitter<GetAllSubjectState> emit,
  ) async {
    try {
      emit(GetAllSubjectLoading());
      final res = await ApiService().getAllSubjects();
      emit(GetAllSubjectSuccess(dataSubject: res));
    } catch (e) {
      emit(GetAllSubjectError(message: e.toString()));
    }
  }
}