import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/user_model.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserTaskBloc extends Bloc<UserTaskEvent, UserTaskState> {
  final ApiService apiService;

  UserTaskBloc(this.apiService) : super(UserTaskInitial()) {
    on<FetchUsers>((event, emit) async {
      emit(UserTaskLoading());
      try {
        final user = await apiService.getUserTask();
        emit(UserTaskLoaded(user.cast<UserTask>()));  
      } catch (e) {
        emit(UserTaskError('Ошибка при загрузке Менеджеров'));
      }
    });
  }
}
