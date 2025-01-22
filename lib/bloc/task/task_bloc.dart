import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final ApiService apiService;
  bool allTasksFetched = false;
  Map<int, int> _taskCounts =
      {}; // Добавляем приватное поле для хранения количества

  TaskBloc(this.apiService) : super(TaskInitial()) {
    on<FetchTaskStatuses>(_fetchTaskStatuses);
    on<FetchTasks>(_fetchTasks);
    on<CreateTask>(_createTask);
    on<FetchMoreTasks>(_fetchMoreTasks);
    on<UpdateTask>(_updateTask);
    on<DeleteTask>(_deleteTask);
    on<DeleteTaskStatuses>(_deleteTaskStatuses);
  }
// Метод для загрузки статусов задач с учётом кэша
Future<void> _fetchTaskStatuses(FetchTaskStatuses event, Emitter<TaskState> emit) async {
  emit(TaskLoading());

  // Проверка интернета
  if (!await _checkInternetConnection()) {
    // Если интернета нет, пробуем загрузить статусы задач из кэша
    final cachedStatuses = await TaskCache.getTaskStatuses();
    if (cachedStatuses.isNotEmpty) {
      emit(TaskLoaded(
        cachedStatuses.map((status) => TaskStatus.fromJson(status)).toList(),
        taskCounts: Map.from(_taskCounts),
      ));
    } else {
      emit(TaskError('Нет подключения к интернету и нет данных в кэше!'));
    }
    return;
  }

  try {
    // Сначала пробуем загрузить статусы задач из кэша
    final cachedStatuses = await TaskCache.getTaskStatuses();
    if (cachedStatuses.isNotEmpty) {
      emit(TaskLoaded(
        cachedStatuses.map((status) => TaskStatus.fromJson(status)).toList(),
        taskCounts: Map.from(_taskCounts),
      ));
    }

    // Затем запрашиваем данные из API
    final response = await apiService.getTaskStatuses();
    if (response.isEmpty) {
      emit(TaskError('Нет статусов задачи!'));
      return;
    }

    // Сохраняем статусы задач в кэш
    await TaskCache.cacheTaskStatuses(
        response.map((status) => {'id': status.id, 'title': status.taskStatus!.name ?? ""}).toList());

    // Параллельно загружаем количество задач для каждого статуса
    final futures = response.map((status) {
      return apiService.getTasks(status.id, page: 1, perPage: 1);  // Загружаем только количество задач
    }).toList();

    final taskCountsResults = await Future.wait(futures);

    // Обновляем количество задач
    for (int i = 0; i < response.length; i++) {
      _taskCounts[response[i].id] = taskCountsResults[i].length;
    }

    emit(TaskLoaded(response, taskCounts: Map.from(_taskCounts)));
  } catch (e) {
    emit(TaskError('Не удалось загрузить данные!'));
  }
}

// Метод для загрузки задач с учётом кэша
Future<void> _fetchTasks(FetchTasks event, Emitter<TaskState> emit) async {
  emit(TaskLoading());

  // Проверка интернет-соединения
  if (!await _checkInternetConnection()) {
    // Если интернета нет, пробуем загрузить задачи из кэша
    final cachedTasks = await TaskCache.getTasksForStatus(event.statusId);
    if (cachedTasks.isNotEmpty) {
      emit(TaskDataLoaded(cachedTasks, currentPage: 1, taskCounts: {}));
    } else {
      emit(TaskError('Нет подключения к интернету и нет данных в кэше!'));
    }
    return;
  }

  try {
    // Сначала пробуем загрузить задачи из кэша
    final cachedTasks = await TaskCache.getTasksForStatus(event.statusId);
    if (cachedTasks.isNotEmpty) {
      emit(TaskDataLoaded(cachedTasks, currentPage: 1, taskCounts: {}));
    }

    // Затем запрашиваем данные из API
    final tasks = await apiService.getTasks(
      event.statusId,
      page: 1,
      perPage: 20,
      search: event.query,
      users: event.userIds,
    );

    // Сохраняем задачи в кэш
    await TaskCache.cacheTasksForStatus(event.statusId, tasks);

    // Обновляем количество задач
    _taskCounts[event.statusId] = tasks.length;

    allTasksFetched = tasks.isEmpty;

    emit(TaskDataLoaded(tasks, currentPage: 1, taskCounts: Map.from(_taskCounts)));
  } catch (e) {
    if (e is ApiException && e.statusCode == 401) {
      emit(TaskError('Неавторизованный доступ!'));
    } else {
      emit(TaskError('Не удалось загрузить данные!'));
    }
  }
}



  Future<void> _fetchMoreTasks(
      FetchMoreTasks event, Emitter<TaskState> emit) async {
    if (allTasksFetched) return;

    if (!await _checkInternetConnection()) {
      emit(TaskError('Нет подключения к интернету'));
      return;
    }

    try {
      final tasks = await apiService.getTasks(event.statusId,
          page: event.currentPage + 1);
      if (tasks.isEmpty) {
        allTasksFetched = true;
        return;
      }
      if (state is TaskDataLoaded) {
        final currentState = state as TaskDataLoaded;
        emit(currentState.merge(tasks));
      }
    } catch (e) {
      emit(TaskError('Не удалось загрузить дополнительные задачи!'));
    }
  }

  Future<void> _createTask(CreateTask event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    if (!await _checkInternetConnection()) {
      emit(TaskError('Нет подключения к интернету'));
      return;
    }

    try {
      final result = await apiService.createTask(
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
        filePath: event.filePath,
      );

      if (result['success']) {
        emit(TaskSuccess('Задача успешно создана!'));
        // add(FetchTasks(event.statusId));
      } else {
        emit(TaskError(result['message']));
      }
    } catch (e) {
      emit(TaskError('Ошибка создания задачи!'));
    }
  }

  Future<void> _updateTask(UpdateTask event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    if (!await _checkInternetConnection()) {
      emit(TaskError('Нет подключения к интернету'));
      return;
    }

    try {
      final result = await apiService.updateTask(
        taskId: event.taskId,
        name: event.name,
        statusId: event.statusId,
        priority: event.priority,
        startDate: event.startDate,
        endDate: event.endDate,
        projectId: event.projectId,
        userId: event.userId,
        description: event.description,
        taskStatusId: event.taskStatusId,
        customFields: event.customFields,
        filePath: event.filePath,
      );

      if (result['success']) {
        emit(TaskSuccess('Задача успешно обновлена!'));
        // add(FetchTasks(event.statusId));
      } else {
        emit(TaskError(result['message']));
      }
    } catch (e) {
      emit(TaskError('Ошибка обновления задачи!'));
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

  Future<void> _deleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    try {
      final response = await apiService.deleteTask(event.taskId);
      if (response['result'] == 'Success') {
        emit(TaskDeleted('Задача успешно удалена!'));
      } else {
        emit(TaskError('Ошибка удаления задача'));
      }
    } catch (e) {
      emit(TaskError('Ошибка удаления задача!'));
    }
  }

  Future<void> _deleteTaskStatuses(
      DeleteTaskStatuses event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    try {
      final response = await apiService.deleteTaskStatuses(event.taskStatusId);
      if (response['result'] == 'Success') {
        emit(TaskDeleted('Статус задачи успешно удалена!'));
      } else {
        emit(TaskError('Ошибка удаления статуса задачи'));
      }
    } catch (e) {
      emit(TaskError('Ошибка удаления статуса сделки!'));
    }
  }
}


