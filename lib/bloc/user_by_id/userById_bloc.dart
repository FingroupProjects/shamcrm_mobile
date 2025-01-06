import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/user_by_id/userById_event.dart';
import 'package:crm_task_manager/bloc/user_by_id/userById_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class UserByIdBloc extends Bloc<UserByIdEvent, UserByIdState> {
  final ApiService apiService;

  UserByIdBloc(this.apiService) : super(UserByIdInitial()) {
    on<FetchUserByIdEvent>(_getUserById);
  }

  Future<void> _getUserById(FetchUserByIdEvent event, Emitter<UserByIdState> emit) async {
    emit(UserByIdLoading());

    try {
      final user = await apiService.getUserById(event.userId);
      emit(UserByIdLoaded(user));
    } catch (e) {
      emit(UserByIdError('Не удалось загрузить данные пользователя!'));
    }
  }
}