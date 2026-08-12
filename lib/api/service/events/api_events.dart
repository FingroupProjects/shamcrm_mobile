part of '../api_service.dart';

extension ApiEventsX on ApiService {
  Future<UserByIdProfile> getUserById(int userId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/user/$userId');
      if (kDebugMode) {
        //debugPrint('ApiService: getUserById - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonUser = decodedJson['result'];

        if (jsonUser == null) {
          throw Exception('Некорректные данные от API');
        }

        final userProfile = UserByIdProfile.fromJson(jsonUser);

        // Сохраняем unique_id в SharedPreferences
        if (userProfile.uniqueId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('unique_id', userProfile.uniqueId!);
          ////debugPrint('unique_id сохранён: ${userProfile.uniqueId}');
        } else {
          ////debugPrint('unique_id не получен от сервера');
        }

        return userProfile;
      } else {
        throw Exception('Ошибка загрузки User ID: ${response.statusCode}');
      }
    } catch (e) {
      ////debugPrint('Ошибка загрузки User ID: $e');
      throw Exception('Ошибка загрузки User ID');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    required String sname,
    required String phone,
    String? email,
    String? filePath,
  }) async {
    try {
      final token = await getToken(); // Получаем токен
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/profile/$userId');
      if (kDebugMode) {
        //debugPrint('ApiService: updateProfile - Generated path: $path');
      }

      // Создаем URL для обновления профиля
      var uri = Uri.parse('$baseUrl$path');

      // Создаем multipart запрос
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем поля
      request.fields['name'] = name;
      request.fields['lastname'] = sname;
      request.fields['phone'] = phone;

      if (email != null) {
        request.fields['email'] = email;
      }

      // Добавляем файл, если указан путь
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          final fileStream = http.ByteStream(file.openRead());
          final length = await file.length();

          final multipartFile = http.MultipartFile(
            'image', // Название поля в API, куда передается файл
            fileStream,
            length,
            filename: fileName,
          );
          request.files.add(multipartFile);
        }
      }

      // Отправляем запрос
      final response = await _multipartPostRequest('', request);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'profile_updated_successfully'};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': 'error_validation_data'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      } else if (response.statusCode == 500) {
        return {'success': false, 'message': 'error_server_text'};
      } else {
        return {'success': false, 'message': 'error_update_profile'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_update_profile',
      };
    }
  }

  Future<List<NoticeEvent>> getEvents({
    int page = 1,
    int perPage = 20,
    String? search,
    List<int>? managers,
    int? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? noticefromDate,
    DateTime? noticetoDate,
    int? salesFunnelId, // Новый параметр
  }) async {
    try {
      // Формируем базовый путь
      String path = '/notices?page=$page&per_page=$perPage';

      if (search != null && search.isNotEmpty) {
        path += '&search=$search';
      }

      if (managers != null && managers.isNotEmpty) {
        for (int i = 0; i < managers.length; i++) {
          path += '&managers[$i]=${managers[i]}';
        }
      }

      if (statuses != null) {
        path += '&event_status_id=$statuses';
        bool isFinished = statuses == 2;
        path +=
            '&isFinished=${isFinished ? '1' : '0'}'; // Передаем 1 или 0 вместо true/false
      }
      if (salesFunnelId != null) {
        path += '&sales_funnel_id=$salesFunnelId';
      }
      if (fromDate != null && toDate != null) {
        final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
        final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
        path += '&created_from=$formattedFromDate&created_to=$formattedToDate';
      }

      if (noticefromDate != null && noticetoDate != null) {
        final formattedFromDate =
            DateFormat('yyyy-MM-dd').format(noticefromDate);
        final formattedToDate = DateFormat('yyyy-MM-dd').format(noticetoDate);
        path += '&push_from=$formattedFromDate&push_to=$formattedToDate';
      }

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      path = await _appendQueryParams(path);
      if (kDebugMode) {
        //debugPrint('ApiService: getEvents - Generated path: $path');
      }

      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null && data['result']['data'] != null) {
          return (data['result']['data'] as List)
              .map((json) => NoticeEvent.fromJson(json))
              .toList();
        } else {
          throw ('Нет данных о событиях в ответе');
        }
      } else {
        throw ('Ошибка загрузки событий!');
      }
    } catch (e) {
      throw ('Ошибка загрузки событий');
    }
  }

  Future<Notice> getNoticeById(int noticeId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/notices/show/$noticeId');
      if (kDebugMode) {
        //debugPrint('ApiService: getNoticeById - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonNotice = decodedJson['result'];

        if (jsonNotice == null) {
          throw ('Некорректные данные от API');
        }

        return Notice.fromJson(jsonNotice);
      } else {
        debugPrint(
            'ApiService.getNoticeById: HTTP ${response.statusCode}, body=${response.body}');
        throw ('Ошибка загрузки notice ID!');
      }
    } catch (e) {
      debugPrint('ApiService.getNoticeById error for notice $noticeId: $e');
      throw ('Ошибка загрузки notice ID!');
    }
  }

  Future<Map<String, dynamic>> createNotice({
    String? title,
    required String body,
    required int leadId,
    DateTime? date,
    required int sendNotification,
    required int sendSms,
    required List<int> users,
    List<String>? filePaths,
  }) async {
    try {
      // Формируем путь с query-параметрами
      final path = await _appendQueryParams('/notices');
      if (kDebugMode) {
        //debugPrint('ApiService: createNotice - Generated path: $path');
      }

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));

      // Добавляем поля в запрос
      if (title != null && title.isNotEmpty) {
        request.fields['title'] = title;
      }
      request.fields['body'] = body;
      request.fields['lead_id'] = leadId.toString();
      if (date != null) {
        request.fields['date'] = DateFormat('yyyy-MM-dd HH:mm').format(date);
      }
      request.fields['send_notification'] = sendNotification.toString();
      request.fields['send_sms'] = sendSms.toString();

      // Добавляем массив users
      for (int i = 0; i < users.length; i++) {
        request.fields['users[$i]'] = users[i].toString();
      }

      // Добавляем файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }

      final response = await _multipartPostRequest(path, request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'notice_create_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('title')) {
          return {'success': false, 'message': 'invalid_title_length'};
        }
        if (response.body.contains('users')) {
          return {'success': false, 'message': 'error_users'};
        }
        return {'success': false, 'message': 'validation_error'};
      } else if (response.statusCode == 500) {
        return {'success': false, 'message': 'error_server_text'};
      } else {
        return {'success': false, 'message': 'error_notice_create'};
      }
    } catch (e) {
      return {'success': false, 'message': 'error_notice_create'};
    }
  }

  Future<Map<String, dynamic>> updateNotice({
    required int noticeId,
    String? title,
    required String body,
    required int leadId,
    int? dealId,
    DateTime? date,
    required int sendNotification,
    required int sendSms,
    required List<int> users,
    List<String>? filePaths,
    List<NoticeFiles>? existingFiles,
  }) async {
    // Формируем путь с query-параметрами
    final path = await _appendQueryParams('/notices/$noticeId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateNotice - Generated path: $path');
    }

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));

    // Добавляем поля явно
    if (title != null) request.fields['title'] = title;
    request.fields['body'] = body;
    request.fields['lead_id'] = leadId.toString();
    if (dealId != null) {
      request.fields['deal_id'] = dealId.toString();
    }
    if (date != null)
      request.fields['date'] = DateFormat('yyyy-MM-dd HH:mm').format(date);
    request.fields['send_notification'] = sendNotification.toString();
    request.fields['send_sms'] = sendSms.toString();

    // Добавляем пользователей
    if (users.isNotEmpty) {
      for (int i = 0; i < users.length; i++) {
        request.fields['users[$i]'] = users[i].toString();
      }
    }

    // Добавляем ID существующих файлов
    if (existingFiles != null && existingFiles.isNotEmpty) {
      final existingFileIds = existingFiles.map((file) => file.id).toList();
      for (int i = 0; i < existingFileIds.length; i++) {
        request.fields['existing_file_ids[$i]'] = existingFileIds[i].toString();
      }
    }

    // Добавляем новые файлы, если они есть
    if (filePaths != null && filePaths.isNotEmpty) {
      for (var filePath in filePaths) {
        final file = await http.MultipartFile.fromPath('files[]', filePath);
        request.files.add(file);
      }
    }

    final response = await _multipartPostRequest(path, request);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'notice_updated_successfully'};
    } else if (response.statusCode == 422) {
      return {'success': false, 'message': 'validation_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'error_notice_update'};
    }
  }

  Future<Map<String, dynamic>> deleteNotice(int noticeId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/notices/$noticeId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteNotice - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw ('Failed to delete notice!');
    }
  }

  Future<Map<String, dynamic>> finishNotice(
      int noticeId, String conclusion) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/notices/finish/$noticeId');
    if (kDebugMode) {
      //debugPrint('ApiService: finishNotice - Generated path: $path');
    }

    final response = await _patchRequest(path, {
      "conclusion": conclusion,
      "organization_id": await getSelectedOrganization()
    });

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw ('Failed to finish notice!');
    }
  }

  Future<SubjectDataResponse> getAllSubjects({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams(
      '/noteSubject/by-sales-funnel-id?page=$page&per_page=$perPage',
    );
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (kDebugMode) {
      //debugPrint('ApiService: getAllSubjects - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SubjectDataResponse.fromJson(data);
    } else {
      throw ('Failed to load subjects');
    }
  }

  Future<AuthorsDataResponse> getAllAuthor() async {
    final token = await getToken(); // Получаем токен перед запросом
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/user');
    if (kDebugMode) {
      //debugPrint('ApiService: getAllAuthor - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    late AuthorsDataResponse dataAuthor;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataAuthor = AuthorsDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // ////debugPrint('Статус ответа!');
    }
    if (kDebugMode) {
      // ////debugPrint('getAll author!');
    }

    return dataAuthor;
  }

  String getRecordingUrl(String recordPath) {
    if (recordPath.isEmpty) return '';

    // Если путь уже содержит полный URL, возвращаем его
    if (recordPath.startsWith('http://') || recordPath.startsWith('https://')) {
      return recordPath;
    }

    // Убираем '/api' из baseUrl и добавляем путь к записи
    String cleanBaseUrl = baseUrl?.replaceAll('/api', '') ?? '';
    return recordPath.startsWith('/call-recordings/')
        ? '$cleanBaseUrl$recordPath'
        : '$cleanBaseUrl/storage/$recordPath';
  }

  Future<Map<String, dynamic>> getTutorialProgress() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/tutorials/getProgress');
    if (kDebugMode) {
      //debugPrint('ApiService: getTutorialProgress - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _normalizeTutorialProgressResponse(data);
    } else {
      throw Exception(
          'Failed to get tutorial progress: ${response.statusCode}');
    }
  }

  Map<String, dynamic> _normalizeTutorialProgressResponse(dynamic rawData) {
    Map<String, dynamic> normalizeResult(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            return item;
          }
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
        }
      }
      return <String, dynamic>{};
    }

    if (rawData is Map<String, dynamic>) {
      return <String, dynamic>{
        ...rawData,
        'result': normalizeResult(rawData['result']),
      };
    }

    if (rawData is Map) {
      final data = Map<String, dynamic>.from(rawData);
      return <String, dynamic>{
        ...data,
        'result': normalizeResult(data['result']),
      };
    }

    return <String, dynamic>{
      'result': normalizeResult(rawData),
    };
  }

  Future<Map<String, dynamic>> getSettings(String? organizationId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/setting');
    if (kDebugMode) {
      //debugPrint('ApiService: getSettings - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to get settings: ${response.statusCode}');
    }
  }

  Future<List<MiniAppSettings>> getMiniAppSettings(
      String? organizationId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/mini-app/setting');
    if (kDebugMode) {
      //debugPrint('ApiService: getMiniAppSettings - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rawList = <dynamic>[];
      final result = data['result'];

      if (result is List) {
        rawList.addAll(result);
      } else if (result is Map<String, dynamic>) {
        if (result['data'] is List) {
          rawList.addAll(result['data'] as List<dynamic>);
        } else if (result['items'] is List) {
          rawList.addAll(result['items'] as List<dynamic>);
        }
      }

      if (kDebugMode) {
        debugPrint(
            'ApiService: getMiniAppSettings - parsed items count: ${rawList.length}');
        if (rawList.isEmpty) {
          debugPrint(
              'ApiService: getMiniAppSettings - empty body: ${response.body}');
        }
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => MiniAppSettings.fromJson(item))
          .toList();
    } else {
      throw Exception(
          'Failed to get mini-app settings: ${response.statusCode}');
    }
  }

  Future<List<CalendarEvent>> getCalendarEventsByMonth(
    int month, {
    String? search,
    List<String>? types,
    List<String>? userIds, // Added parameter for user IDs
  }) async {
    String url = '/calendar/getByMonth?month=$month';

    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }

    if (types != null && types.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
            '📅 Calendar types to send: $types (count: ${types.length})');
      }
      url += types.map((type) => '&type[]=${Uri.encodeComponent(type)}').join();
    }

    if (kDebugMode) {
      debugPrint('📅 Calendar URL after types: $url');
    }

    if (userIds != null && userIds.isNotEmpty) {
      url += userIds
          // TODO check if users[] or user_id[]
          .map((userId) => '&user_id[]=$userId')
          .join(); // Append user IDs
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('📅 Calendar API URL: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null && data['result'] is List) {
        return (data['result'] as List)
            .map((item) => CalendarEvent.fromJson(item))
            .toList();
      }
      throw ('Ошибка формата загрузки календаря!');
    } else {
      throw ('Ошибка загрузки календаря!');
    }
  }
}
