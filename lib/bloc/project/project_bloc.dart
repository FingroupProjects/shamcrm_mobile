import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ApiService apiService;
  
  ProjectBloc(this.apiService) : super(ProjectInitial()) {
    on<FetchProjects>((event, emit) async {
      emit(ProjectLoading());
      try {
        final projects = await apiService.getProject();
        emit(ProjectLoaded(projects));
      } catch (e) {
        emit(ProjectError('Ошибка при загрузке Проектов'));
      }
    });
  }
}
