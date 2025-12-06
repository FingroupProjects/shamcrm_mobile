import 'dart:async';
import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:flutter/foundation.dart';
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
  List<int>? _currentProjectIds;
  List<String>? _currentAuthors;
  DateTime? _currentDeadlineFromDate;
  DateTime? _currentDeadlineToDate;
  String? _currentDepartment;
  List<Map<String, dynamic>>? _currentDirectoryValues; // Добавляем для справочников
  bool isFetching = false; // Флаг для предотвращения параллельных запросов

  TaskBloc(this.apiService) : super(TaskInitial()) {
    on<FetchTaskStatuses>(_fetchTaskStatuses);
    on<FetchTaskStatusesWithFilters>(_fetchTaskStatusesWithFilters);
    on<FetchTasks>(_fetchTasks);
    on<CreateTask>(_createTask);
    on<FetchMoreTasks>(_fetchMoreTasks);
    on<UpdateTask>(_updateTask);
    on<DeleteTask>(_deleteTask);
    on<DeleteTaskStatuses>(_deleteTaskStatuses);
    on<FetchTaskStatus>(_fetchTaskStatus);
    on<UpdateTaskStatusEdit>(_updateTaskStatusEdit);
  }

  Future<void> _fetchTaskStatus(FetchTaskStatus event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final taskStatus = await apiService.getTaskStatus(event.taskStatusId);
      emit(TaskStatusLoaded(taskStatus));
    } catch (e) {
      emit(TaskError('Failed to fetch task status: ${e.toString()}'));
    }
  }

Future<void> _fetchTaskStatuses(FetchTaskStatuses event, Emitter<TaskState> emit) async {
  emit(TaskLoading());

  try {
    List<TaskStatus> response;

    // При forceRefresh = true делаем РАДИКАЛЬНУЮ перезагрузку
    if (event.forceRefresh) {
      if (!await _checkInternetConnection()) {
        emit(TaskError('Нет подключения к интернету для обновления данных'));
        return;
      }
      
      // РАДИКАЛЬНАЯ очистка всех локальных данных блока
      _taskCounts.clear();
      allTasksFetched = false;
      isFetching = false;
      
      // Сбрасываем все параметры фильтрации
      _currentQuery = null;
      _currentUserIds = null;
      _currentStatusIds = null;
      _currentFromDate = null;
      _currentToDate = null;
      _currentOverdue = null;
      _currentHasFile = null;
      _currentHasDeal = null;
      _currentUrgent = null;
      _currentProjectIds = null;
      _currentAuthors = null;
      _currentDeadlineFromDate = null;
      _currentDeadlineToDate = null;
      _currentDepartment = null;
      _currentDirectoryValues = null;
      
      // Загружаем статусы с сервера
      response = await apiService.getTaskStatuses();
      
      // ПОЛНОСТЬЮ перезаписываем кэш новыми данными
      await TaskCache.clearEverything();
      await TaskCache.cacheTaskStatuses(response
          .map((status) => {'id': status.id, 'title': status.taskStatus?.name ?? ""})
          .toList());
      
      // Устанавливаем новые счетчики ТОЛЬКО из свежих данных API
      for (var status in response) {
        final count = int.tryParse(status.tasksCount) ?? 0;
        _taskCounts[status.id] = count;
        await TaskCache.setPersistentTaskCount(status.id, count);
      }
      
    } else {
      // Стандартная логика для обычной загрузки
      if (!await _checkInternetConnection()) {
        final cachedStatuses = await TaskCache.getTaskStatuses();
        if (cachedStatuses.isNotEmpty) {
          // При отсутствии интернета загружаем минимальные данные из кэша
          // но это будет работать только для отображения табов
          // Счётчики восстанавливаем из persistent cache
          _taskCounts.clear();
          final allPersistentCounts = await TaskCache.getPersistentTaskCounts();
          for (String statusIdStr in allPersistentCounts.keys) {
            int statusId = int.parse(statusIdStr);
            int count = allPersistentCounts[statusIdStr] ?? 0;
            _taskCounts[statusId] = count;
          }
          
          // Создаём минимальные TaskStatus объекты для отображения
          final List<TaskStatus> minimalStatuses = cachedStatuses.map((status) {
            final statusId = status['id'] as int;
            final count = _taskCounts[statusId] ?? 0;
            return TaskStatus(
              id: statusId,
              color: '#000000',
              tasksCount: count.toString(),
              needsPermission: false,
              finalStep: false,
              checkingStep: false,
              roles: [],
              taskStatus: TaskStatusName(
                id: statusId,
                name: status['title'] as String,
              ),
            );
          }).toList();
          
          emit(TaskLoaded(minimalStatuses, taskCounts: Map.from(_taskCounts)));
        } else {
          emit(TaskError('Нет подключения к интернету и нет кэшированных данных'));
        }
        return;
      }

      // ВСЕГДА загружаем с API для получения актуальных счётчиков
      response = await apiService.getTaskStatuses();
      await TaskCache.cacheTaskStatuses(response
          .map((status) => {'id': status.id, 'title': status.taskStatus?.name ?? ""})
          .toList());

      // Устанавливаем счетчики из свежих данных API
      _taskCounts.clear();
      for (var status in response) {
        final count = int.tryParse(status.tasksCount) ?? 0;
        _taskCounts[status.id] = count;
        await TaskCache.setPersistentTaskCount(status.id, count);
      }
    }

    emit(TaskLoaded(response, taskCounts: Map.from(_taskCounts)));

    // При обычной загрузке автоматически загружаем задачи для первого статуса
    if (response.isNotEmpty && !event.forceRefresh && !_hasActiveFilters()) {
      final firstStatusId = response.first.id;
      add(FetchTasks(firstStatusId));
    }

  } catch (e) {
    emit(TaskError('Не удалось загрузить статусы: $e'));
  }
}

