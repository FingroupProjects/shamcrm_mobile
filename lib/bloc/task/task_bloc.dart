import 'dart:async';
import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/offline/core/offline_module.dart';
import 'package:crm_task_manager/offline/core/offline_runtime.dart';
import 'package:crm_task_manager/offline/core/request_priority.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:crm_task_manager/api/service/api_service.dart' as api_service;
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
  List<int>? _currentReasonForRefusalIds;
  List<String>? _currentAuthors;
  DateTime? _currentDeadlineFromDate;
  DateTime? _currentDeadlineToDate;
  DateTime? _currentCompletedFromDate;
  DateTime? _currentCompletedToDate;
  String? _currentDepartment;
  List<Map<String, dynamic>>?
      _currentDirectoryValues; // Добавляем для справочников
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

  Future<void> _fetchTaskStatus(
      FetchTaskStatus event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final taskStatus = await apiService.getTaskStatus(event.taskStatusId);
      emit(TaskStatusLoaded(taskStatus));
    } catch (e) {
      emit(TaskError('Failed to fetch task status: ${e.toString()}'));
    }
  }

  Future<void> _fetchTaskStatuses(
      FetchTaskStatuses event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    try {
      List<TaskStatus> response;

      // При forceRefresh = true делаем РАДИКАЛЬНУЮ перезагрузку
      if (event.forceRefresh) {
        final hasInternet = await _checkInternetConnection();

        if (!hasInternet) {
          // При отсутствии интернета загружаем из кэша вместо ошибки
          final cachedStatuses = await TaskCache.getTaskStatuses();
          if (cachedStatuses.isNotEmpty) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ TaskBloc: forceRefresh without internet, loading from cache');
            }

            // Восстанавливаем счетчики из persistent cache
            _taskCounts.clear();
            final allPersistentCounts =
                await TaskCache.getPersistentTaskCounts();
            for (String statusIdStr in allPersistentCounts.keys) {
              int statusId = int.parse(statusIdStr);
              int count = allPersistentCounts[statusIdStr] ?? 0;
              _taskCounts[statusId] = count;
            }

            // Создаём TaskStatus объекты из кэша
            final List<TaskStatus> minimalStatuses =
                cachedStatuses.map((status) {
              final statusId = status['id'] as int;
              final count = _taskCounts[statusId] ?? 0;
              return TaskStatus(
                id: statusId,
                color: '#000000',
                tasksCount: count.toString(),
                needsPermission: false,
                finalStep: false,
                checkingStep: false,
                isUnassembled: status['is_unassembled'] == true,
                roles: [],
                taskStatus: TaskStatusName(
                  id: statusId,
                  name: status['title'] as String,
                ),
              );
            }).toList();

            emit(
                TaskLoaded(minimalStatuses, taskCounts: Map.from(_taskCounts)));
            return;
          } else {
            emit(
                TaskError('Нет подключения к интернету для обновления данных'));
            return;
          }
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
        _currentReasonForRefusalIds = null;
        _currentAuthors = null;
        _currentDeadlineFromDate = null;
        _currentDeadlineToDate = null;
        _currentDepartment = null;
        _currentDirectoryValues = null;

        // ОПТИМИЗАЦИЯ: Загружаем статусы с сервера с timeout
        api_service.ApiService.clearAnalyticsResponseCache();
        response = await apiService.getTaskStatuses(bypassCache: true).timeout(
          Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException(
                'Превышено время ожидания загрузки статусов');
          },
        );

        // ПОЛНОСТЬЮ перезаписываем кэш новыми данными
        await TaskCache.clearEverything();
        await TaskCache.cacheTaskStatuses(response
            .map((status) => {
                  'id': status.id,
                  'title': status.taskStatus?.name ?? "",
                  'is_unassembled': status.isUnassembled,
                })
            .toList());

        // Устанавливаем новые счетчики ТОЛЬКО из свежих данных API
        for (var status in response) {
          final count = int.tryParse(status.tasksCount) ?? 0;
          _taskCounts[status.id] = count;
          await TaskCache.setPersistentTaskCount(status.id, count);
        }
      } else {
        // Стандартная логика для обычной загрузки
        final hasInternet = await _checkInternetConnection();

        if (!hasInternet) {
          // При отсутствии интернета пытаемся загрузить из кэша
          final cachedStatuses = await TaskCache.getTaskStatuses();
          if (cachedStatuses.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('⚠️ TaskBloc: No internet, loading from cache');
            }

            // Счётчики восстанавливаем из persistent cache
            _taskCounts.clear();
            final allPersistentCounts =
                await TaskCache.getPersistentTaskCounts();
            for (String statusIdStr in allPersistentCounts.keys) {
              int statusId = int.parse(statusIdStr);
              int count = allPersistentCounts[statusIdStr] ?? 0;
              _taskCounts[statusId] = count;
            }

            // Создаём минимальные TaskStatus объекты для отображения
            final List<TaskStatus> minimalStatuses =
                cachedStatuses.map((status) {
              final statusId = status['id'] as int;
              final count = _taskCounts[statusId] ?? 0;
              return TaskStatus(
                id: statusId,
                color: '#000000',
                tasksCount: count.toString(),
                needsPermission: false,
                finalStep: false,
                checkingStep: false,
                isUnassembled: false,
                roles: [],
                taskStatus: TaskStatusName(
                  id: statusId,
                  name: status['title'] as String,
                ),
              );
            }).toList();

            emit(
                TaskLoaded(minimalStatuses, taskCounts: Map.from(_taskCounts)));

            if (kDebugMode) {
              debugPrint(
                  '✅ TaskBloc: Loaded ${minimalStatuses.length} statuses from cache');
            }
            return;
          } else {
            if (kDebugMode) {
              debugPrint('❌ TaskBloc: No internet and no cache available');
            }
            emit(TaskError(
                'Нет подключения к интернету и нет кэшированных данных'));
            return;
          }
        }

        // ОПТИМИЗАЦИЯ: ВСЕГДА загружаем с009 API для получения актуальных счётчиков с timeout
        response = await apiService.getTaskStatuses(
          bypassCache: event.forceRefresh,
        ).timeout(
          Duration(seconds: 15),
          onTimeout: () async {
            // При timeout возвращаем кэшированные данные
            final cachedStatuses = await TaskCache.getTaskStatuses();
            if (cachedStatuses.isNotEmpty) {
              return cachedStatuses.map((status) {
                return TaskStatus(
                  id: status['id'] as int,
                  color: '#000000',
                  tasksCount: '0',
                  needsPermission: false,
                  finalStep: false,
                  checkingStep: false,
                  isUnassembled: status['is_unassembled'] == true,
                  roles: [],
                  taskStatus: TaskStatusName(
                    id: status['id'] as int,
                    name: status['title'] as String,
                  ),
                );
              }).toList();
            }
            throw TimeoutException(
                'Превышено время ожидания загрузки статусов');
          },
        );
        await TaskCache.cacheTaskStatuses(response
            .map((status) => {
                  'id': status.id,
                  'title': status.taskStatus?.name ?? "",
                  'is_unassembled': status.isUnassembled,
                })
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

      // ОПТИМИЗАЦИЯ: Убираем автоматическую загрузку задач - пусть TaskScreen сам решит когда загружать
      // При обычной загрузке автоматически загружаем задачи для первого статуса
      // if (response.isNotEmpty && !event.forceRefresh && !_hasActiveFilters()) {
      //   final firstStatusId = response.first.id;
      //   add(FetchTasks(firstStatusId));
      // }
    } catch (e) {
      emit(TaskError('Не удалось загрузить статусы: $e'));
    }
  }

  Future<void> _fetchTasks(FetchTasks event, Emitter<TaskState> emit) async {
    // ОПТИМИЗАЦИЯ: Улучшенная проверка на параллельные запросы
    if (isFetching) {
      if (kDebugMode) {
        debugPrint('⚠️ TaskBloc: _fetchTasks - Already fetching, skipping');
      }
      return;
    }

    isFetching = true;

    if (kDebugMode) {
      debugPrint('🔍 TaskBloc: _fetchTasks - START');
      debugPrint('🔍 TaskBloc: statusId=${event.statusId}');
    }

    try {
      // ОПТИМИЗАЦИЯ: Показываем загрузку только если нет кэшированных данных
      final cachedTasks = await TaskCache.getTasksForStatus(event.statusId);
      if (cachedTasks.isEmpty) {
        if (state is! TaskDataLoaded) {
          emit(TaskLoading());
        }
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
      _currentReasonForRefusalIds = event.reasonForRefusalIds;
      _currentAuthors = event.authors;
      _currentDeadlineFromDate = event.deadlinefromDate;
      _currentDeadlineToDate = event.deadlinetoDate;
      _currentCompletedFromDate = event.completedFromDate;
      _currentCompletedToDate = event.completedToDate;
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
      bool hasCachedData = false;

      // ОПТИМИЗАЦИЯ: Сначала загружаем из кэша для быстрого отображения (уже загружено выше)
      if (cachedTasks.isNotEmpty) {
        tasks = cachedTasks;
        hasCachedData = true;
        if (kDebugMode) {
          debugPrint(
              '✅ TaskBloc: _fetchTasks - Found ${tasks.length} cached tasks for status ${event.statusId}');
        }
        // Сразу показываем кэшированные данные
        emit(TaskDataLoaded(tasks,
            currentPage: 1, taskCounts: Map.from(_taskCounts)));
      }

      // ОПТИМИЗАЦИЯ: Проверяем интернет только если нужно обновить данные
      final hasInternet = await _checkInternetConnection();

      if (hasInternet) {
        if (kDebugMode) {
          debugPrint('📡 TaskBloc: Internet available, fetching from API');
        }

        try {
          // ОПТИМИЗАЦИЯ: Загружаем задачи с timeout
          final freshTasks = await apiService
              .getTasks(
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
            reasonForRefusalIds: event.reasonForRefusalIds,
            authors: event.authors,
            deadlinefromDate: event.deadlinefromDate,
            deadlinetoDate: event.deadlinetoDate,
            completedFromDate: event.completedFromDate,
            completedToDate: event.completedToDate,
            department: event.department,
            directoryValues: event.directoryValues,
          )
              .timeout(
            Duration(seconds: 20),
            onTimeout: () {
              // При timeout возвращаем пустой список, кэшированные данные уже показаны
              if (kDebugMode) {
                debugPrint('⚠️ TaskBloc: getTasks timeout, using cached data');
              }
              return <Task>[];
            },
          );

          if (freshTasks.isNotEmpty) {
            tasks = freshTasks;
            if (kDebugMode) {
              debugPrint(
                  '✅ TaskBloc: Fetched ${tasks.length} fresh tasks from API for status ${event.statusId}');
            }

            // КЛЮЧЕВОЙ МОМЕНТ: Берём реальный счётчик из _taskCounts
            final int? realTotalCount = _taskCounts[event.statusId];

            if (kDebugMode) {
              debugPrint(
                  '🔍 TaskBloc: Real total count for status ${event.statusId}: $realTotalCount');
            }

            // Кэшируем свежие задачи с РЕАЛЬНЫМ общим счётчиком
            await TaskCache.cacheTasksForStatus(
              event.statusId,
              tasks,
              updatePersistentCount: true,
              actualTotalCount: realTotalCount,
            );

            if (kDebugMode) {
              debugPrint(
                  '✅ TaskBloc: Cached ${tasks.length} tasks for status ${event.statusId}');
            }
          } else {
            final int? realTotalCount = _taskCounts[event.statusId];

            if ((realTotalCount ?? 0) == 0) {
              tasks = <Task>[];
              hasCachedData = false;
              await TaskCache.clearTasksForStatus(event.statusId);

              if (kDebugMode) {
                debugPrint(
                    '✅ TaskBloc: API returned empty list and count=0, clearing stale cache for status ${event.statusId}');
              }
            } else if (kDebugMode) {
              debugPrint(
                  '⚠️ TaskBloc: API returned empty list, keeping cached data');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '❌ TaskBloc: Error fetching from API: $e, using cached data');
          }
          // При ошибке продолжаем использовать кэшированные данные
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ TaskBloc: No internet connection, using cached data');
        }
      }

      allTasksFetched = tasks.isEmpty && !hasCachedData;

      if (kDebugMode) {
        debugPrint(
            '✅ TaskBloc: _fetchTasks - Final: ${tasks.length} tasks (cached: $hasCachedData)');
        debugPrint('✅ TaskBloc: Final taskCounts: $_taskCounts');
      }

      // Финальное состояние (если не было показано ранее из кэша)
      if (!hasCachedData || tasks.isNotEmpty) {
        emit(TaskDataLoaded(tasks,
            currentPage: 1, taskCounts: Map.from(_taskCounts)));
      }
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

  Future<void> _fetchMoreTasks(
      FetchMoreTasks event, Emitter<TaskState> emit) async {
    if (allTasksFetched) return;

    if (!await _checkInternetConnection()) {
      emit(TaskError('Нет подключения к интернету'));
      return;
    }

    try {
      // ОПТИМИЗАЦИЯ: Загружаем дополнительные задачи с timeout
      final tasks = await apiService
          .getTasks(
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
            reasonForRefusalIds:
                event.reasonForRefusalIds ?? _currentReasonForRefusalIds,
            authors: event.authors ?? _currentAuthors,
            deadlinefromDate:
                event.deadlinefromDate ?? _currentDeadlineFromDate,
            deadlinetoDate: event.deadlinetoDate ?? _currentDeadlineToDate,
            completedFromDate:
                event.completedFromDate ?? _currentCompletedFromDate,
            completedToDate: event.completedToDate ?? _currentCompletedToDate,
            department: event.department ?? _currentDepartment,
            directoryValues: event.directoryValues ?? _currentDirectoryValues,
          )
          .timeout(
            Duration(seconds: 20),
            onTimeout: () => <Task>[],
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
      if (event.files != null && event.files!.isNotEmpty) {
        emit(TaskError(
            'Офлайн-очередь для вложений будет доведена в phase 2. Сейчас офлайн поддерживаются только текстовые операции.'));
        return;
      }
      await OfflineRuntime.instance.outboxService.enqueue(
        id: 'task_create_${DateTime.now().millisecondsSinceEpoch}',
        module: OfflineModule.task,
        entityType: 'task',
        entityId: 'local_${DateTime.now().millisecondsSinceEpoch}',
        operationType: 'create',
        payload: {
          'name': event.name,
          'statusId': event.statusId,
          'taskStatusId': event.taskStatusId,
          'priority': event.priority,
          'startDate': event.startDate?.toIso8601String(),
          'endDate': event.endDate?.toIso8601String(),
          'projectId': event.projectId,
          'userId': event.userId,
          'description': event.description,
          'customFields': event.customFields,
          'directoryValues': event.directoryValues,
        },
        idempotencyKey: 'task-create-${DateTime.now().millisecondsSinceEpoch}',
        priority: RequestPriority.high,
      );
      emit(TaskSuccess(
          'Задача принята локально и поставлена в очередь на синхронизацию.'));
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
        emit(TaskSuccess(
            event.localizations.translate('task_create_successfully')));
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
      await OfflineRuntime.instance.outboxService.enqueue(
        id: 'task_update_${event.taskId}_${DateTime.now().millisecondsSinceEpoch}',
        module: OfflineModule.task,
        entityType: 'task',
        entityId: event.taskId.toString(),
        operationType: 'update',
        payload: {
          'taskId': event.taskId,
          'name': event.name,
          'taskStatusId': event.taskStatusId,
          'priority': event.priority,
          'startDate': event.startDate?.toIso8601String(),
          'endDate': event.endDate?.toIso8601String(),
          'projectId': event.projectId,
          'userId': event.userId,
          'description': event.description,
          'customFields': event.customFields,
          'filePaths': event.filePaths,
          'directoryValues': event.directoryValues,
          'reasonForRefusalId': event.reasonForRefusalId,
          'reasonForRefusal': event.reasonForRefusal,
        },
        idempotencyKey:
            'task-update-${event.taskId}-${DateTime.now().millisecondsSinceEpoch}',
        priority: RequestPriority.high,
      );
      emit(TaskSuccess(
          'Изменения задачи приняты локально и поставлены в очередь.'));
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
        reasonForRefusalId: event.reasonForRefusalId,
        reasonForRefusal: event.reasonForRefusal,
      );

      if (result['success']) {
        emit(TaskSuccess(
            event.localizations.translate('task_update_successfully')));
      } else {
        emit(TaskError(event.localizations.translate(result['message'])));
      }
    } catch (e) {
      emit(TaskError(
          event.localizations.translate('error_task_update_successfully')));
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
        (_currentReasonForRefusalIds != null &&
            _currentReasonForRefusalIds!.isNotEmpty) ||
        (_currentAuthors != null && _currentAuthors!.isNotEmpty) ||
        (_currentDeadlineFromDate != null) ||
        (_currentDeadlineToDate != null) ||
        (_currentDepartment != null && _currentDepartment!.isNotEmpty) ||
        (_currentDirectoryValues != null &&
            _currentDirectoryValues!.isNotEmpty);
  }

  // Кэш статуса интернет-соединения
  bool _cachedInternetStatus = true;
  DateTime? _lastInternetCheck;
  static const Duration _internetCheckInterval = Duration(seconds: 10);

  Future<bool> _checkInternetConnection() async {
    // ОПТИМИЗАЦИЯ: Используем кэшированный результат если проверка была недавно
    if (_lastInternetCheck != null &&
        DateTime.now().difference(_lastInternetCheck!) <
            _internetCheckInterval) {
      if (kDebugMode) {
        debugPrint(
            '🔄 TaskBloc: Using cached internet status: $_cachedInternetStatus');
      }
      return _cachedInternetStatus;
    }

    if (kDebugMode) {
      debugPrint('🌐 TaskBloc: Checking internet connection...');
    }

    try {
      // ИСПРАВЛЕНО: Проверяем несколькими способами для надежности
      // Способ 1: Быстрая проверка через DNS
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(Duration(seconds: 3), onTimeout: () => []);

        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('✅ TaskBloc: Internet check OK (DNS)');
          }
          _cachedInternetStatus = true;
          _lastInternetCheck = DateTime.now();
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ TaskBloc: DNS lookup failed: $e');
        }
      }

      // Способ 2: Пробуем создать сокет
      try {
        final socket =
            await Socket.connect('8.8.8.8', 53, timeout: Duration(seconds: 2));
        socket.destroy();
        if (kDebugMode) {
          debugPrint('✅ TaskBloc: Internet check OK (Socket)');
        }
        _cachedInternetStatus = true;
        _lastInternetCheck = DateTime.now();
        return true;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ TaskBloc: Socket connect failed: $e');
        }
      }

      // Оба способа не сработали - считаем что нет интернета
      if (kDebugMode) {
        debugPrint('❌ TaskBloc: No internet connection detected');
      }
      _cachedInternetStatus = false;
      _lastInternetCheck = DateTime.now();
      return false;
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TaskBloc: SocketException: $e');
      }
      _cachedInternetStatus = false;
      _lastInternetCheck = DateTime.now();
      return false;
    } catch (e) {
      // При любой другой ошибке считаем что интернет есть, чтобы попытаться сделать запрос
      if (kDebugMode) {
        debugPrint('⚠️ TaskBloc: Internet check error: $e, assuming online');
      }
      _cachedInternetStatus = true;
      _lastInternetCheck = DateTime.now();
      return true;
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
        isUnassembled: event.isUnassembled,
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
      // ОПТИМИЗАЦИЯ: 1. Получаем статусы с учётом фильтров с timeout
      final statuses = await apiService
          .getTaskStatuses(
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
        reasonForRefusalIds: event.reasonForRefusalIds,
        projectIds: event.projectIds,
        authors: event.authors,
        department: event.department,
        directoryValues: event.directoryValues,
      )
          .timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
              'Превышено время ожидания загрузки статусов с фильтрами');
        },
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
          .map((status) => {
                'id': status.id,
                'title': status.taskStatus?.name ?? "",
                'is_unassembled': status.isUnassembled,
              })
          .toList());

      // 4. Эмитим состояние со статусами
      emit(TaskLoaded(statuses, taskCounts: Map.from(_taskCounts)));

      // 5. СОХРАНЯЕМ ФИЛЬТРЫ В БЛОКЕ БЕЗ АВТОМАТИЧЕСКОЙ ЗАГРУЗКИ ВСЕХ СТАТУСОВ
      if (statuses.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
              '🚀 TaskBloc: Received ${statuses.length} statuses with filters');
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
        _currentReasonForRefusalIds = event.reasonForRefusalIds;
        _currentAuthors = event.authors;
        _currentDeadlineFromDate = event.deadlinefromDate;
        _currentDeadlineToDate = event.deadlinetoDate;
        _currentCompletedFromDate = event.completedFromDate;
        _currentCompletedToDate = event.completedToDate;
        _currentDepartment = event.department;
        _currentDirectoryValues = event.directoryValues;

        if (kDebugMode) {
          debugPrint('✅ TaskBloc: Filters saved to bloc state');
        }

        // ОПТИМИЗАЦИЯ: Загружаем только ПЕРВЫЙ статус, остальные по требованию
        if (statuses.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
                '🔄 TaskBloc: Loading tasks for first status only: ${statuses.first.id}');
          }

          try {
            await _fetchTasksForStatusWithFilters(
              statuses.first.id,
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
              event.completedFromDate,
              event.completedToDate,
              event.projectIds,
              event.reasonForRefusalIds,
              event.authors,
              event.department,
              event.directoryValues,
            );

            // После загрузки первого статуса эмитим состояние
            final firstStatusTasks =
                await TaskCache.getTasksForStatus(statuses.first.id);
            emit(TaskDataLoaded(firstStatusTasks,
                currentPage: 1, taskCounts: Map.from(_taskCounts)));

            if (kDebugMode) {
              debugPrint('✅ TaskBloc: First status tasks loaded and emitted');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ TaskBloc: Error loading first status tasks: $e');
            }
            // Эмитим пустое состояние если не удалось загрузить
            emit(TaskDataLoaded([],
                currentPage: 1, taskCounts: Map.from(_taskCounts)));
          }
        }
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
    DateTime? completedFromDate,
    DateTime? completedToDate,
    List<int>? projectIds,
    List<int>? reasonForRefusalIds,
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
        debugPrint(
            '🔍 TaskBloc: _fetchTasksForStatusWithFilters for status $statusId');
      }

      // ОПТИМИЗАЦИЯ: Загружаем задачи для статуса с timeout
      final tasks = await apiService
          .getTasks(
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
            completedFromDate: completedFromDate,
            completedToDate: completedToDate,
            projectIds: projectIds,
            reasonForRefusalIds: reasonForRefusalIds,
            authors: authors,
            department: department,
            directoryValues: directoryValues,
          )
          .timeout(
            Duration(seconds: 20),
            onTimeout: () => <Task>[],
          );

      if (kDebugMode) {
        debugPrint(
            '✅ TaskBloc: Fetched ${tasks.length} tasks for status $statusId WITH FILTERS');
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
    _currentReasonForRefusalIds = null;
    _currentAuthors = null;
    _currentDeadlineFromDate = null;
    _currentDeadlineToDate = null;
    _currentCompletedFromDate = null;
    _currentCompletedToDate = null;
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
}
