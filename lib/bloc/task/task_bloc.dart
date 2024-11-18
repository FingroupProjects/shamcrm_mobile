import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final ApiService apiService;
  bool allTasksFetched = false;

  TaskBloc(this.apiService) : super(TaskInitial()) {
    on<FetchTaskStatuses>(_fetchTaskStatuses);
    on<FetchTasks>(_fetchTasks);
    on<CreateTask>(_createTask);
    on<FetchMoreTasks>(_fetchMoreTasks);
    on<CreateTaskStatus>(_createTaskStatus);
    on<UpdateTask>(_updateTask);
    on<DeleteTask>(_deleteTask);

    on<DeleteTaskStatuses>(_deleteTaskStatuses);

  }

  Future<void> _fetchTaskStatuses(
      FetchTaskStatuses event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    await Future.delayed(Duration(milliseconds: 500));

    if (!await _checkInternetConnection()) {
      emit(TaskError('Нет подключения к интернету'));
      return;
    }

    try {
      final response = await apiService.getTaskStatuses();
      if (response.isEmpty) {
        emit(TaskError('Ответ пустой'));
        return;
      }
      emit(TaskLoaded(response));
    } catch (e) {
      emit(TaskError('Не удалось загрузить данные: ${e.toString()}'));
    }
  }

// // Метод для поиска лидов
Future<void> _fetchTasks(FetchTasks event, Emitter<TaskState> emit) async {
  emit(TaskLoading());
  if (!await _checkInternetConnection()) {
    emit(TaskError('Нет подключения к интернету'));
    return;
  }

  try {
    // Передаем правильный leadStatusId из события FetchLeads
    final tasks = await apiService.getTasks(
      event.statusId,
      page: 1,
      perPage: 20,
      search: event.query,
    );
    allTasksFetched = tasks.isEmpty;
    emit(TaskDataLoaded(tasks, currentPage: 1));
  } catch (e) {
    emit(TaskError('Не удалось загрузить задачи: ${e.toString()}'));
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
          'Не удалось загрузить дополнительные задачи: ${e.toString()}'));
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
        // file: event.file // C
      );

      if (result['success']) {
        emit(TaskSuccess('Задача создана успешно'));
        add(FetchTasks(event.statusId));
      } else {
        emit(TaskError(result['message']));
      }
    } catch (e) {
      emit(TaskError('Ошибка создания задачи: ${e.toString()}'));
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
        // file: event.file 
      );

      if (result['success']) {
        emit(TaskSuccess('Задача обновлена успешно'));
        add(FetchTasks(event.statusId));
      } else {
        emit(TaskError(result['message']));
      }
    } catch (e) {
      emit(TaskError('Ошибка обновления задачи: ${e.toString()}'));
    }
  }

  Future<void> _createTaskStatus(
      CreateTaskStatus event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    if (!await _checkInternetConnection()) {
      emit(TaskError('Нет подключения к интернету'));
      return;
    }

    try {
      final result = await apiService.createTaskStatus(event.name, event.color);

      if (result['success']) {
        emit(TaskSuccess(result['message']));
        add(FetchTaskStatuses());
      } else {
        emit(TaskError(result['message']));
      }
    } catch (e) {
      emit(TaskError('Ошибка создания статуса задачи: ${e.toString()}'));
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
        emit(TaskDeleted('Задача удалена успешно'));
        add(FetchTasks(event.taskId)); // Перезагрузка лида после удаления
      } else {
        emit(TaskError('Ошибка удаления задача'));
      }
    } catch (e) {
      emit(TaskError('Ошибка удаления задача: ${e.toString()}'));
    }
  }
  
   Future<void> _deleteTaskStatuses(DeleteTaskStatuses event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    try {
      final response = await apiService.deleteTaskStatuses(event.taskStatusId);
      if (response['result'] == 'Success') {
        emit(TaskDeleted('Статус задачи удалена успешно'));
        add(FetchTasks(event.taskStatusId)); // Перезагрузка лида после удаления
      } else {
        emit(TaskError('Ошибка удаления статуса сделки'));
      }
    } catch (e) {
      emit(TaskError('Ошибка удаления статуса сделки: ${e.toString()}'));
    }
  }
}