Future<void> _fetchTasks(FetchTasks event, Emitter<TaskState> emit) async {
  if (isFetching) {
    debugPrint('⚠️ TaskBloc: _fetchTasks - Already fetching, skipping');
    return;
  }

  isFetching = true;

  if (kDebugMode) {
    debugPrint('🔍 TaskBloc: _fetchTasks - START');
    debugPrint('🔍 TaskBloc: statusId=${event.statusId}');
  }

  try {
    if (state is! TaskDataLoaded) {
      emit(TaskLoading());
    }

    // Сохраняем параметры текущего запроса
    _currentQuery = event.query;
    _currentUserIds = event.userIds;
    _currentStatusIds = event.statusIds;
    _currentFromDate = event.fromDate;
    _currentToDate = event.toDate;
    _currentOverdue = event.overdue;
    _currentHasFile = event.hasFile;
    _currentHasDeal = event.hasDeal;
    _currentUrgent = event.urgent;
    _currentProjectIds = event.projectIds;
    _currentAuthors = event.authors;
    _currentDeadlineFromDate = event.deadlinefromDate;
    _currentDeadlineToDate = event.deadlinetoDate;
    _currentDepartment = event.department;
    _currentDirectoryValues = event.directoryValues;

    // КРИТИЧНО: Восстанавливаем ВСЕ постоянные счетчики
    final allPersistentCounts = await TaskCache.getPersistentTaskCounts();
    for (String statusIdStr in allPersistentCounts.keys) {
      int statusId = int.parse(statusIdStr);
      int count = allPersistentCounts[statusIdStr] ?? 0;
      _taskCounts[statusId] = count;
    }

    if (kDebugMode) {
      debugPrint('✅ TaskBloc: Restored persistent counts: $_taskCounts');
    }

    List<Task> tasks = [];

    // Попытка загрузить из кэша
    tasks = await TaskCache.getTasksForStatus(event.statusId);
    if (tasks.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('✅ TaskBloc: _fetchTasks - Emitting ${tasks.length} cached tasks for status ${event.statusId}');
      }
      emit(TaskDataLoaded(tasks, currentPage: 1, taskCounts: Map.from(_taskCounts)));
    }

    if (await _checkInternetConnection()) {
      if (kDebugMode) {
        debugPrint('📡 TaskBloc: Internet available, fetching from API');
      }

      tasks = await apiService.getTasks(
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
        projectIds: event.projectIds,
        authors: event.authors,
        deadlinefromDate: event.deadlinefromDate,
        deadlinetoDate: event.deadlinetoDate,
        department: event.department,
        directoryValues: event.directoryValues,
      );

      if (kDebugMode) {
        debugPrint('✅ TaskBloc: Fetched ${tasks.length} tasks from API for status ${event.statusId}');
      }

      // КЛЮЧЕВОЙ МОМЕНТ: Берём реальный счётчик из _taskCounts
      final int? realTotalCount = _taskCounts[event.statusId];
      
      if (kDebugMode) {
        debugPrint('🔍 TaskBloc: Real total count for status ${event.statusId}: $realTotalCount');
      }

      // Кэшируем задачи с РЕАЛЬНЫМ общим счётчиком
      await TaskCache.cacheTasksForStatus(
        event.statusId,
        tasks,
        updatePersistentCount: true,
        actualTotalCount: realTotalCount,
      );
      
      if (kDebugMode) {
        debugPrint('✅ TaskBloc: Cached ${tasks.length} tasks for status ${event.statusId}');
      }
    } else {
      if (kDebugMode) {
        debugPrint('❌ TaskBloc: No internet connection');
      }
    }

    allTasksFetched = tasks.isEmpty;

    if (kDebugMode) {
      debugPrint('✅ TaskBloc: _fetchTasks - Emitting TaskDataLoaded with ${tasks.length} tasks');
      debugPrint('✅ TaskBloc: Final taskCounts: $_taskCounts');
    }

    emit(TaskDataLoaded(tasks, currentPage: 1, taskCounts: Map.from(_taskCounts)));
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ TaskBloc: _fetchTasks - Error: $e');
    }
    if (e is ApiException && e.statusCode == 401) {
      emit(TaskError('Неавторизованный доступ!'));
    } else {
      emit(TaskError('Не удалось загрузить данные!'));
    }
  } finally {
    isFetching = false;
    if (kDebugMode) {
      debugPrint('🏁 TaskBloc: _fetchTasks - FINISHED');
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
        search: event.query ?? _currentQuery,
        users: event.userIds ?? _currentUserIds,
        statuses: event.statusIds ?? _currentStatusIds,
        fromDate: event.fromDate ?? _currentFromDate,
        toDate: event.toDate ?? _currentToDate,
        overdue: event.overdue ?? _currentOverdue,
        hasFile: event.hasFile ?? _currentHasFile,
        hasDeal: event.hasDeal ?? _currentHasDeal,
        urgent: event.urgent ?? _currentUrgent,
        projectIds: event.projectIds ?? _currentProjectIds,
        authors: event.authors ?? _currentAuthors,
        deadlinefromDate: event.deadlinefromDate ?? _currentDeadlineFromDate,
        deadlinetoDate: event.deadlinetoDate ?? _currentDeadlineToDate,
        department: event.department ?? _currentDepartment,
        directoryValues: event.directoryValues ?? _currentDirectoryValues, // Передаем directoryValues
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
        files: event.files,
        directoryValues: event.directoryValues,
      );
      if (result['success']) {
        emit(TaskSuccess(event.localizations.translate('task_create_successfully')));
      } else {
        emit(TaskError(event.localizations.translate(result['message'])));
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
      taskStatusId: event.taskStatusId,
      priority: event.priority,
      startDate: event.startDate,
      endDate: event.endDate,
      projectId: event.projectId,
      userId: event.userId,
      description: event.description,
      customFields: event.customFields,
      filePaths: event.filePaths,
      existingFiles: event.existingFiles,
      directoryValues: event.directoryValues, // Add for consistency
    );

    if (result['success']) {
      emit(TaskSuccess(event.localizations.translate('task_update_successfully')));
    } else {
      emit(TaskError(event.localizations.translate(result['message'])));
    }
  } catch (e) {
    emit(TaskError(event.localizations.translate('error_task_update_successfully')));
  }
}
  // Метод для проверки наличия активных фильтров
  bool _hasActiveFilters() {
    return (_currentQuery != null && _currentQuery!.isNotEmpty) ||
        (_currentUserIds != null && _currentUserIds!.isNotEmpty) ||
        (_currentStatusIds != null) ||
        (_currentFromDate != null) ||
        (_currentToDate != null) ||
        (_currentOverdue == true) ||
        (_currentHasFile == true) ||
        (_currentHasDeal == true) ||
        (_currentUrgent == true) ||
        (_currentProjectIds != null && _currentProjectIds!.isNotEmpty) ||
        (_currentAuthors != null && _currentAuthors!.isNotEmpty) ||
        (_currentDeadlineFromDate != null) ||
        (_currentDeadlineToDate != null) ||
        (_currentDepartment != null && _currentDepartment!.isNotEmpty) ||
        (_currentDirectoryValues != null && _currentDirectoryValues!.isNotEmpty);
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

Future<void> _fetchTaskStatusesWithFilters(
  FetchTaskStatusesWithFilters event,
  Emitter<TaskState> emit,
) async {
  if (kDebugMode) {
    debugPrint('🔍 TaskBloc: _fetchTaskStatusesWithFilters - START');
  }

  emit(TaskLoading());

  try {
    // 1. Получаем статусы с учётом фильтров
    final statuses = await apiService.getTaskStatuses(
      users: event.userIds,
      statuses: event.statusIds,
      fromDate: event.fromDate,
      toDate: event.toDate,
      overdue: event.overdue,
      hasFile: event.hasFile,
      hasDeal: event.hasDeal,
      urgent: event.urgent,
      deadlinefromDate: event.deadlinefromDate,
      deadlinetoDate: event.deadlinetoDate,
      projectIds: event.projectIds,
      authors: event.authors,
      department: event.department,
      directoryValues: event.directoryValues,
    );

    if (kDebugMode) {
      debugPrint('✅ TaskBloc: Got ${statuses.length} statuses with filters');
    }

    // 2. Обновляем счётчики из полученных статусов
    _taskCounts.clear();
    for (var status in statuses) {
      // Получаем количество задач для статуса из ответа API
      // TaskStatus.tasksCount это String, преобразуем в int
      final count = int.tryParse(status.tasksCount) ?? 0;
      _taskCounts[status.id] = count;
    }

    // 3. Кэшируем статусы
    await TaskCache.cacheTaskStatuses(statuses
        .map((status) => {'id': status.id, 'title': status.taskStatus?.name ?? ""})
        .toList());

    // 4. Эмитим состояние со статусами
    emit(TaskLoaded(statuses, taskCounts: Map.from(_taskCounts)));

    // 5. СОХРАНЯЕМ ФИЛЬТРЫ В БЛОКЕ ПЕРЕД ПАРАЛЛЕЛЬНОЙ ЗАГРУЗКОЙ
    if (statuses.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('🚀 TaskBloc: Starting parallel fetch for ${statuses.length} statuses');
        debugPrint('🔍 TaskBloc: SAVING FILTERS TO BLOC STATE');
      }

      // СОХРАНЯЕМ фильтры для последующих запросов
      _currentQuery = null;
      _currentUserIds = event.userIds;
      _currentStatusIds = event.statusIds;
      _currentFromDate = event.fromDate;
      _currentToDate = event.toDate;
      _currentOverdue = event.overdue;
      _currentHasFile = event.hasFile;
      _currentHasDeal = event.hasDeal;
      _currentUrgent = event.urgent;
      _currentProjectIds = event.projectIds;
      _currentAuthors = event.authors;
      _currentDeadlineFromDate = event.deadlinefromDate;
      _currentDeadlineToDate = event.deadlinetoDate;
      _currentDepartment = event.department;
      _currentDirectoryValues = event.directoryValues;

      if (kDebugMode) {
        debugPrint('✅ TaskBloc: Filters saved to bloc state');
      }

      // Создаём список Future для параллельной загрузки
      final List<Future<void>> fetchTasks = statuses.map((status) {
        return _fetchTasksForStatusWithFilters(
          status.id,
          event.userIds,
          event.statusIds,
          event.fromDate,
          event.toDate,
          event.overdue,
          event.hasFile,
          event.hasDeal,
          event.urgent,
          event.deadlinefromDate,
          event.deadlinetoDate,
          event.projectIds,
          event.authors,
          event.department,
          event.directoryValues,
        );
      }).toList();

      // Запускаем все запросы параллельно
      await Future.wait(fetchTasks);

      if (kDebugMode) {
        debugPrint('✅ TaskBloc: All parallel fetches completed');
      }

      // После загрузки всех данных эмитим финальное состояние
      final allTasks = <Task>[];
      for (var status in statuses) {
        final tasksForStatus = await TaskCache.getTasksForStatus(status.id);
        allTasks.addAll(tasksForStatus);
      }

      emit(TaskDataLoaded(allTasks, currentPage: 1, taskCounts: Map.from(_taskCounts)));
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ TaskBloc: _fetchTaskStatusesWithFilters - Error: $e');
    }
    emit(TaskError('Не удалось загрузить статусы с фильтрами: $e'));
  }
}

