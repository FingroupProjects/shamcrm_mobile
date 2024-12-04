import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/project/project_event.dart';
import 'package:crm_task_manager/bloc/project/project_state.dart';

class GetAllProjectBloc extends Bloc<GetAllProjectEvent, GetAllProjectState> {
  GetAllProjectBloc() : super(GetAllProjectInitial()) {
    on<GetAllProjectEv>(_getProjects);
  }

  Future<void> _getProjects(GetAllProjectEv event, Emitter<GetAllProjectState> emit) async {
    try {
      emit(GetAllProjectLoading());

      var res = await ApiService().getAllProject();

      emit(GetAllProjectSuccess(dataProject: res));
    } catch (e) {
      emit(GetAllProjectError(message: e.toString()));
    }
  }
}
