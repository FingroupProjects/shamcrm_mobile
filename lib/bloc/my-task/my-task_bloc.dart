import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/screens/my-task/my_task_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyTaskBloc extends Bloc<MyTaskEvent, MyTaskState> {
  final ApiService apiService;
  bool allMyTasksFetched = false;
  Map<int, int> _taskCounts =
      {}; // Добавляем приватное поле для хранения количества

  MyTaskBloc(this.apiService) : super(MyTaskInitial()) {
    on<FetchMyTaskStatuses>(_fetchMyTaskStatuses);
    on<FetchMyTasks>(_fetchMyTasks);
    on<CreateMyTask>(_createMyTask);
    on<FetchMoreMyTasks>(_fetchMoreMyTasks);
    on<UpdateMyTask>(_updateMyTask);
    on<DeleteMyTask>(_deleteMyTask);
    on<DeleteMyTaskStatuses>(_deleteMyTaskStatuses);
    on<UpdateMyTaskStatusEdit>(_updateMyTaskStatusEdit);
    on<FetchMyTaskStatus>(_fetchMyTaskStatus);
  }
  Future<void> _fetchMyTaskStatus(FetchMyTaskStatus event, Emitter<MyTaskState> emit) async {
    emit(MyTaskLoading());
    try {
      final myTaskStatus = await apiService.getMyTaskStatus(event.myTaskStatusId);
      emit(MyTaskStatusLoaded(myTaskStatus));
    } catch (e) {
      emit(MyTaskError('Failed to fetch deal status: ${e.toString()}'));
    }
  }
  
  Future<void> _updateMyTaskStatusEdit(
    UpdateMyTaskStatusEdit event, Emitter<MyTaskState> emit) async {
  emit(MyTaskLoading());

  try {
    final response = await apiService.updateMyTaskStatusEdit(
      event.myTaskStatusId,
      event.title,
      event.finalStep,  // Добавляем передачу finalStep
      event.localizations,
    );

    if (response['result'] == 'Success') {
      emit(MyTaskStatusUpdatedEdit(
          event.localizations.translate('status_updated_successfully')));
    } else {
      emit(MyTaskError(event.localizations.translate('error_update_status')));
    }
  } catch (e) {
    emit(MyTaskError(event.localizations.translate('error_update_status')));
  }
}

// Метод для загрузки статусов задач с учётом кэша
  Future<void> _fetchMyTaskStatuses(
      FetchMyTaskStatuses event, Emitter<MyTaskState> emit) async {
    emit(MyTaskLoading());

    // Проверка интернета
    if (!await _checkInternetConnection()) {
      // Если интернета нет, пробуем загрузить статусы задач из кэша
      final cachedStatuses = await MyTaskCache.getMyTaskStatuses();
      if (cachedStatuses.isNotEmpty) {
        emit(MyTaskLoaded(
          cachedStatuses
              .map((status) => MyTaskStatus.fromJson(status))
              .toList(),
          taskCounts: Map.from(_taskCounts),
        ));
      } else {
        emit(MyTaskError('Нет подключения к интернету и нет данных в кэше!'));
      }
      return;
    }

    try {
      // Сначала пробуем загрузить статусы задач из кэша
      final cachedStatuses = await MyTaskCache.getMyTaskStatuses();
      if (cachedStatuses.isNotEmpty) {
        emit(MyTaskLoaded(
          cachedStatuses
              .map((status) => MyTaskStatus.fromJson(status))
              .toList(),
          taskCounts: Map.from(_taskCounts),
        ));
      }

      // Затем запрашиваем данные из API
      final response = await apiService.getMyTaskStatuses();
      if (response.isEmpty) {
        emit(MyTaskError('Нет статусов задачи!'));
        return;
      }

      // Сохраняем статусы задач в кэш
      await MyTaskCache.cacheMyTaskStatuses(response
          .map((status) => {'id': status.id, 'title': status.title ?? ""})
          .toList());

      // Параллельно загружаем количество задач для каждого статуса
      final futures = response.map((status) {
        return apiService.getMyTasks(status.id,
            page: 1, perPage: 1); // Загружаем только количество задач
      }).toList();

      final taskCountsResults = await Future.wait(futures);

      // Обновляем количество задач
      for (int i = 0; i < response.length; i++) {
        _taskCounts[response[i].id] = taskCountsResults[i].length;
      }

      emit(MyTaskLoaded(response, taskCounts: Map.from(_taskCounts)));
    } catch (e) {
      emit(MyTaskError('Не удалось загрузить данные!'));
    }
  }

// Метод для загрузки задач с учётом кэша
  Future<void> _fetchMyTasks(
      FetchMyTasks event, Emitter<MyTaskState> emit) async {
    emit(MyTaskLoading());

    // Проверка интернет-соединения
    if (!await _checkInternetConnection()) {
      // Если интернета нет, пробуем загрузить задачи из кэша
      final cachedMyTasks =
          await MyTaskCache.getMyTasksForStatus(event.statusId);
      if (cachedMyTasks.isNotEmpty) {
        emit(MyTaskDataLoaded(cachedMyTasks, currentPage: 1, taskCounts: {}));
      } else {
        emit(MyTaskError('Нет подключения к интернету и нет данных в кэше!'));
      }
      return;
    }

    try {
      // Сначала пробуем загрузить задачи из кэша
      final cachedMyTasks =
          await MyTaskCache.getMyTasksForStatus(event.statusId);
      if (cachedMyTasks.isNotEmpty) {
        emit(MyTaskDataLoaded(cachedMyTasks, currentPage: 1, taskCounts: {}));
      }

      // Затем запрашиваем данные из API
      final tasks = await apiService.getMyTasks(
        event.statusId,
        page: 1,
        perPage: 20,
        search: event.query,
      );

      // Сохраняем задачи в кэш
      await MyTaskCache.cacheMyTasksForStatus(event.statusId, tasks);

      // Обновляем количество задач
      _taskCounts[event.statusId] = tasks.length;

      allMyTasksFetched = tasks.isEmpty;

      emit(MyTaskDataLoaded(tasks,
          currentPage: 1, taskCounts: Map.from(_taskCounts)));
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        emit(MyTaskError('Неавторизованный доступ!'));
      } else {
        emit(MyTaskError('Не удалось загрузить данные!'));
      }
    }
  }

  Future<void> _fetchMoreMyTasks(
      FetchMoreMyTasks event, Emitter<MyTaskState> emit) async {
    if (allMyTasksFetched) return;

    if (!await _checkInternetConnection()) {
      emit(MyTaskError('Нет подключения к интернету'));
      return;
    }

    try {
      final tasks = await apiService.getMyTasks(event.statusId,
          page: event.currentPage + 1);
      if (tasks.isEmpty) {
        allMyTasksFetched = true;
        return;
      }
      if (state is MyTaskDataLoaded) {
        final currentState = state as MyTaskDataLoaded;
        emit(currentState.merge(tasks));
      }
    } catch (e) {
      emit(MyTaskError('Не удалось загрузить дополнительные задачи!'));
    }
  }

  Future<void> _createMyTask(
      CreateMyTask event, Emitter<MyTaskState> emit) async {
    emit(MyTaskLoading());

    if (!await _checkInternetConnection()) {
      emit(MyTaskError(event.localizations.translate('no_internet_connection')));
      return;
    }

    try {
      final result = await apiService.createMyTask(
        name: event.name,
        statusId: event.statusId,
        taskStatusId: event.taskStatusId,
        startDate: event.startDate,
        endDate: event.endDate,
        description: event.description,
        filePaths: event.filePaths,
        setPush: event.setPush,
      );

      if (result['success']) {
        emit(MyTaskSuccess(event.localizations.translate('task_create_successfully')));
        // add(FetchMyTasks(event.statusId));
      } else {
        emit(MyTaskError(result['message']));
      }
    } catch (e) {
      emit(MyTaskError(event.localizations.translate('task_creation_error')));
    }
  }
