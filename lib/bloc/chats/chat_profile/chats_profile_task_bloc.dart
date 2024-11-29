import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_event.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class TaskProfileBloc extends Bloc<TaskProfileEvent, TaskProfileState> {
  final ApiService apiService;

  TaskProfileBloc(this.apiService) : super(TaskProfileInitial()) {
    on<FetchTaskProfile>((event, emit) async {
      emit(TaskProfileLoading());
      try {
        final profile = await apiService.getTaskProfile(event.chatId);
        emit(TaskProfileLoaded(profile));
      } catch (e) {
        if (e.toString() == 'Exception: Данные задачи не найдены') {
          emit(TaskProfileError('Данные задачи не найдены'));
        } else {
          emit(TaskProfileError('Ошибка загрузки задачи: $e'));
        }
      }
    });
  }
}
