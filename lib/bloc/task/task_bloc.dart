import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final ApiService apiService;
  bool allTasksFetched =
      false; // Переменная для отслеживания статуса завершения загрузки сделок

  TaskBloc(this.apiService) : super(TaskInitial()) {
    on<FetchTaskStatuses>(_fetchTaskStatuses);
    on<FetchTasks>(_fetchTasks);
    // on<CreateTask>(_createTask);
    on<FetchMoreTasks>(_fetchMoreTasks);
    // on<CreateTaskStatus>(_createTaskStatus);
    on<UpdateTask>(_updateTask);

  }

  Future<void> _fetchTaskStatuses(
      FetchTaskStatuses event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    await Future.delayed(Duration(milliseconds: 500)); // Небольшая задержка

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

  // Метод для загрузки лидов
  Future<void> _fetchTasks(FetchTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    if (!await _checkInternetConnection()) {
      emit(TaskError('Нет подключения к интернету'));
      return;
    }

    try {
      final tasks = await apiService.getTasks(event.statusId);
      allTasksFetched = tasks.isEmpty; // Если сделок нет, устанавливаем флаг
      emit(TaskDataLoaded(tasks,
          currentPage: 1)); // Устанавливаем текущую страницу на 1
    } catch (e) {
      emit(TaskError('Не удалось загрузить лиды: ${e.toString()}'));
    }
  }

  Future<void> _fetchMoreTasks(
      FetchMoreTasks event, Emitter<TaskState> emit) async {
    if (allTasksFetched)
      return; // Если все сделки уже загружены, ничего не делаем

    if (!await _checkInternetConnection()) {
      emit(TaskError('Нет подключения к интернету'));
      return;
    }

    try {
      final tasks = await apiService.getTasks(event.statusId,
          page: event.currentPage + 1);
      if (tasks.isEmpty) {
        allTasksFetched = true; // Если пришли пустые данные, устанавливаем флаг
        return; // Выходим, так как данных больше нет
      }
      if (state is TaskDataLoaded) {
        final currentState = state as TaskDataLoaded;
        emit(currentState.merge(tasks)); // Объединяем старые и новые сделки
      }
    } catch (e) {
      emit(TaskError(
          'Не удалось загрузить дополнительные сделки: ${e.toString()}'));
    }
  }

  //  Future<void> _createTaskStatus(
  //     CreateTaskStatus event, Emitter<TaskState> emit) async {
  //   emit(TaskLoading());

  //   if (!await _checkInternetConnection()) {
  //     emit(TaskError('Нет подключения к интернету'));
  //     return;
  //   }

  //   try {
  //     final result =
  //         await apiService.createTaskStatus(event.name, event.color);

  //     if (result['success']) {
  //       emit(TaskSuccess(result['message']));
  //       add(FetchTaskStatuses()); 
  //     } else {
  //       emit(TaskError(result['message']));
  //     }
  //   } catch (e) {
  //     emit(TaskError('Ошибка создания статуса Сделки: ${e.toString()}'));
  //   }
  // }

  // Future<void> _createTask(CreateTask event, Emitter<TaskState> emit) async {
  //   emit(TaskLoading());

  //   // Проверка подключения к интернету
  //   if (!await _checkInternetConnection()) {
  //     emit(TaskError('Нет подключения к интернету'));
  //     return;
  //   }

  //   try {
  //     // Вызов метода создания лида
  //     final result = await apiService.createTask(
  //       name: event.name,
  //       taskStatusId: event.taskStatusId,
  //       startDate: event.startDate,
  //       endDate: event.endDate,
  //       description: event.description,
  //     );

  //     // Если успешно, то обновляем состояние
  //     if (result['success']) {
  //       emit(TaskSuccess('Сделка создан успешно'));
  //       add(FetchTasks(event.taskStatusId));
  //     } else {
  //       // Если есть ошибка, отображаем сообщение об ошибке
  //       emit(TaskError(result['message']));
  //     }
  //   } catch (e) {
  //     // Логирование ошибки
  //     emit(TaskError('Ошибка создания сделки: ${e.toString()}'));
  //   }
  // }

 
  
Future<void> _updateTask(UpdateTask event, Emitter<TaskState> emit) async {
  emit(TaskLoading());

  // Проверка подключения к интернету
  if (!await _checkInternetConnection()) {
    emit(TaskError('Нет подключения к интернету'));
    return;
  }

  // try {
  //   // Вызов метода обновления лида
  //   final result = await apiService.updateTask(
  //     taskId: event.taskId,
  //     name: event.name,
  //     taskStatusId: event.taskStatusId,
  //     managerId: event.managerId,
  //     description: event.description,
  //     organizationId: event.organizationId,
  //   );

  //   // Если успешно, то обновляем состояние
  //   if (result['success']) {
  //     emit(TaskSuccess('Лид обновлен успешно'));
  //     // add(FetchTask(event.taskStatusId)); // Обновляем список лидов
  //   } else {
  //     emit(TaskError(result['message']));
  //   }
  // } catch (e) {
  //   emit(TaskError('Ошибка обновления лида: ${e.toString()}'));
  // }
}

 

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}