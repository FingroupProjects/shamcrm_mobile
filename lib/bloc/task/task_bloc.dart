import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final ApiService apiService;
  bool allTasksFetched = false;
  Map<int, int> _taskCounts = {}; // Добавляем приватное поле для хранения количества

 
  TaskBloc(this.apiService) : super(TaskInitial()) {
    on<FetchTaskStatuses>(_fetchTaskStatuses);
    on<FetchTasks>(_fetchTasks);
    on<CreateTask>(_createTask);
    on<FetchMoreTasks>(_fetchMoreTasks);
    on<UpdateTask>(_updateTask);
    on<DeleteTask>(_deleteTask);
    on<DeleteTaskStatuses>(_deleteTaskStatuses);
  }

  Future<void> _fetchTaskStatuses(
      FetchTaskStatuses event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    
    await Future.delayed(Duration(milliseconds: 600));
    
    if (!await _checkInternetConnection()) {
      emit(TaskError('Нет подключения к интернету'));
      return;
    }

    try {
      final response = await apiService.getTaskStatuses();
      if (response.isEmpty) {
        emit(TaskError('Нет статусов задачи!'));
        return;
      }

      // Загружаем количество задач для каждого статуса
      for (var status in response) {
        try {
          final tasks = await apiService.getTasks(
            status.id,
            page: 1,
            perPage: 20, // Увеличиваем количество для получения всех задач
          );
          _taskCounts[status.id] = tasks.length;
        } catch (e) {
          print('Error fetching task count for status ${status.id}: $e');
          _taskCounts[status.id] = 0;
        }
      }

      emit(TaskLoaded(response, taskCounts: Map.from(_taskCounts)));
    } catch (e) {
      emit(TaskError('Не удалось загрузить данные!'));
    }
  }

  Future<void> _fetchTasks(FetchTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    
    if (!await _checkInternetConnection()) {
      emit(TaskError('Нет подключения к интернету'));
      return;
    }

    try {
      // Сначала получаем все задачи для подсчета
      final allTasks = await apiService.getTasks(
        event.statusId,
        page: 1,
        perPage: 20, // Увеличиваем для получения всех задач
        search: event.query,
      );
      
      // Сохраняем общее количество
      _taskCounts[event.statusId] = allTasks.length;
      
      // Теперь получаем только нужную страницу для отображения
      final pageTasks = await apiService.getTasks(
        event.statusId,
        page: 1,
        perPage: 20,
        search: event.query,
      );
      
      allTasksFetched = pageTasks.isEmpty;
      
      if (state is TaskLoaded) {
        final loadedState = state as TaskLoaded;
        emit(loadedState.copyWith(taskCounts: Map.from(_taskCounts)));
      }
      
      emit(TaskDataLoaded(pageTasks, currentPage: 1));
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
      emit(TaskError(
          'Не удалось загрузить дополнительные задачи!'));
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