// Вспомогательный метод для загрузки задач одного статуса
Future<void> _fetchTasksForStatusWithFilters(
  int statusId,
  List<int>? userIds,
  int? statusIds,
  DateTime? fromDate,
  DateTime? toDate,
  bool? overdue,
  bool? hasFile,
  bool? hasDeal,
  bool? urgent,
  DateTime? deadlinefromDate,
  DateTime? deadlinetoDate,
  List<int>? projectIds,
  List<String>? authors,
  String? department,
  List<Map<String, dynamic>>? directoryValues,
) async {
  try {
    if (!await _checkInternetConnection()) {
      if (kDebugMode) {
        debugPrint('⚠️ TaskBloc: No internet for status $statusId');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('🔍 TaskBloc: _fetchTasksForStatusWithFilters for status $statusId');
    }

    final tasks = await apiService.getTasks(
      null, // taskStatusId = null, используем statuses параметр
      page: 1,
      perPage: 20,
      users: userIds,
      statuses: statusId, // ID статуса через параметр statuses
      fromDate: fromDate,
      toDate: toDate,
      overdue: overdue,
      hasFile: hasFile,
      hasDeal: hasDeal,
      urgent: urgent,
      deadlinefromDate: deadlinefromDate,
      deadlinetoDate: deadlinetoDate,
      projectIds: projectIds,
      authors: authors,
      department: department,
      directoryValues: directoryValues,
    );

    if (kDebugMode) {
      debugPrint('✅ TaskBloc: Fetched ${tasks.length} tasks for status $statusId WITH FILTERS');
    }

    // Кэшируем с сохранением реального счётчика
    final realCount = _taskCounts[statusId];
    await TaskCache.cacheTasksForStatus(
      statusId,
      tasks,
      updatePersistentCount: true,
      actualTotalCount: realCount,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ TaskBloc: Error fetching tasks for status $statusId: $e');
    }
  }
}

  // ======================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ========================
  
  /// РАДИКАЛЬНАЯ очистка - удаляет ВСЕ данные и сбрасывает состояние блока
  Future<void> clearAllCountsAndCache() async {
    // Очищаем локальные переменные блока
    _taskCounts.clear();
    allTasksFetched = false;
    isFetching = false;
    
    // Сбрасываем все текущие параметры фильтрации
    _currentQuery = null;
    _currentUserIds = null;
    _currentStatusIds = null;
    _currentFromDate = null;
    _currentToDate = null;
    _currentOverdue = null;
    _currentHasFile = null;
    _currentHasDeal = null;
    _currentUrgent = null;
    _currentProjectIds = null;
    _currentAuthors = null;
    _currentDeadlineFromDate = null;
    _currentDeadlineToDate = null;
    _currentDepartment = null;
    _currentDirectoryValues = null;
    
    // Радикальная очистка кэша
    await TaskCache.clearEverything();
  }

  /// Дополнительный метод для принудительного сброса всех счетчиков
  Future<void> resetAllCounters() async {
    _taskCounts.clear();
    await TaskCache.clearPersistentCounts();
  }
  
  /// Вызывать перед переходом между табами
  Future<void> _preserveCurrentCounts() async {
    if (_taskCounts.isNotEmpty) {
      for (int statusId in _taskCounts.keys) {
        int currentCount = _taskCounts[statusId] ?? 0;
        await TaskCache.setPersistentTaskCount(statusId, currentCount);
      }
    }
  }
  
  /// Метод для восстановления всех счетчиков из постоянного кэша
  Future<void> _restoreAllCounts() async {
    final allPersistentCounts = await TaskCache.getPersistentTaskCounts();
    _taskCounts.clear();
    
    for (String statusIdStr in allPersistentCounts.keys) {
      int statusId = int.parse(statusIdStr);
      int count = allPersistentCounts[statusIdStr] ?? 0;
      _taskCounts[statusId] = count;
    }
  }
}