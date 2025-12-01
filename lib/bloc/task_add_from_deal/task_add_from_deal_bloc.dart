import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_event.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_state.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskAddFromDealBloc extends Bloc<TaskAddFromDealEvent, TaskAddFromDealState> {
  final ApiService apiService;

  TaskAddFromDealBloc({required this.apiService}) : super(const TaskAddFromDealInitial()) {
    on<CreateTaskFromDeal>(_createTaskFromDeal);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _createTaskFromDeal(
    CreateTaskFromDeal event,
    Emitter<TaskAddFromDealState> emit,
  ) async {
    emit(const TaskAddFromDealLoading());
    if (!await _checkInternetConnection()) {
      emit(TaskAddFromDealError(AppLocalizations.of(navigatorKey.currentContext!)!
          .translate('no_internet_connection')));
      return;
    }
    try {
      final result = await apiService.createTaskFromDeal(
        dealId: event.dealId,
        name: event.name,
        statusId: event.statusId,
        taskStatusId: event.taskStatusId,
        priority: event.priority,
        startDate: event.startDate,
        endDate: event.endDate,
        projectId: event.projectId,
        userId: event.userId,
        description: event.description,
        customFields: event.customFields,
        filePaths: event.filePaths,
        directoryValues: event.directoryValues,
      );
      if (result['success']) {
        emit(TaskAddFromDealSuccess(
            result['message'] ?? AppLocalizations.of(navigatorKey.currentContext!)!.translate('task_deal_create_successfully')));
      } else {
        emit(TaskAddFromDealError(
            result['message'] ?? AppLocalizations.of(navigatorKey.currentContext!)!.translate('error_create_task')));
      }
    } catch (e) {
      emit(TaskAddFromDealError(AppLocalizations.of(navigatorKey.currentContext!)!.translate('error_create_task')));
    }
  }
}