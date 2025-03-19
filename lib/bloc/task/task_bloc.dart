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
  Map<int, int> _taskCounts = {};
  String? _currentQuery;
  List<int>? _currentUserIds;
  int? _currentStatusIds;
  DateTime? _currentFromDate;
  DateTime? _currentToDate;
  bool? _currentOverdue;
  bool? _currentHasFile;
  bool? _currentHasDeal;
  bool? _currentUrgent;
  String? _currentProject;
  List<String>? _currentAuthors;
  DateTime? _currentDeadlineFromDate;
  DateTime? _currentDeadlineToDate;
  String? _currentDepartment;

  TaskBloc(this.apiService) : super(TaskInitial()) {
    on<FetchTaskStatuses>(_fetchTaskStatuses);
    on<FetchTasks>(_fetchTasks);
    on<CreateTask>(_createTask);
    on<FetchMoreTasks>(_fetchMoreTasks);
    on<UpdateTask>(_updateTask);
    on<DeleteTask>(_deleteTask);
    on<DeleteTaskStatuses>(_deleteTaskStatuses);
    on<FetchTaskStatus>(_fetchTaskStatus);
    on<UpdateTaskStatusEdit>(_updateTaskStatusEdit);
  }

  Future<void> _fetchTaskStatus(
      FetchTaskStatus event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final taskStatus = await apiService.getTaskStatus(event.taskStatusId);
      emit(TaskStatusLoaded(taskStatus));
    } catch (e) {
      emit(TaskError('Failed to fetch deal status: ${e.toString()}'));
    }
  }

