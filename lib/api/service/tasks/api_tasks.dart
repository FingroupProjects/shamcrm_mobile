part of '../api_service.dart';

extension ApiTasksX on ApiService {
  Future<void> clearTaskStatusesPersistentCache() async {
    final prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();
    final cacheKey = 'cachedTaskStatuses_$organizationId';

    if (kDebugMode) {
      debugPrint(
          '🧹 ApiService.clearTaskStatusesPersistentCache: removing key=$cacheKey');
    }

    await prefs.remove(cacheKey);
  }

  Future<TaskById> getTaskById(int taskId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task/$taskId');
      if (kDebugMode) {
        debugPrint('ApiService: getTaskById - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonTask = decodedJson['result'];

        if (jsonTask == null || jsonTask['taskStatus'] == null) {
          throw Exception('Некорректные данные от API');
        }

        // Используем правильное имя ключа 'taskStatus' для получения статуса задачи
        return TaskById.fromJson(jsonTask, jsonTask['taskStatus']['id'] ?? 0);
      } else if (response.statusCode == 404) {
        throw Exception('Ресурс с задачи $taskId не найден');
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера. Попробуйте позже');
      } else {
        throw Exception('Ошибка загрузки task ID!');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: getTaskById error: $e');
      }
      throw Exception('Ошибка загрузки task ID');
    }
  }

  Future<List<Task>> getTasks(
    int? taskStatusId, {
    int page = 1,
    int perPage = 20,
    String? search,
    List<int>? users,
    int? statuses,
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
    int? projectId,
    List<String>? authors,
    String? department,
    List<int>? reasonForRefusalIds,
    List<Map<String, dynamic>>? directoryValues, // Добавляем directoryValues
  }) async {
    // Формируем базовый путь
    String path = projectId == null
        ? '/task?page=$page&per_page=$perPage'
        : '/task/get-by-project/$projectId?page=$page&per_page=$perPage';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getTasks - Generated path: $path');
    }

    bool hasFilters = (search != null && search.isNotEmpty) ||
        (users != null && users.isNotEmpty) ||
        (fromDate != null) ||
        (toDate != null) ||
        (statuses != null) ||
        overdue == true ||
        hasFile == true ||
        hasDeal == true ||
        urgent == true ||
        (deadlinefromDate != null) ||
        (deadlinetoDate != null) ||
        (completedFromDate != null) ||
        (completedToDate != null) ||
        (projectIds != null && projectIds.isNotEmpty) ||
        (authors != null && authors.isNotEmpty) ||
        (department != null && department.isNotEmpty) ||
        (reasonForRefusalIds != null && reasonForRefusalIds.isNotEmpty) ||
        (directoryValues != null &&
            directoryValues.isNotEmpty); // Проверяем directoryValues

