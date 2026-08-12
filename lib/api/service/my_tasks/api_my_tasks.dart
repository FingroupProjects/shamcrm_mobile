part of '../api_service.dart';

extension ApiMyTasksX on ApiService {
  Future<MyTaskById> getMyTaskById(int taskId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task/$taskId');
      if (kDebugMode) {
        //debugPrint('ApiService: getMyTaskById - Generated path: $path');
      }

      final response = await _getRequest(path);

      ////debugPrint('Response status code: ${response.statusCode}');
      ////debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? result = decodedJson['result'];

        if (result == null) {
          throw ('Некорректные данные от API: result is null');
        }

        return MyTaskById.fromJson(result, 0);
      } else {
        throw ('HTTP Error');
      }
    } catch (e) {
      ////debugPrint('Error in getMyTaskById: $e');
      throw ('Ошибка загрузки task ID');
    }
  }

  Future<List<MyTask>> getMyTasks(
    int? taskStatusId, {
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    // Формируем базовый путь
    String path = '/my-task?page=$page&per_page=$perPage';

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    } else if (taskStatusId != null) {
      // Условие: если нет userId
      path += '&task_status_id=$taskStatusId';
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getMyTasks - Generated path: $path');
    }

    // Логируем конечный URL запроса
    // ////debugPrint('Sending request to API with path: $path');
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => MyTask.fromJson(json, taskStatusId ?? -1))
            .toList();
      } else {
        throw Exception('Нет данных о задачах в ответе');
      }
    } else {
      // Логирование ошибки с ответом сервера
      ////debugPrint('Error response! - ${response.body}');
      throw Exception('Ошибка загрузки задач!');
    }
  }

  Future<List<MyTaskStatus>> getMyTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task-status');
      if (kDebugMode) {
        //debugPrint('ApiService: getMyTaskStatuses - Generated path: $path');
      }

      // Отправляем запрос на сервер
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          // Принт старых кэшированных данных (если они есть)
          final cachedStatuses = prefs.getString(
              'cachedMyTaskStatuses_${await getSelectedOrganization()}');
          if (cachedStatuses != null) {
            final decodedData = json.decode(cachedStatuses);
          }

          // Обновляем кэш новыми данными
          await prefs.setString(
              'cachedMyTaskStatuses_${await getSelectedOrganization()}',
              json.encode(data['result']));
          // ////debugPrint(
          //     '------------------------------------ Новые данные, которые сохраняются в кэш ---------------------------------');
          // ////debugPrint(data['result']); // Новые данные, которые будут сохранены в кэш

          return (data['result'] as List)
              .map((status) => MyTaskStatus.fromJson(status))
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      ////debugPrint('Ошибка загрузки статусов задач. Используем кэшированные данные.');
      // Если запрос не удался, пытаемся загрузить данные из кэша
      final cachedStatuses = prefs
          .getString('cachedMyTaskStatuses_${await getSelectedOrganization()}');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => MyTaskStatus.fromJson(status))
            .toList();
        return cachedList;
      } else {
        throw Exception(
            'Ошибка загрузки статусов задач и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasMyTasks(int taskStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<MyTask> tasks =
          await getMyTasks(taskStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return tasks.isNotEmpty;
    } catch (e) {
      ////debugPrint('Error while checking if status has deals!');
      return false;
    }
  }

  Future<void> updateMyTaskStatus(
      int taskId, int position, int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task/change-status/$taskId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateMyTaskStatus - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'position': 1,
      'status_id': statusId,
    });

    if (response.statusCode == 200) {
      ////debugPrint('Статус задачи успешно обновлен');
    } else if (response.statusCode == 422) {
      throw MyTaskStatusUpdateException(
          422, 'Вы не можете переместить задачу на этот статус');
    } else {
      throw Exception('Ошибка обновления задач сделки!');
    }
  }

  Map<String, dynamic> _handleMyTaskResponse(
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

  Future<Map<String, dynamic>> CreateMyTaskStatusAdd({
    required String statusName,
    bool? finalStep,
  }) async {
    try {
      // Формируем данные для запроса
      final Map<String, dynamic> data = {
        'title': statusName,
        'color': "#000",
      };
      if (finalStep != null) {
        data['final_step'] = finalStep;
      }

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task-status');
      if (kDebugMode) {
        //debugPrint('ApiService: CreateMyTaskStatusAdd - Generated path: $path');
      }

      // Выполняем запрос
      final response = await _postRequest(path, data);

      // Проверяем успешность запроса
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Статус задачи успешно создан',
          'data': responseData,
        };
      }

      // Получаем текст ошибки в зависимости от кода ответа
      final errorMessage = _getErrorMessage(response.statusCode);

      return {
        'success': false,
        'message': errorMessage,
        'statusCode': response.statusCode,
        'details': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при создании статуса',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> createMyTask({
    required String name,
    required int? statusId,
    required int? taskStatusId,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    List<String>? filePaths,
    int position = 1,
    required bool setPush,
    List<Map<String, dynamic>>? customFields,
    List<Map<String, int>>? directoryValues,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task');
      if (kDebugMode) {
        //debugPrint('ApiService: createMyTask - Generated path: $path');
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
      request.fields['status_id'] = statusId.toString();
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['position'] = position.toString();
      request.fields['send_notification'] = setPush ? '1' : '0';

      if (startDate != null) {
        request.fields['from'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        request.fields['to'] = endDate.toIso8601String();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      // Добавляем файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath(
              'files[]', filePath); // Используем 'files[]'
          request.files.add(file);
        }
      }

      // Добавляем кастомные поля
      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          final field = customFields[i];
          request.fields['custom_fields[$i][key]'] = field['key'].toString();
          request.fields['custom_fields[$i][value]'] =
              field['value'].toString();
          request.fields['custom_fields[$i][type]'] = field['type'].toString();
        }
      }

      // Добавляем справочники
      if (directoryValues != null && directoryValues.isNotEmpty) {
        for (int i = 0; i < directoryValues.length; i++) {
          final directory = directoryValues[i];
          request.fields['directories[$i][directory_id]'] =
              directory['directory_id'].toString();
          request.fields['directories[$i][entry_id]'] =
              directory['entry_id'].toString();
        }
      }

      // Отправляем запрос
      final response = await _multipartPostRequest('', request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Задача успешно создана',
          'data': responseData,
        };
      } else {
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
            errorMessage = 'Недостаточно прав для создания задачи';
            break;
          case 404:
            errorMessage = 'Ресурс не найден';
            break;
          case 409:
            errorMessage = 'Конфликт при создании задачи';
            break;
          case 500:
            errorMessage = 'Внутренняя ошибка сервера';
            break;
          default:
            errorMessage = 'Произошла ошибка при создании задачи';
        }
        return {
          'success': false,
          'message': '$errorMessage!',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      ////debugPrint('Detailed error: $e');
      return {
        'success': false,
        'message': 'Ошибка при выполнении запроса!',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateMyTask({
    required int taskId,
    required String name,
    required int? taskStatusId,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    List<String>? filePaths,
    required bool setPush,
    List<MyTaskFiles>? existingFiles,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task/$taskId');
      if (kDebugMode) {
        //debugPrint('ApiService: updateMyTask - Generated path: $path');
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
      request.fields['send_notification'] = setPush ? '1' : '0';

      if (endDate != null) {
        request.fields['to'] =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      // Добавляем новые файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }

      // Добавляем информацию о существующих файлах
      if (existingFiles != null && existingFiles.isNotEmpty) {
        List<Map<String, dynamic>> existingFilesList = existingFiles
            .map(
                (file) => {'id': file.id, 'name': file.name, 'path': file.path})
            .toList();

        request.fields['existing_files'] = json.encode(existingFilesList);
      }

      // Отправляем запрос
      final response = await _multipartPostRequest('', request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Задача успешно обновлена',
          'data': responseData,
        };
      } else {
        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage = 'Неверные данные запроса';
            break;
          case 401:
            errorMessage = 'Необходима авторизация';
            break;
          case 403:
            errorMessage = 'Недостаточно прав для обновления задачи';
            break;
          case 404:
            errorMessage = 'Ресурс не найден';
            break;
          case 409:
            errorMessage = 'Конфликт при обновлении задачи';
            break;
          case 500:
            errorMessage = 'Внутренняя ошибка сервера';
            break;
          default:
            errorMessage = 'Произошла ошибка при обновлении задачи';
        }
        return {
          'success': false,
          'message': '$errorMessage!',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      ////debugPrint('Detailed error: $e');
      return {
        'success': false,
        'message': 'Ошибка при выполнении запроса!',
        'error': e.toString(),
      };
    }
  }

  Future<List<MyTaskHistory>> getMyTaskHistory(int taskId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task/history/$taskId');
      if (kDebugMode) {
        //debugPrint('ApiService: getMyTaskHistory - Generated path: $path');
      }

      // Используем метод _getRequest вместо прямого выполнения запроса
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => MyTaskHistory.fromJson(json)).toList();
      } else {
        ////debugPrint('Failed to load task history!');
        throw Exception('Ошибка загрузки истории задач!');
      }
    } catch (e) {
      ////debugPrint('Error occurred!');
      throw Exception('Ошибка загрузки истории задач!');
    }
  }

  Future<List<MyStatusName>> getMyStatusName() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-taskStatusName');
    if (kDebugMode) {
      //debugPrint('ApiService: getMyStatusName - Generated path: $path');
    }

    ////debugPrint('Начало запроса статусов задач'); // Отладочный вывод
    final response = await _getRequest(path);
    ////debugPrint('Статус код ответа!'); // Отладочный вывод

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные: $data'); // Отладочный вывод

      if (data['result'] != null) {
        final statusList = (data['result'] as List)
            .map((name) => MyStatusName.fromJson(name))
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

  Future<Map<String, dynamic>> deleteMyTask(int taskId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task/$taskId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteMyTask - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete task!');
    }
  }

  Future<Map<String, dynamic>> deleteMyTaskStatuses(int taskStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task-status/$taskStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteMyTaskStatuses - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete taskStatus!');
    }
  }

  Future<Map<String, dynamic>> finishMyTask(int taskId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task/finish');
    if (kDebugMode) {
      //debugPrint('ApiService: finishMyTask - Generated path: $path');
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

  Future<MyTaskStatus> getMyTaskStatus(int myTaskStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task-status/$myTaskStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: getMyTaskStatus - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return MyTaskStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

  Future<Map<String, dynamic>> updateMyTaskStatusEdit(int myTaskStatusId,
      String title, bool finalStep, AppLocalizations localizations) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task-status/$myTaskStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateMyTaskStatusEdit - Generated path: $path');
    }

    final payload = {
      "title": title,
      "organization_id": await getSelectedOrganization(),
      "color": "#000",
      "final_step": finalStep ? 1 : 0, // Конвертируем bool в 1/0
    };
    final response = await _patchRequest(path, payload);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update leadStatus!');
    }
  }
}