/* Future<void> _createMyTask(
      CreateMyTask event, Emitter<MyTaskState> emit) async {
    emit(MyTaskLoading());

    if (!await _checkInternetConnection()) {
      emit(MyTaskError(event.localizations.translate('no_internet_connection')));
      return;
    }

    try {
      final result = await apiService.createMyTask(
        name: event.name,
        statusId: event.statusId,
        taskStatusId: event.taskStatusId,
        startDate: event.startDate,
        endDate: event.endDate,
        description: event.description,
        filePaths: event.filePaths,
        setPush: event.setPush,
      );

      if (result['success']) {
        emit(MyTaskSuccess(event.localizations.translate('task_create_successfully')));
        // add(FetchMyTasks(event.statusId));
      } else {
        emit(MyTaskError(result['message']));
      }
    } catch (e) {
      emit(MyTaskError(event.localizations.translate('task_creation_error')));
    }
  }*/
  Future<void> _updateMyTask(
      UpdateMyTask event, Emitter<MyTaskState> emit) async {
    emit(MyTaskLoading());

    if (!await _checkInternetConnection()) {
      emit(MyTaskError(event.localizations.translate('no_internet_connection')));
      return;
    }

    try {
      final result = await apiService.updateMyTask(
        taskId: event.taskId,
        name: event.name,
        // startDate: event.startDate,
        endDate: event.endDate,
        description: event.description,
        taskStatusId: event.taskStatusId,
        filePaths: event.filePaths,
        setPush: event.setPush,
      );

      if (result['success']) {
        emit(MyTaskSuccess(event.localizations.translate('task_update_successfully')));
        // add(FetchMyTasks(event.statusId));
      } else {
        emit(MyTaskError(result['message']));
      }
    } catch (e) {
      emit(MyTaskError(event.localizations.translate('error_task_update_successfully')));
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _deleteMyTask(
      DeleteMyTask event, Emitter<MyTaskState> emit) async {
    emit(MyTaskLoading());

    try {
      final response = await apiService.deleteMyTask(event.taskId);
      if (response['result'] == 'Success') {
        emit(MyTaskDeleted(event.localizations.translate('task_deleted_successfully')));
      } else {
        emit(MyTaskError(event.localizations.translate('error_delete_task')));
      }
    } catch (e) {
      emit(MyTaskError(event.localizations.translate('error_delete_task')));
    }
  }

  Future<void> _deleteMyTaskStatuses(
      DeleteMyTaskStatuses event, Emitter<MyTaskState> emit) async {
    emit(MyTaskLoading());

    try {
      final response =
          await apiService.deleteMyTaskStatuses(event.taskStatusId);
      if (response['result'] == 'Success') {
        emit(MyTaskDeleted(event.localizations.translate('task_create_successfully')));
      } else {
        emit(MyTaskError(event.localizations.translate('error_delete_task_status')));
      }
    } catch (e) {
      emit(MyTaskError(event.localizations.translate('error_delete_task_status')));
    }
  }
}