    if (taskStatusId != null && !hasFilters) {
      path += '&task_status_id=$taskStatusId';
    }
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }
    if (users != null && users.isNotEmpty) {
      for (int i = 0; i < users.length; i++) {
        path += '&users[$i]=${users[i]}';
      }
    }
    if (statuses != null) {
      path += '&task_status_id=$statuses';
    }
    if (fromDate != null && toDate != null) {
      final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
      path += '&from=$formattedFromDate&to=$formattedToDate';
    }
    if (overdue == true) {
      path += '&overdue=1';
    }
    if (hasFile == true) {
      path += '&hasFile=1';
    }
    if (hasDeal == true) {
      path += '&hasDeal=1';
    }
    if (urgent == true) {
      path += '&urgent=1';
    }
    if (deadlinefromDate != null && deadlinetoDate != null) {
      final formattedFromDate =
          DateFormat('yyyy-MM-dd').format(deadlinefromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(deadlinetoDate);
      path += '&deadline_from=$formattedFromDate&deadline_to=$formattedToDate';
    }
    if (completedFromDate != null && completedToDate != null) {
      final formattedCompletedFrom =
          DateFormat('yyyy-MM-dd').format(completedFromDate);
      final formattedCompletedTo =
          DateFormat('yyyy-MM-dd').format(completedToDate);
      path +=
          '&completed_from=$formattedCompletedFrom&completed_to=$formattedCompletedTo';
    }
    if (projectIds != null && projectIds.isNotEmpty) {
      for (int projectId in projectIds) {
        path += '&project_ids[]=$projectId';
      }
    }
    if (authors != null && authors.isNotEmpty) {
      for (int i = 0; i < authors.length; i++) {
        path += '&authors[$i]=${authors[i]}';
      }
    }
    if (department != null && department.isNotEmpty) {
      path += '&department_id=$department';
    }
    if (reasonForRefusalIds != null && reasonForRefusalIds.isNotEmpty) {
      for (int i = 0; i < reasonForRefusalIds.length; i++) {
        path += '&reason_for_refusals[$i]=${reasonForRefusalIds[i]}';
      }
    }
    if (directoryValues != null && directoryValues.isNotEmpty) {
      final Map<String, LinkedHashSet<String>> groupedDirectoryValues = {};

      for (final dynamic rawValue in directoryValues) {
        if (rawValue is! Map) {
          continue;
        }

        final Map value = rawValue;
        final directoryIdRaw = value['directory_id'];
        final entryIdRaw = value['entry_id'];

        if (directoryIdRaw == null || entryIdRaw == null) {
          continue;
        }

        final directoryId = directoryIdRaw.toString();
        final Iterable<String> entryIds = entryIdRaw is List
            ? entryIdRaw
                .where((entry) => entry != null && entry.toString().isNotEmpty)
                .map((entry) => entry.toString())
            : [entryIdRaw.toString()];

        if (entryIds.isEmpty) {
          continue;
        }

        final entries = groupedDirectoryValues.putIfAbsent(
          directoryId,
          () => LinkedHashSet<String>(),
        );
        entries.addAll(entryIds);
      }

      if (groupedDirectoryValues.isNotEmpty) {
        var directoryIndex = 0;
        groupedDirectoryValues.forEach((directoryId, entryIds) {
          if (entryIds.isEmpty) {
            return;
          }
          path +=
              '&directory_values[$directoryIndex][directory_id]=$directoryId';

          var entryIndex = 0;
          for (final entryId in entryIds) {
            path +=
                '&directory_values[$directoryIndex][entry_id][$entryIndex]=$entryId';
            entryIndex++;
          }

          directoryIndex++;
        });
      }
    }

    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        final effectiveTaskStatusId = taskStatusId ?? statuses ?? -1;
        return (data['result']['data'] as List)
            .map((json) => Task.fromJson(json, effectiveTaskStatusId))
            .toList();
      } else {
        throw Exception('Нет данных о задачах в ответе');
      }
    } else {
      ////debugPrint('Error response! - ${response.body}');
      throw Exception('Ошибка загрузки задач!');
    }
  }

  Future<List<TaskStatus>> getTaskStatuses({
    List<int>? users,
    int? statuses,
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
    int? projectId,
    List<String>? authors,
    String? department,
    List<int>? reasonForRefusalIds,
    List<Map<String, dynamic>>? directoryValues,
    bool bypassCache = false,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    if (kDebugMode) {
      debugPrint('🔍 getTaskStatuses - START WITH FILTERS');
      debugPrint('🔍 getTaskStatuses - organizationId: $organizationId');
      debugPrint('🔍 getTaskStatuses - bypassCache: $bypassCache');
    }

    try {
      String path = projectId == null
          ? '/task-status'
          : '/task-status/get-by-project/$projectId';
      path = await _appendQueryParams(path);

      // Добавляем фильтры к запросу статусов
      if (users != null && users.isNotEmpty) {
        for (int i = 0; i < users.length; i++) {
          path += '&users[$i]=${users[i]}';
        }
      }
      if (statuses != null) {
        path += '&task_status_id=$statuses';
      }
      if (fromDate != null && toDate != null) {
        final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
        final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
        path += '&from=$formattedFromDate&to=$formattedToDate';
      }
      if (overdue == true) path += '&overdue=1';
      if (hasFile == true) path += '&hasFile=1';
      if (hasDeal == true) path += '&hasDeal=1';
      if (urgent == true) path += '&urgent=1';
      if (deadlinefromDate != null && deadlinetoDate != null) {
        final formattedDeadlineFrom =
            DateFormat('yyyy-MM-dd').format(deadlinefromDate);
        final formattedDeadlineTo =
            DateFormat('yyyy-MM-dd').format(deadlinetoDate);
        path +=
            '&deadline_from=$formattedDeadlineFrom&deadline_to=$formattedDeadlineTo';
      }
      if (completedFromDate != null && completedToDate != null) {
        final formattedCompletedFrom =
            DateFormat('yyyy-MM-dd').format(completedFromDate);
        final formattedCompletedTo =
            DateFormat('yyyy-MM-dd').format(completedToDate);
        path +=
            '&completed_from=$formattedCompletedFrom&completed_to=$formattedCompletedTo';
      }
      if (projectIds != null && projectIds.isNotEmpty) {
        for (int i = 0; i < projectIds.length; i++) {
          path += '&project_ids[$i]=${projectIds[i]}';
        }
      }
      if (authors != null && authors.isNotEmpty) {
        for (int i = 0; i < authors.length; i++) {
          path += '&authors[$i]=${Uri.encodeQueryComponent(authors[i])}';
        }
      }
      if (department != null && department.isNotEmpty) {
        path += '&department=${Uri.encodeQueryComponent(department)}';
      }
      if (reasonForRefusalIds != null && reasonForRefusalIds.isNotEmpty) {
        for (int i = 0; i < reasonForRefusalIds.length; i++) {
          path += '&reason_for_refusals[$i]=${reasonForRefusalIds[i]}';
        }
      }
      if (directoryValues != null && directoryValues.isNotEmpty) {
        for (int i = 0; i < directoryValues.length; i++) {
          final directoryId = directoryValues[i]['directory_id'];
          final entryId = directoryValues[i]['entry_id'];
          path += '&directory_values[$i][directory_id]=$directoryId';
          path += '&directory_values[$i][entry_id]=$entryId';
        }
      }

      if (kDebugMode) {
        debugPrint(
            '📤 getTaskStatuses projectId=$projectId - Final path: $path');
      }

      // Статусы конкретного проекта не должны смешиваться с аналитическим
      // кэшем общего экрана задач.
      final response = projectId != null
          ? await _getRequest(path)
          : await _analyticsRequest(path, bypassCache: bypassCache);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic>? statusList;

        if (data is List) {
          statusList = data;
        } else if (data is Map) {
          if (data['result'] != null) {
            statusList = data['result'] as List;
          } else if (data['data'] != null) {
            statusList = data['data'] as List;
          } else if (data['statuses'] != null) {
            statusList = data['statuses'] as List;
          }
        }

        if (statusList != null && statusList.isNotEmpty) {
          if (projectId == null) {
            await prefs.setString(
                'cachedTaskStatuses_$organizationId', json.encode(statusList));
          }

          final statuses =
              statusList.map((status) => TaskStatus.fromJson(status)).toList();

          if (kDebugMode) {
            debugPrint(
                '✅ getTaskStatuses WITH FILTERS - Got ${statuses.length} statuses');
          }

          return statuses;
        } else {
          throw Exception('Результат отсутствует в ответе или пустой');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ getTaskStatuses WITH FILTERS - request failed: $e');
      }

      if (projectId != null || bypassCache) {
        if (kDebugMode) {
          debugPrint(
              '🛑 getTaskStatuses - skip persistent fallback cache for project or bypass request');
        }
        rethrow;
      }

      ////debugPrint('Ошибка загрузки статусов задач. Используем кэшированные данные.');
      // Если запрос не удался, пытаемся загрузить данные из кэша
      final cachedStatuses =
          prefs.getString('cachedTaskStatuses_$organizationId');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => TaskStatus.fromJson(status))
            .toList();
        return cachedList;
      } else {
        throw Exception(
            'Ошибка загрузки статусов задач и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasTasks(int taskStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<Task> tasks =
          await getTasks(taskStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return tasks.isNotEmpty;
    } catch (e) {
      ////debugPrint('Error while checking if status has deals!');
      return false;
    }
  }

  Future<void> updateTaskStatus(
    int taskId,
    int position,
    int statusId, {
    int? reasonForRefusalId,
    String? reasonForRefusal,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/changeStatus/$taskId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateTaskStatus - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'position': 1,
      'status_id': statusId,
      if (reasonForRefusalId != null)
        'reason_for_refusal_id': reasonForRefusalId,
      if (reasonForRefusal != null && reasonForRefusal.trim().isNotEmpty)
        'reason_for_refusal': reasonForRefusal.trim(),
    });

    if (response.statusCode == 200) {
      ////debugPrint('Статус задачи успешно обновлен');
    } else if (response.statusCode == 422) {
      // ПАРСИМ JSON ОТВЕТ ОТ СЕРВЕРА
      final jsonResponse = json.decode(response.body);
      // БЕРЁМ message ИЗ ОТВЕТА СЕРВЕРА
      final errorMessage = jsonResponse['message'] ??
          'Вы не можете переместить задачу на этот статус';
      throw TaskStatusUpdateException(422, errorMessage);
    } else {
      throw Exception('Ошибка обновления задач сделки!');
    }
  }

  Map<String, dynamic> _handleTaskResponse(
      http.Response response, String operation) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      // Проверяем наличие ошибок в ответе
      if (data['errors'] != null) {
        return {
          'success': false,
          'message': 'Ошибка ${operation} задачи: ${data['errors']}',
        };
      }

      return {
        'success': true,
        'message':
            'Задача ${operation == 'создания' ? 'создана' : 'обновлена'} успешно.',
        'data': data['result'],
      };
    }

    if (response.statusCode == 422) {
      final data = json.decode(response.body);
      final validationErrors = {
        'name': 'Название задачи должно содержать минимум 3 символа.',
        'from': 'Неверный формат даты начала.',
        'to': 'Неверный формат даты окончания.',
        'project_id': 'Указанный проект не существует.',
        'user_id': 'Указанный пользователь не существует.',
        // Убрана валидация файла
      };

      // Игнорируем ошибки валидации файла
      if (data['errors']?['file'] != null) {
        data['errors'].remove('file');
      }

      // Проверяем каждое поле на наличие ошибки, кроме файла
      for (var entry in validationErrors.entries) {
        if (data['errors']?[entry.key] != null) {
          return {'success': false, 'message': entry.value};
        }
      }

      // Если остались только ошибки файла, считаем что валидация прошла успешно
      if (data['errors']?.isEmpty ?? true) {
        return {
          'success': true,
          'message':
              'Задача ${operation == 'создания' ? 'создана' : 'обновлена'} успешно.',
        };
      }

      return {
        'success': false,
        'message': 'Ошибка валидации: ${data['errors'] ?? response.body}',
      };
    }

    return {
      'success': false,
      'message': 'Ошибка ${operation} задачи!',
    };
  }

  Exception _handleErrorResponse(http.Response response, String operation) {
    try {
      final data = json.decode(response.body);
      final errorMessage = data['errors'] ?? data['message'] ?? response.body;
      return Exception('Ошибка ${operation}! - $errorMessage');
    } catch (e) {
      return Exception('Ошибка ${operation}! - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> CreateTaskStatusAdd({
    required int taskStatusNameId,
    required int projectId,
    required bool needsPermission,
    List<int>? roleIds,
    bool? finalStep,
    bool isUnassembled = false,
  }) async {
    try {
      // Формируем данные для запроса
      final Map<String, dynamic> data = {
        'task_status_name_id': taskStatusNameId,
        'project_id': projectId,
        'needs_permission': needsPermission ? 1 : 0,
      };

      // Добавляем final_step, если оно не null
      if (finalStep != null) {
        data['final_step'] = finalStep;
      }
      data['is_unassembled'] = isUnassembled;

      // Обрабатываем список ролей, если он существует
      if (roleIds != null && roleIds.isNotEmpty) {
        data['roles'] = roleIds.map((roleId) => {'role_id': roleId}).toList();
      }

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task-status');
      if (kDebugMode) {
        //debugPrint('ApiService: CreateTaskStatusAdd - Generated path: $path');
      }

      // Выполняем запрос
      final response = await _postRequest(path, data);

      // Проверяем статус ответа
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Статус задачи успешно создан',
          'data': responseData,
        };
      }

      // Обрабатываем различные коды ошибок
      String errorMessage;
      switch (response.statusCode) {
        case 400:
          errorMessage = 'Неверные данные запроса';
          break;
        case 401:
          errorMessage = 'Необходима авторизация';
          break;
        case 403:
          errorMessage = 'Недостаточно прав для создания статуса';
          break;
        case 404:
          errorMessage = 'Ресурс не найден';
          break;
        case 409:
          errorMessage = 'Конфликт при создании статуса';
          break;
        case 500:
          errorMessage = 'Внутренняя ошибка сервера';
          break;
        default:
          errorMessage = 'Произошла ошибка при создании статуса';
      }

      return {
        'success': false,
        'message': '$errorMessage!',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при выполнении запроса!',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> createTask({
    required String name,
    required int? statusId,
    required int? taskStatusId,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? projectId,
    List<int>? userId,
    String? description,
    List<Map<String, dynamic>>? customFields,
    List<FileHelper>? files,
    List<Map<String, int>>? directoryValues,
    int position = 1,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task');
      if (kDebugMode) {
        //debugPrint('ApiService: createTask - Generated path: $path');
      }
      var uri = Uri.parse('$baseUrl$path');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;
      request.fields['status_id'] = statusId.toString();
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['position'] = position.toString();
      request.fields['organization_id'] =
          (await getSelectedOrganization()).toString();

      if (priority != null) {
        request.fields['priority_level'] = priority.toString();
      }
      if (startDate != null) {
        request.fields['from'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        request.fields['to'] = DateFormat('yyyy-MM-dd').format(endDate);
      }
      if (projectId != null) {
        request.fields['project_id'] = projectId.toString();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      if (userId != null && userId.isNotEmpty) {
        for (int i = 0; i < userId.length; i++) {
          request.fields['users[$i][user_id]'] = userId[i].toString();
        }
      }

      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['custom_fields[$i][key]'] = field['key'] ?? '';
          request.fields['custom_fields[$i][value]'] = field['value'] ?? '';
          request.fields['custom_fields[$i][type]'] = field['type'] ?? 'string';
        }
      }

      if (directoryValues != null && directoryValues.isNotEmpty) {
        for (int i = 0; i < directoryValues.length; i++) {
          var directoryValue = directoryValues[i];
          request.fields['directory_values[$i][entry_id]'] =
              directoryValue['entry_id'].toString();
          request.fields['directory_values[$i][directory_id]'] =
              directoryValue['directory_id'].toString();
        }
      }

      // Отправляем файлы (все файлы при создании новые, id == 0)
      if (files != null && files.isNotEmpty) {
        final newFiles = files.where((f) => f.id == 0).toList();
        for (var fileData in newFiles) {
          try {
            final file = await http.MultipartFile.fromPath(
              'files[]',
              fileData.path,
              filename: fileData.name,
            );
            request.files.add(file);
          } catch (e) {
            debugPrint("Error adding file ${fileData.name}: $e");
          }
        }
      }

      final response = await _multipartPostRequest('', request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'task_create_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'error_start_date_task',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'error_end_date_task',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'error_priority_level',
          };
        }
        if (response.body.contains('directory_values')) {
          return {
            'success': false,
            'message': 'error_directory_values',
          };
        }
        if (response.body.contains('type')) {
          return {
            'success': false,
            'message': 'invalid_field_type',
          };
        }
        if (response.body.contains('task_custom_fields')) {
          return {
            'success': false,
            'message': 'invalid_task_custom_fields',
          };
        }
        return {
          'success': false,
          'message': 'unknown_error',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        return {
          'success': false,
          'message': 'error_create_task',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_create_task',
      };
    }
  }

  Future<Map<String, dynamic>> updateTask({
    required int taskId,
    required String name,
    required int taskStatusId,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? projectId,
    List<int>? userId,
    String? description,
    List<String>? filePaths,
    List<Map<String, dynamic>>? customFields,
    List<TaskFiles>? existingFiles,
    List<Map<String, int>>? directoryValues,
    int? reasonForRefusalId,
    String? reasonForRefusal,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task/$taskId');
      if (kDebugMode) {
        //debugPrint('ApiService: updateTask - Generated path: $path');
      }
      var uri = Uri.parse('$baseUrl$path');

      // Создаем multipart request
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем все поля в формате form-data
      request.fields['name'] = name;
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['_method'] = 'POST'; // Для эмуляции PUT запроса

      if (priority != null) {
        request.fields['priority_level'] = priority;
      }
      if (startDate != null) {
        request.fields['from'] = startDate.toString().split(' ')[0];
      }
      if (endDate != null) {
        request.fields['to'] = endDate.toString().split(' ')[0];
      }

      if (projectId != null) {
        request.fields['project_id'] = projectId.toString();
      }
      if (description != null) {
        request.fields['description'] = description;
      }
      if (reasonForRefusalId != null) {
        request.fields['reason_for_refusal_id'] = reasonForRefusalId.toString();
      }
      if (reasonForRefusal != null && reasonForRefusal.trim().isNotEmpty) {
        request.fields['reason_for_refusal'] = reasonForRefusal.trim();
      }

      // Добавляем пользователей
      if (userId != null && userId.isNotEmpty) {
        for (int i = 0; i < userId.length; i++) {
          request.fields['users[$i][user_id]'] = userId[i].toString();
        }
      }

      // Добавляем кастомные поля
      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['custom_fields[$i][key]'] = field['key']!.toString();
          request.fields['custom_fields[$i][value]'] =
              field['value']!.toString();
          request.fields['custom_fields[$i][type]'] =
              field['type']?.toString() ?? 'string';
        }
      }

      // Добавляем ID существующих файлов
      if (existingFiles != null && existingFiles.isNotEmpty) {
        for (int i = 0; i < existingFiles.length; i++) {
          request.fields['existing_files[$i]'] = existingFiles[i].id.toString();
        }
      }
      if (directoryValues != null && directoryValues.isNotEmpty) {
        directoryValues.asMap().forEach((i, value) {
          request.fields['directory_values[$i][entry_id]'] =
              value['entry_id'].toString();
          request.fields['directory_values[$i][directory_id]'] =
              value['directory_id'].toString();
        });
      }
      // Добавляем новые файлы
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }
      // Отправляем запрос
      final response = await _multipartPostRequest('', request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'task_update_successfully',
        };
      } else if (response.statusCode == 422) {
        ////debugPrint('Server Response: ${response.body}'); // Добавим для отладки

        // Обработка ошибок валидации
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'error_start_date_task',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'error_end_date_task',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'error_priority_level',
          };
        }
        return {
          'success': false,
          'message': 'unknown_error',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        ////debugPrint('Server Response: ${response.body}'); // Добавим для отладки

        return {
          'success': false,
          'message': 'error_task_update_successfully',
        };
      }
    } catch (e) {
      ////debugPrint('Update Task Error: $e'); // Добавим для отладки

      return {
        'success': false,
        'message': 'error_task_update_successfully',
      };
    }
  }

  Future<List<TaskHistory>> getTaskHistory(int taskId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task/history/$taskId');
      if (kDebugMode) {
        //debugPrint('ApiService: getTaskHistory - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => TaskHistory.fromJson(json)).toList();
      } else {
        ////debugPrint('Failed to load task history!');
        throw Exception('Ошибка загрузки истории задач!');
      }
    } catch (e) {
      ////debugPrint('Error occurred!');
      throw Exception('Ошибка загрузки истории задач!');
    }
  }

  /// Получить историю выполнения задачи (overdue history)
  /// GET /api/task/overdue-history/{taskId}?organization_id=1&sales_funnel_id=1
  Future<TaskOverdueHistoryResponse?> getTaskOverdueHistory(int taskId) async {
    try {
      final path = await _appendQueryParams('/task/overdue-history/$taskId');
      if (kDebugMode) {
        debugPrint('ApiService: getTaskOverdueHistory - Path: $path');
      }

      final response = await _analyticsRequest(path);

      if (kDebugMode) {
        debugPrint(
            'ApiService: getTaskOverdueHistory - Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final historyResponse = TaskOverdueHistoryResponse.fromJson(data);

        if (kDebugMode) {
          debugPrint(
              'ApiService: История выполнения получена - ${historyResponse.result?.length ?? 0} записей');
        }

        return historyResponse;
      } else {
        if (kDebugMode) {
          debugPrint(
              'ApiService: Ошибка получения истории выполнения: ${response.statusCode}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            'ApiService: Исключение при получении истории выполнения: $e');
        debugPrint('ApiService: StackTrace: $stackTrace');
      }
      return null;
    }
  }

  Future<ProjectsDataResponse> getAllProject({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path =
        await _appendQueryParams('/project?page=$page&per_page=$perPage');
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (kDebugMode) {
      //debugPrint('ApiService: getAllProject - Generated path: $path');
    }

    final response = await _getRequest(path);

    late ProjectsDataResponse dataProject;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataProject = ProjectsDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {}

    return dataProject;
  }

  Future<Map<String, dynamic>> createProject({
    required String name,
    String? startDate,
    String? endDate,
    int? statusId,
  }) async {
    final response = await _postRequest('/project', {
      'name': name,
      if (startDate?.isNotEmpty ?? false) 'start_date': startDate,
      if (endDate?.isNotEmpty ?? false) 'end_date': endDate,
      if (statusId != null) 'status_id': statusId,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': json.decode(response.body)};
    }
    return {'success': false, 'message': 'Ошибка создания проекта'};
  }

  Future<Map<String, dynamic>> updateProject({
    required int projectId,
    required String name,
    String? startDate,
    String? endDate,
    int? statusId,
  }) async {
    final response = await _patchRequest('/project/$projectId', {
      'name': name,
      if (startDate?.isNotEmpty ?? false) 'start_date': startDate,
      if (endDate?.isNotEmpty ?? false) 'end_date': endDate,
      if (statusId != null) 'status_id': statusId,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': json.decode(response.body)};
    }
    return {'success': false, 'message': 'Ошибка обновления проекта'};
  }

  Future<Map<String, dynamic>> deleteProject(int projectId) async {
    final response = await _deleteRequest('/project/$projectId');
    if (response.statusCode == 200 || response.statusCode == 204) {
      return {'success': true};
    }
    return {'success': false, 'message': 'Ошибка удаления проекта'};
  }

  Future<ProjectTaskDataResponse> getTaskProject({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    // Формируем базовый путь с параметрами пагинации
    String path = '/task/get/projects?page=$page&per_page=$perPage';
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      debugPrint('ApiService: getTaskProject - Generated path: $path');
    }

    final response = await _getRequest(path);

    late ProjectTaskDataResponse dataProject;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataProject = ProjectTaskDataResponse.fromJson(data);
      } else {
        throw ('Результат отсутствует в ответе');
      }
    } else if (response.statusCode == 404) {
      throw ('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw ('Внутренняя ошибка сервера');
    } else {
      throw ('Ошибка при получении данных!');
    }

    if (kDebugMode) {
      // ////debugPrint('getAll project!');
    }

    return dataProject;
  }

  Future<List<Role>> getRoles() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/role');
    if (kDebugMode) {
      //debugPrint('ApiService: getRoles - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((role) => Role.fromJson(role))
            .toList();
      } else {
        throw Exception('Роли не найдены');
      }
    } else {
      throw Exception('Ошибка при получении ролей!');
    }
  }

  Future<List<StatusName>> getStatusName() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/taskStatusName');
    if (kDebugMode) {
      //debugPrint('ApiService: getStatusName - Generated path: $path');
    }

    ////debugPrint('Начало запроса статусов задач'); // Отладочный вывод
    final response = await _getRequest(path);
    ////debugPrint('Статус код ответа!'); // Отладочный вывод

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные: $data'); // Отладочный вывод

      if (data['result'] != null) {
        final statusList = (data['result'] as List)
            .map((name) => StatusName.fromJson(name))
            .toList();
        ////debugPrint(
        // 'Преобразованный список статусов: $statusList'); // Отладочный вывод
        return statusList;
      } else {
        throw Exception('Статусы задач не найдены');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<Map<String, dynamic>> deleteTask(int taskId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/$taskId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteTask - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete task!');
    }
  }

  Future<Map<String, dynamic>> deleteTaskStatuses(int taskStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task-status/$taskStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteTaskStatuses - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete taskStatus!');
    }
  }

  Future<Map<String, dynamic>> finishTask(int taskId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/finish');
    if (kDebugMode) {
      //debugPrint('ApiService: finishTask - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'task_id': taskId,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Задача успешно завершена'};
    } else if (response.statusCode == 422) {
      try {
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ??
            'Неизвестная ошибка при завершении задачи';
        return {
          'success': false,
          'message': errorMessage,
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Ошибка обработки ответа сервера',
        };
      }
    } else {
      return {'success': false, 'message': 'Ошибка завершения задачи!'};
    }
  }

  Future<TaskStatus> getTaskStatus(int taskStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task-status/$taskStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: getTaskStatus - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return TaskStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

  Future<Map<String, dynamic>> updateTaskStatusEdit({
    required int taskStatusId,
    required String name,
    required bool needsPermission,
    required bool finalStep,
    required bool checkingStep,
    bool isUnassembled = false,
    required List<int> roleIds,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task-status/$taskStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateTaskStatusEdit - Generated path: $path');
    }

    final roles = roleIds.map((roleId) => {"role_id": roleId}).toList();

    final payload = {
      "task_status_name_id": taskStatusId,
      "needs_permission": needsPermission ? 1 : 0,
      "final_step": finalStep ? 1 : 0,
      "checking_step": checkingStep ? 1 : 0,
      "is_unassembled": isUnassembled,
      "roles": roles,
      "organization_id": await getSelectedOrganization(),
    };

    final response = await _patchRequest(
      path,
      payload,
    );

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update task status!');
    }
  }

  Future<Map<String, dynamic>> deleteTaskFile(int fileId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/deleteFile/$fileId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteTaskFile - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete task file!');
    }
  }

  Future<List<Department>> getDepartments() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/department');
    if (kDebugMode) {
      //debugPrint('ApiService: getDepartments - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result']; // Извлекаем массив из ключа "result"
      ////debugPrint('Полученные данные отделов: $result');
      return (result as List)
          .map((department) => Department.fromJson(department))
          .toList();
    } else {
      throw Exception('Ошибка загрузки отделов');
    }
  }

  Future<DirectoryDataResponse> getDirectory() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/directory');
    if (kDebugMode) {
      //debugPrint('ApiService: getDirectory - Generated path: $path');
    }

    final response = await _getRequest(path);

    late DirectoryDataResponse dataDirectory;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataDirectory = DirectoryDataResponse.fromJson(data);
      } else {
        throw ('Результат отсутствует в ответе');
      }
    } else if (response.statusCode == 404) {
      throw ('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw ('Внутренняя ошибка сервера');
    } else {
      throw ('Ошибка при получении данных!');
    }

    if (kDebugMode) {
      ////debugPrint('getAll directory!');
    }

    return dataDirectory;
  }

  Future<void> linkDirectory({
    required int directoryId,
    required String modelType,
    required String organizationId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/directoryLink');
    if (kDebugMode) {
      //debugPrint('ApiService: linkDirectory - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        'directory_id': directoryId,
        'model_type': modelType,
        'organization_id': organizationId,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ('Ошибка при связывании справочника: ${response.statusCode}');
    }

    if (kDebugMode) {
      ////debugPrint('Directory linked successfully!');
    }
  }

  Future<DirectoryLinkResponse> getTaskDirectoryLinks() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/directoryLink/task');
    if (kDebugMode) {
      //debugPrint('ApiService: getTaskDirectoryLinks - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        return DirectoryLinkResponse.fromJson(data);
      } else {
        throw Exception('Данные отсутствуют в ответе');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw Exception('Внутренняя ошибка сервера');
    } else {
      throw Exception('Ошибка при получении связанных справочников!');
    }
  }

  Future<OverdueTasksResponse> getUsersOverdueTaskData(
      {required int userId}) async {
    // Use _appendQueryParams to include organization_id, etc.
    final path =
        await _appendQueryParams('/dashboard/user/$userId/overdue-tasks');

    if (kDebugMode) {
      // debugPrint('ApiService: getUserOverdueTasksData - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['result'] != null) {
        return OverdueTasksResponse.fromJson(data);
      } else {
        throw ('Нет данных в ответе "Просроченные задачи"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Ошибка загрузки данных "Просроченные задачи"!');
    }
  }

  Future<TaskProfile> getTaskProfile(int chatId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task/getByChat/$chatId');
      if (kDebugMode) {
        //debugPrint('ApiService: getTaskProfile - Generated path: $path');
      }

      ////debugPrint('Organization ID: $organizationId'); // Добавим логирование

      final response = await _getRequest(path);

      ////debugPrint('Response status code!'); // Логируем статус ответа
      ////debugPrint('Response body!'); // Логируем тело ответа

      if (response.statusCode == 200) {
        try {
          final dynamic decodedJson = json.decode(response.body);
          ////debugPrint(
          // 'Decoded JSON type: ${decodedJson.runtimeType}'); // Логируем тип декодированного JSON
          ////debugPrint('Decoded JSON: $decodedJson'); // Отладочный вывод

          if (decodedJson is Map<String, dynamic>) {
            if (decodedJson['result'] != null) {
              ////debugPrint(
              // 'Result type: ${decodedJson['result'].runtimeType}'); // Логируем тип результата
              return TaskProfile.fromJson(decodedJson['result']);
            } else {
              ////debugPrint('Result is null');
              throw Exception('Данные задачи не найдены');
            }
          } else {
            ////debugPrint('Decoded JSON is not a Map: ${decodedJson.runtimeType}');
            throw Exception('Неверный формат ответа');
          }
        } catch (parseError) {
          ////debugPrint('Ошибка парсинга JSON: $parseError');
          throw Exception('Ошибка парсинга ответа: $parseError');
        }
      } else {
        ////debugPrint('Ошибка загрузки задачи!');
        throw Exception('Ошибка загрузки задачи!');
      }
    } catch (e) {
      ////debugPrint('Полная ошибка в getTaskProfile!');
      ////debugPrint('Трассировка стека: ${StackTrace.current}');
      throw Exception('Ошибка загрузки задачи!');
    }
  } // Упрощённый метод для получения интеграции лида (теперь не нужен отдельный класс IntegrationForLead)

  Future<bool> checkOverdueTasks() async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task/check/overdue');
      if (kDebugMode) {
        //debugPrint('ApiService: checkOverdueTasks - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        return decodedJson['res'] ?? false;
      } else {
        throw Exception('Failed to check overdue tasks');
      }
    } catch (e) {
      throw Exception('Error checking overdue tasks');
    }
  }

  Future<List<String>> getTaskCustomFields() async {
    final path = await _appendQueryParams('/field-position?table=tasks');

    if (kDebugMode) {
      debugPrint('ApiService: getTaskCustomFields - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List<dynamic>?;
      final ls = resultList
              ?.where((e) => e['is_custom_field'] == true)
              .map((e) => e['field_name'] as String)
              .toList() ??
          <String>[];

      if (kDebugMode) {
        debugPrint(
            'ApiService: getTaskCustomFields - Response status: ${response.statusCode}');
        debugPrint('ApiService: getTaskCustomFields - Response ls: $ls');
      }

      return ls;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка загрузки пользовательских полей задач',
        response.statusCode,
      );
    }
  }

  Future<List<String>> getTaskCustomFieldValues(String key) async {
    final path =
        await _appendQueryParams('/task/get/custom-field-values?key=$key');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getTaskCustomFieldValues - Generated path: $path');
    }
    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList.map((value) => value.toString()).toList();
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка загрузки значений пользовательского поля задач',
        response.statusCode,
      );
    }
  }
}