// Метод для загрузки статусов задач с учётом кэша
  Future<void> _fetchTaskStatuses(FetchTaskStatuses event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    if (!await _checkInternetConnection()) {
      final cachedStatuses = await TaskCache.getTaskStatuses();
      if (cachedStatuses.isNotEmpty) {
        emit(TaskLoaded(cachedStatuses.map((status) => TaskStatus.fromJson(status)).toList(),
        taskCounts: Map.from(_taskCounts) 
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
        emit(TaskLoaded( cachedStatuses.map((status) => TaskStatus.fromJson(status)).toList(),
        taskCounts: Map.from(_taskCounts) 
        ));
      }

      // Затем запрашиваем данные из API
      final response = await apiService.getTaskStatuses();
      if (response.isEmpty) {
        emit(TaskError('Нет статусов задачи!'));
        return;
      }

      // Сохраняем статусы задач в кэш
      await TaskCache.cacheTaskStatuses(response.map((status) => {'id': status.id, 'title': status.taskStatus!.name ?? ""}).toList());

      // Параллельно загружаем количество задач для каждого статуса
      final futures = response.map((status) { return apiService.getTasks(status.id, page: 1, perPage: 1); 
      }).toList();

      final taskCountsResults = await Future.wait(futures);

      // Update lead counts
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

  _currentQuery = event.query;
  _currentUserIds = event.userIds;
  _currentStatusIds = event.statusIds;
  _currentFromDate = event.fromDate;
  _currentToDate = event.toDate;
  _currentOverdue = event.overdue;
  _currentHasFile = event.hasFile;
  _currentHasDeal = event.hasDeal;
  _currentUrgent = event.urgent;
  _currentProject = event.project;
  _currentAuthors = event.authors;
  _currentDeadlineFromDate = event.deadlinefromDate;
  _currentDeadlineToDate = event.deadlinetoDate;
  _currentDepartment = event.department;

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
      statuses: event.statusIds,
      fromDate: event.fromDate,
      toDate: event.toDate,
      overdue: event.overdue,
      hasFile: event.hasFile,
      hasDeal: event.hasDeal,
      urgent: event.urgent,
      project: event.project,
      authors: event.authors,
      deadlinefromDate: event.deadlinefromDate,
      deadlinetoDate: event.deadlinetoDate,
      department: event.department, 
    );

    // Сохраняем задачи в кэш
    await TaskCache.cacheTasksForStatus(event.statusId, tasks);
    _taskCounts[event.statusId] = tasks.length;
    
    // Обновляем состояние
    final taskCounts = Map<int, int>.from(_taskCounts);
    for (var task in tasks) {
      taskCounts[task.statusId] = (taskCounts[task.statusId] ?? 0) + 1;
    }
    allTasksFetched = tasks.isEmpty;

    emit(TaskDataLoaded(tasks, currentPage: 1, taskCounts: taskCounts));
  } catch (e) {
    if (e is ApiException && e.statusCode == 401) {
      emit(TaskError('Неавторизованный доступ!'));
    } else {
      emit(TaskError('Не удалось загрузить данные!'));
    }
  }
}
  
Future<void> _fetchMoreTasks(FetchMoreTasks event, Emitter<TaskState> emit) async {
  if (allTasksFetched) return;

  if (!await _checkInternetConnection()) {
    emit(TaskError('Нет подключения к интернету'));
    return;
  }

  try {
    final tasks = await apiService.getTasks(
      event.statusId,
      page: event.currentPage + 1,
      perPage: 20,
      search: _currentQuery,
      users: _currentUserIds,
      statuses: _currentStatusIds,
      fromDate: _currentFromDate,
      toDate: _currentToDate,
      overdue: _currentOverdue,
      hasFile: _currentHasFile,
      hasDeal: _currentHasDeal,
      urgent: _currentUrgent,
      project: _currentProject,
      authors: _currentAuthors,
      deadlinefromDate: _currentDeadlineFromDate,
      deadlinetoDate: _currentDeadlineToDate,
      department: _currentDepartment,
    );

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
      emit(TaskError(event.localizations.translate('no_internet_connection')));
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
        filePaths: event.filePaths,
      );

      if (result['success']) {
        emit(TaskSuccess(
            event.localizations.translate('task_create_successfully')));
      } else {
        emit(TaskError(result['message']));
      }
    } catch (e) {
      emit(TaskError(event.localizations.translate('task_creation_error')));
    }
  }

  Future<void> _updateTask(UpdateTask event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    if (!await _checkInternetConnection()) {
      emit(TaskError(event.localizations.translate('no_internet_connection')));
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
        filePaths: event.filePaths,
      );

      if (result['success']) {
        emit(TaskSuccess(
            event.localizations!.translate('task_update_successfully')));
        // add(FetchTasks(event.statusId));
      } else {
        emit(TaskError(result['message']));
      }
    } catch (e) {
      emit(TaskError(
          event.localizations.translate('error_task_update_successfully')));
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
        emit(TaskDeleted(
            event.localizations.translate('task_deleted_successfully')));
      } else {
        emit(TaskError(event.localizations.translate('error_delete_task')));
      }
    } catch (e) {
      emit(TaskError(event.localizations.translate('error_delete_task')));
    }
  }

  Future<void> _deleteTaskStatuses(
      DeleteTaskStatuses event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    try {
      final response = await apiService.deleteTaskStatuses(event.taskStatusId);
      if (response['result'] == 'Success') {
        emit(TaskDeleted(
            event.localizations.translate('task_create_successfully')));
      } else {
        emit(TaskError(
            event.localizations.translate('error_delete_task_status')));
      }
    } catch (e) {
      emit(
          TaskError(event.localizations.translate('error_delete_task_status')));
    }
  }

Future<void> _updateTaskStatusEdit(
    UpdateTaskStatusEdit event, Emitter<TaskState> emit) async {
  emit(TaskLoading());

  try {
    final response = await apiService.updateTaskStatusEdit(
      taskStatusId: event.taskStatusId,
      name: event.name,
      needsPermission: event.needsPermission,
      finalStep: event.finalStep,
      checkingStep: event.checkingStep,
      roleIds: event.roleIds,
    );

    if (response['result'] == 'Success') {
      emit(TaskStatusUpdatedEdit(
          event.localizations.translate('status_updated_successfully')));
    } else {
      emit(TaskError(event.localizations.translate('error_update_status')));
    }
  } catch (e) {
    emit(TaskError(event.localizations.translate('error_update_status')));
  }
}
}