import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_overdue_task_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_overdue_task_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserOverdueTaskBloc extends Bloc<UserOverdueTaskEvent, UserOverdueTaskState> {
  final ApiService apiService;

  UserOverdueTaskBloc(this.apiService) : super(UserOverdueTaskInitial()) {
    on<LoadUserOverdueTaskData>(_onLoadUserOverdueTaskData);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _onLoadUserOverdueTaskData(
      LoadUserOverdueTaskData event,
      Emitter<UserOverdueTaskState> emit,
      ) async {
    try {
      // Only show loading on initial load (not when paginating)
      if (state is! UserOverdueTaskLoaded) {
        emit(UserOverdueTaskLoading());
      }

      final data = await apiService.getUsersOverdueTaskData(
        userId: event.id,
      );

      emit(UserOverdueTaskLoaded(data: data));
    } catch (e) {
      emit(UserOverdueTaskError(message: e.toString()));
    }
  }
}