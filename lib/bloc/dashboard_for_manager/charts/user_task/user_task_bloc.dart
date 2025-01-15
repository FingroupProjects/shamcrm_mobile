// Bloc
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/user_task/user_task_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/user_task/user_task_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserBlocManager extends Bloc<UserEvent, UserState> {
  final ApiService apiService;

  UserBlocManager(this.apiService) : super(UserInitial()) {
    on<LoadUserData>(_onLoadUserData);
  }

  Future<void> _onLoadUserData(
    LoadUserData event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(UserLoading());

      final data = await apiService.getUserStatsManager();
      emit(UserLoaded(data: data.finishedTasksPercent));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }
}