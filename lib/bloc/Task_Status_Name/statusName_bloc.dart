
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_event.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskStatusNameBloc extends Bloc<StatusNameEvent, StatusNameState> {
  final ApiService apiService;
  
  TaskStatusNameBloc(this.apiService) : super(StatusNameInitial() as StatusNameState) {
    on<FetchStatusNames>((event, emit) async {
      emit(StatusNameLoading() as StatusNameState);
      try {
        final statuses = await apiService.getStatusName();
        print('Полученные статусы в блоке: $statuses');

        emit(StatusNameLoaded(statuses));
      } catch (e) {
        emit(StatusNameError('Ошибка при загрузке Имя Статусов'));
      }
    });
  }
}
