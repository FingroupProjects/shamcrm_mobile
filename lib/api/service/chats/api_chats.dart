part of '../api_service.dart';

extension ApiChatsX on ApiService {
  String? _extractResponseMessage(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  /// Получение статистики сообщений
  /// Endpoint: /api/dashboard/message-stats
  Future<MessageStatsResponse> getMessageStats() async {
    final path = await _appendQueryParams('/dashboard/message-stats');

    if (kDebugMode) {
      debugPrint('ApiService: getMessageStats - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getMessageStats',
      fallbackMessage: 'Ошибка загрузки статистики сообщений!',
    );
    return MessageStatsResponse.fromJson(jsonData);
  }

  /// Ответы на сообщения (график)
  /// Endpoint: /api/v2/dashboard/replies-to-messages-chart
  Future<RepliesToMessagesResponse> getRepliesToMessagesChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/replies-to-messages-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getRepliesToMessagesChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getRepliesToMessagesChartV2',
      fallbackMessage: 'Ошибка загрузки ответов на сообщения!',
    );
    return RepliesToMessagesResponse.fromJson(jsonData);
  }

  Future<PaginationDTO<Chats>> getAllChats(
    String endPoint, [
    int page = 1,
    String? search,
    int? salesFunnelId,
    Map<String, dynamic>? filters,
  ]) async {
    final token = await getToken();
    String path = '/v2/chat/getMyChats/$endPoint?page=$page';

    path = await _appendQueryParams(path);

    if (search != null && search.isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search)}';
    }

    if (salesFunnelId != null && endPoint == 'lead') {
      path += '&funnel_id=$salesFunnelId';
    }

    if (filters != null) {
      if (endPoint == 'lead') {
        // ИСПРАВЛЕНО: Менеджеры - поддержка Map и объектов
        if (filters['managers'] != null &&
            (filters['managers'] as List).isNotEmpty) {
          List<int> managerIds = (filters['managers'] as List).map((m) {
            if (m is Map) {
              return SafeConverters.toInt(m['id']);
            }
            return SafeConverters.toInt(m.id); // Для объектов ManagerData
          }).toList();
          for (int managerId in managerIds) {
            path += '&managers[]=$managerId';
          }
        }

        // ИСПРАВЛЕНО: Регионы - поддержка Map и объектов
        if (filters['regions'] != null &&
            (filters['regions'] as List).isNotEmpty) {
          List<int> regionIds = (filters['regions'] as List).map((r) {
            if (r is Map) {
              return SafeConverters.toInt(r['id']);
            }
            return SafeConverters.toInt(r.id); // Для объектов RegionData
          }).toList();
          for (int regionId in regionIds) {
            path += '&regions[]=$regionId';
          }
        }

        // ИСПРАВЛЕНО: Источники - поддержка Map и объектов
        if (filters['sources'] != null &&
            (filters['sources'] as List).isNotEmpty) {
          List<int> sourceIds = (filters['sources'] as List).map((s) {
            if (s is Map) {
              return SafeConverters.toInt(s['id']);
            }
            return SafeConverters.toInt(s.id); // Для объектов SourceData
          }).toList();
          for (int sourceId in sourceIds) {
            path += '&sources[]=$sourceId';
          }
        }

        // Статусы (без изменений)
        if (filters['statuses'] != null &&
            (filters['statuses'] as List).isNotEmpty) {
          List<String> statusIds = (filters['statuses'] as List).cast<String>();
          for (String statusId in statusIds) {
            path += '&leadStatus[]=$statusId';
          }
        }

        // Даты (без изменений)
        if (filters['fromDate'] != null) {
          path += '&from_date=${filters['fromDate'].toIso8601String()}';
        }
        if (filters['toDate'] != null) {
          path += '&to_date=${filters['toDate'].toIso8601String()}';
        }

        // Флаги (без изменений)
        if (filters['hasSuccessDeals'] == true) {
          path += '&has_success_deals=1';
        }
        if (filters['hasInProgressDeals'] == true) {
          path += '&has_in_progress_deals=1';
        }
        if (filters['hasFailureDeals'] == true) {
          path += '&has_failure_deals=1';
        }
        if (filters['hasNotices'] == true) {
          path += '&has_notices=1';
        }
        if (filters['hasContact'] == true) {
          path += '&has_contact=1';
        }
        if (filters['hasChat'] == true) {
          path += '&has_chat=1';
        }
        if (filters['hasNoReplies'] == true) {
          path += '&hasNoReplies=1';
        }
        if (filters['hasUnreadMessages'] == true) {
          path += '&unread_only=1';
        }
        if (filters['hasDeal'] == true) {
          path += '&has_deal=1';
        }
        if (filters['unreadOnly'] == true) {
          path += '&unread_only=1';
        }
        if (filters['daysWithoutActivity'] != null &&
            filters['daysWithoutActivity'] > 0) {
          path += '&days_without_activity=${filters['daysWithoutActivity']}';
        }
        if (filters['directory_values'] != null &&
            (filters['directory_values'] as List).isNotEmpty) {
          List<Map<String, dynamic>> directoryValues =
              filters['directory_values'] as List<Map<String, dynamic>>;
          for (var value in directoryValues) {
            path +=
                '&directory_values[${value['directory_id']}]=${value['entry_id']}';
          }
        }
      } else if (endPoint == 'task') {
        // Обработка фильтров для task (без изменений)
        if (filters['task_number'] != null &&
            filters['task_number'].isNotEmpty) {
          path += '&task_number=${Uri.encodeComponent(filters['task_number'])}';
        }
        if (filters['department_id'] != null) {
          path += '&department_id=${filters['department_id']}';
        }
        if (filters['task_created_from'] != null) {
          path += '&task_created_from=${filters['task_created_from']}';
        }
        if (filters['task_created_to'] != null) {
          path += '&task_created_to=${filters['task_created_to']}';
        }
        if (filters['deadline_from'] != null) {
          path += '&deadline_from=${filters['deadline_from']}';
        }
        if (filters['deadline_to'] != null) {
          path += '&deadline_to=${filters['deadline_to']}';
        }
        if (filters['executor_ids'] != null &&
            (filters['executor_ids'] as List).isNotEmpty) {
          List<String> executorIds = (filters['executor_ids'] as List)
              .map((id) => id.toString())
              .toList();
          for (String executorId in executorIds) {
            path += '&executor_ids[]=$executorId';
          }
        }
        if (filters['author_ids'] != null &&
            (filters['author_ids'] as List).isNotEmpty) {
          List<int> authorIds = (filters['author_ids'] as List).cast<int>();
          for (int authorId in authorIds) {
            path += '&author_ids[]=$authorId';
          }
        }
        if (filters['project_ids'] != null &&
            (filters['project_ids'] as List).isNotEmpty) {
          List<int> projectIds = (filters['project_ids'] as List).cast<int>();
          for (int projectId in projectIds) {
            path += '&project_ids[]=$projectId';
          }
        }
        if (filters['task_status_ids'] != null &&
            (filters['task_status_ids'] as List).isNotEmpty) {
          List<int> taskStatusIds =
              (filters['task_status_ids'] as List).cast<int>();
          for (int statusId in taskStatusIds) {
            path += '&task_status_ids[]=$statusId';
          }
        }
        if (filters['unread_only'] == true) {
          path += '&unread_only=1';
        }
      }
    }

    final fullUrl = '$baseUrl$path';

    // ДОБАВЛЕНО: Отладочный вывод
    debugPrint('ApiService.getAllChats: Final URL: $fullUrl');

    try {
      // ДОБАВЛЕНО: Timeout для диагностики медленных ответов бэкенда
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'FlutterApp/1.0',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 302) {
        throw Exception('Получен редирект 302. Проверьте URL и авторизацию.');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          final pagination = PaginationDTO<Chats>.fromJson(data['result'], (e) {
            return Chats.fromJson(e);
          });
          return pagination;
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService.getAllChats: Error: $e');
      rethrow;
    }
  }

  Future<String> getDynamicBaseUrlFixed() async {
    // Сначала проверяем кешированное значение
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedBaseUrl = prefs.getString('cached_base_url');

    if (cachedBaseUrl != null &&
        cachedBaseUrl.isNotEmpty &&
        cachedBaseUrl != 'null') {
      if (kDebugMode) {
        debugPrint('ApiService: Using cached baseUrl: $cachedBaseUrl');
      }
      return cachedBaseUrl;
    }

    // Если кеша нет, используем старую логику
    return await getDynamicBaseUrl();
  }

  Future<ChatsGetId> getChatById(int chatId) async {
    final token = await getToken();
    String path = '/v2/chat/$chatId';
    path = await _appendQueryParams(path);

    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('🔍 [getChatById] Requesting: $baseUrl$path');

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'FlutterApp/1.0',
        'Cache-Control': 'no-cache',
      },
    );

    debugPrint('📥 [getChatById] Status: ${response.statusCode}');
    debugPrint('📥 [getChatById] Full Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // ✅ ЛОГИРУЕМ СТРУКТУРУ ВЕРХНЕГО УРОВНЯ
      debugPrint('📊 [getChatById] Top-level keys: ${data.keys.toList()}');

      if (data['result'] != null) {
        final result = data['result'];

        // ✅ ЛОГИРУЕМ СТРУКТУРУ result
        debugPrint('📊 [getChatById] Result keys: ${result.keys.toList()}');
        debugPrint('📊 [getChatById] Result type: ${result['type']}');
        debugPrint('📊 [getChatById] Result name: "${result['name']}"');
        debugPrint('📊 [getChatById] Result group: ${result['group']}');
        debugPrint(
            '📊 [getChatById] Result chatUsers type: ${result['chatUsers']?.runtimeType}');
        debugPrint(
            '📊 [getChatById] Result chatUsers length: ${result['chatUsers']?.length}');

        if (result['chatUsers'] != null && result['chatUsers'] is List) {
          debugPrint('📊 [getChatById] ChatUsers content:');
          for (var i = 0; i < (result['chatUsers'] as List).length; i++) {
            final user = result['chatUsers'][i];
            debugPrint(
                '   [$i] type: ${user['type']}, participant: ${user['participant']?['name']}');
          }
        }

        debugPrint('════════════════════════════════════════════════════════');

        return ChatsGetId.fromJson(result);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }

  Future<int> getUnreadMessagesCount() async {
    final token = await getToken();
    String path = '/v2/chat/getUnreadMessagesCount';
    path = await _appendQueryParams(path);

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Ошибка ${response.statusCode} при получении общего счетчика чатов');
    }

    final data = json.decode(response.body);
    return _extractUnreadCountFromResponse(data);
  }

  Future<Map<String, int>> getUnreadMessagesCountByChatType() async {
    final token = await getToken();
    String path = '/v2/chat/getUnreadMessagesCountByChatType';
    path = await _appendQueryParams(path);
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('ApiService.getUnreadMessagesCountByChatType: GET $uri');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    debugPrint(
      'ApiService.getUnreadMessagesCountByChatType: status=${response.statusCode}, body=${response.body}',
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Ошибка ${response.statusCode} при получении счетчиков чатов по типам');
    }

    final data = json.decode(response.body);
    final result = data is Map<String, dynamic> ? data['result'] : null;
    if (result is! Map<String, dynamic>) {
      return const {
        'corporate': 0,
        'leads': 0,
        'tasks': 0,
        'all': 0,
      };
    }

    return {
      'corporate': _extractIntValue(result['corporate']),
      'leads': _extractIntValue(result['leads']),
      'tasks': _extractIntValue(result['tasks']),
      'all': _extractIntValue(result['all']),
    };
  }

  int _extractIntValue(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  int _extractUnreadCountFromResponse(dynamic data) {
    if (data is int) {
      return data;
    }

    if (data is String) {
      return int.tryParse(data) ?? 0;
    }

    if (data is Map<String, dynamic>) {
      final dynamic result = data['result'] ?? data['data'] ?? data;

      if (result is int) {
        return result;
      }

      if (result is String) {
        return int.tryParse(result) ?? 0;
      }

      if (result is Map<String, dynamic>) {
        const keys = [
          'count',
          'unread_count',
          'unreadCount',
          'total',
          'messages_count',
        ];

        for (final key in keys) {
          final value = result[key];
          if (value is int) {
            return value;
          }
          if (value is String) {
            final parsed = int.tryParse(value);
            if (parsed != null) {
              return parsed;
            }
          }
        }
      }
    }

    return 0;
  }

  Future<String> sendMessages(List<int> messageIds) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/chat/read');
    if (kDebugMode) {
      //debugPrint('ApiService: sendMessages - Generated path: $path');
    }

    // Prepare the body
    final body = json.encode({'message_ids': messageIds});

    // Make the POST request
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['message'] ?? 'Success';
    } else {
      throw Exception('Error ${response.statusCode}!');
    }
  }

  Future<ChatMessagesPage> getMessagesPage(
    int chatId, {
    int page = 1,
    String? search,
    String? chatType, // Тип чата: 'lead', 'corporate', 'task'
  }) async {
    try {
      final token = await getToken();
      // ✅ Обновляем userID.value, чтобы Message.fromJson корректно определял isMyMessage
      try {
        if (userID.value.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final storedUserId = prefs.getString('userID') ?? '';
          if (storedUserId.isNotEmpty) {
            userID.value = storedUserId;
          }
        }
      } catch (_) {}

      // Проверяем инициализацию baseUrl
      if (baseUrl == null || baseUrl!.isEmpty || baseUrl == 'null') {
        await initialize();
        if (baseUrl == null || baseUrl!.isEmpty || baseUrl == 'null') {
          throw Exception('Base URL не может быть инициализирован');
        }
      }

      String path = '/v3/chat/getMessages/$chatId?page=$page';
      path = await _appendQueryParams(path);

      if (search != null && search.isNotEmpty) {
        path += '&search=${Uri.encodeComponent(search)}';
      }

      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChatMessagesPage.fromJson(
          Map<String, dynamic>.from(data as Map),
          chatType: chatType,
        );
      } else {
        throw Exception('Ошибка ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService.getMessages error: $e');
      rethrow;
    }
  }

  Future<List<Message>> getMessages(
    int chatId, {
    String? search,
    String? chatType,
  }) async {
    final page = await getMessagesPage(
      chatId,
      page: 1,
      search: search,
      chatType: chatType,
    );
    return page.data;
  }

  Future<void> closeChatSocket(int chatId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/clearCache/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: closeChatSocket - Generated path: $path');
    }

    final response = await _postRequest(path, {});

    if (response.statusCode != 200) {
      throw Exception('close sokcet!');
    }
  }

  /// Marks the chat as read on the server while the user is inside it.
  /// Endpoint: POST /api/v2/chat/{chatId}/heartbeat
  Future<void> sendChatHeartbeat(int chatId) async {
    final path = await _appendQueryParams('/v2/chat/$chatId/heartbeat');
    if (kDebugMode) {
      debugPrint('ApiService: sendChatHeartbeat - path: $path');
    }

    final response = await _postRequest(path, {});
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'Ошибка heartbeat ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<void> sendMessage(int chatId, String message,
      {String? replyMessageId, String? responseType}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendMessage/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: sendMessage - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'message': message,
      if (replyMessageId != null) 'forwarded_message_id': replyMessageId,
      if (responseType != null) 'response_type': responseType,
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки сообщения!');
    }
  }

  Future<void> sendLocation(
    int chatId, {
    required double latitude,
    required double longitude,
    String? responseType,
  }) async {
    final path = await _appendQueryParams('/v2/chat/sendLocation/$chatId');

    final response = await _postRequest(path, {
      'latitude': latitude,
      // Backend still accepts the legacy misspelled key in some environments.
      'lattitude': latitude,
      'longitude': longitude,
      if (responseType != null) 'response_type': responseType,
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки геопозиции!');
    }
  }

  Future<void> pinMessage(String messageId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/pinMessage/$messageId');
    if (kDebugMode) {
      //debugPrint('ApiService: pinMessage - Generated path: $path');
    }

    final response = await _postRequest(path, {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка закрепления сообщения!');
    }
  }

  Future<void> unpinMessage(String messageId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/pinMessage/$messageId');
    if (kDebugMode) {
      //debugPrint('ApiService: unpinMessage - Generated path: $path');
    }

    final response = await _postRequest(path, {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка закрепления сообщения!');
    }
  }

  Future<void> editMessage(String messageId, String message) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/editMessage/$messageId');
    if (kDebugMode) {
      //debugPrint('ApiService: editMessage - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'message': message,
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка изменения сообщения!');
    }
  }

  Future<void> sendChatAudioFile(int chatId, File audio,
      {String? responseType}) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendVoice/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: sendChatAudioFile - Generated path: $path');
    }

    String requestUrl = '$baseUrl$path';

    Dio dio = LoggedDioClient.create();
    try {
      final voice = await MultipartFile.fromFile(audio.path,
          contentType: MediaType('audio', 'm4a'));
      FormData formData = FormData.fromMap({
        'voice': voice,
        if (responseType != null) 'response_type': responseType,
      });

      var response = await dio.post(
        requestUrl,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );
      if (kDebugMode) {
        ////debugPrint('response.statusCode!');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          ////debugPrint('Audio message sent successfully!');
        }
      } else {
        if (kDebugMode) {
          ////debugPrint('Error sending audio message: ${response.data}');
        }
        throw Exception('Error sending audio message: ${response.data}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        ////debugPrint('Exception caught!');
      }
      if (kDebugMode) {
        ////debugPrint(e.response?.data);
      }
      throw Exception('Failed to send audio message due to an exception!');
    }
  }

  Future<void> sendChatFile(int chatId, String pathFile,
      {String? responseType}) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendFile/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: sendChatFile - Generated path: $path');
    }

    String requestUrl = '$baseUrl$path';

    Dio dio = LoggedDioClient.create();
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(pathFile),
        if (responseType != null) 'response_type': responseType,
      });

      var response = await dio.post(
        requestUrl,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            'Device': 'mobile'
          },
          contentType: 'multipart/form-data',
        ),
      );
      if (kDebugMode) {
        ////debugPrint('response.statusCode!');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          ////debugPrint('Audio message sent successfully!');
        }
      } else {
        if (kDebugMode) {
          ////debugPrint('Error sending audio message: ${response.data}');
        }
        throw Exception('Error sending audio message: ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        ////debugPrint('Exception caught!');
      }
      throw Exception('Failed to send audio message due to an exception!');
    }
  }

  Future<void> sendChatFiles(
    int chatId,
    List<String> filePaths, {
    String? responseType,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    if (filePaths.isEmpty) return;

    if (filePaths.length == 1) {
      await sendChatFile(
        chatId,
        filePaths.first,
        responseType: responseType,
      );
      return;
    }

    final token = await getToken();
    final path = await _appendQueryParams('/v2/chat/sendFile/$chatId');
    final requestUrl = '$baseUrl$path';

    final dio = LoggedDioClient.create();

    try {
      final formMap = <String, dynamic>{
        if (responseType != null) 'response_type': responseType,
      };

      formMap['files[]'] = [
        for (final pathFile in filePaths)
          await MultipartFile.fromFile(pathFile),
      ];

      final response = await dio.post(
        requestUrl,
        data: FormData.fromMap(formMap),
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            'Device': 'mobile'
          },
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Error sending media batch: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to send media batch due to an exception!');
    }
  }

  Future<void> sendFile(int chatId, String filePath) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendFile/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: sendFile - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'file_path': filePath,
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки файла!');
    }
  }

  Future<void> sendVoice(int chatId, String voicePath) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendVoice/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: sendVoice - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'voice_path': voicePath,
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки голосового сообщения!');
    }
  }

  Future<Map<String, dynamic>> deleteChat(int chatId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/v2/chat/$chatId');
      if (kDebugMode) {
        //debugPrint('ApiService: deleteChat - Generated path: $path');
      }

      final response = await _deleteRequest(path);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return {
          'result': responseBody['result'],
          'errors': responseBody['errors'],
        };
      } else if (response.statusCode == 400) {
        // Ошибка запроса
        throw Exception('Ошибка запроса: Неверные данные');
      } else if (response.statusCode == 401) {
        // Ошибка авторизации
        throw Exception('Ошибка авторизации: Некорректные учетные данные');
      } else if (response.statusCode == 403) {
        // Ошибка доступа
        throw Exception('Ошибка доступа: Недостаточно прав');
      } else if (response.statusCode == 404) {
        // Чат не найден
        throw Exception('Ошибка: Чат не найден');
      } else if (response.statusCode >= 500 && response.statusCode < 600) {
        // Ошибка сервера
        throw Exception('Ошибка сервера: Попробуйте позже');
      } else {
        // Обработка других ошибок
        throw Exception('Неизвестная ошибка!');
      }
    } catch (e) {
      // Обработка ошибок сети или других непредвиденных исключений
      throw Exception('Не удалось выполнить запрос!');
    }
  }

  Future<UsersDataResponse> getAllUser({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final token = await getToken();
    String path = await _appendQueryParams(
      '/department/get/users?page=$page&per_page=$perPage',
    );
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (kDebugMode) {
      //debugPrint('ApiService: getAllUser - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //debugPrint('ApiService: getAllUser - Response: $data');
      }
      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }

    return dataUser;
  }

  Future<UsersDataResponse> getAnotherUsers() async {
    final token = await getToken(); // Получаем токен перед запросом
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/user/getAnotherUsers/');
    if (kDebugMode) {
      //debugPrint('ApiService: getAnotherUsers - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // ////debugPrint('Статус ответа!');
    }
    if (kDebugMode) {
      // ////debugPrint('getAll user!');
    }

    return dataUser;
  }

  Future<UsersDataResponse> getUsersNotInChat(String chatId) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/user/users-not-in-chat/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: getUsersNotInChat - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // ////debugPrint('Статус ответа!');
    }
    if (kDebugMode) {
      // ////debugPrint('getUsersNotInChat!');
    }

    return dataUser;
  }

  Future<UsersDataResponse> getUsersWihtoutCorporateChat() async {
    final token = await getToken(); // Получаем токен перед запросом
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/chat/users/without-corporate-chat/');
    if (kDebugMode) {
      //debugPrint('ApiService: getUsersWihtoutCorporateChat - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    ////debugPrint(
    // '----------------------------------------------------------------------');
    ////debugPrint(
    // '-------------------------------getUsersWihtoutCorporateChat---------------------------------------');
    ////debugPrint(response);

    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // ////debugPrint('Статус ответа!');
    }
    if (kDebugMode) {
      // ////debugPrint('getAll user!');
    }

    return dataUser;
  }

  Future<Map<String, dynamic>> createNewClient(String userID) async {
    try {
      // Инициализируем baseUrl, если он ещё не установлен
      if (baseUrl == null || baseUrl!.isEmpty) {
        await initialize();
        if (baseUrl == null || baseUrl!.isEmpty) {
          throw Exception(
              'baseUrl is not defined after initialization. Please ensure domain is set.');
        }
      }

      final token = await getToken();
      final path = await _appendQueryParams('/chat/createChat/$userID');

      // Проверка organization_id
      final organizationId = await getSelectedOrganization();
      if (organizationId == null) {
        if (kDebugMode) {
          debugPrint(
              'ApiService: createNewClient - Using fallback organization_id=1');
        }
      }

      if (kDebugMode) {
        debugPrint('ApiService: createNewClient - Base URL: $baseUrl');
        debugPrint('ApiService: createNewClient - Generated path: $path');
        debugPrint('ApiService: createNewClient - Token: $token');
        debugPrint(
            'ApiService: createNewClient - Organization ID: $organizationId');
      }

      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'user_id': userID,
          'organization_id':
              organizationId, // Используем organizationId напрямую, так как есть fallback в getSelectedOrganization
        }),
      );

      if (kDebugMode) {
        debugPrint(
            'ApiService: createNewClient - Status code: ${response.statusCode}');
        debugPrint(
            'ApiService: createNewClient - Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        var chatId = jsonResponse['result']['id'];
        return {'chatId': chatId};
      } else {
        throw Exception(
            'Failed to create chat: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: createNewClient - Error: $e');
      }
      throw Exception('Failed to create chat: $e');
    }
  }

  Future<Map<String, dynamic>> createGroupChat({
    required String name,
    List<int>? userId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'users': userId?.map((id) => {'id': id}).toList() ?? [],
      };

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/chat/createGroup');
      if (kDebugMode) {
        //debugPrint('ApiService: createGroupChat - Generated path: $path');
      }

      final response = await _postRequest(
        path,
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'group_chat_created_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        return {
          'success': false,
          'message': 'error_validation',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        return {
          'success': false,
          'message': 'error_create_group_chat',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_create_group_chat',
      };
    }
  }

  Future<Map<String, dynamic>> addUserToGroup({
    required int chatId,
    int? userId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'chatId': chatId,
        'userId': userId,
      };

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path =
          await _appendQueryParams('/chat/addUserToGroup/$chatId/$userId');
      if (kDebugMode) {
        //debugPrint('ApiService: addUserToGroup - Generated path: $path');
      }

      final response = await _postRequest(
        path,
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Участник успешно добавлен.',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'Ошибка на сервере. Попробуйте позже.',
        };
      } else {
        return {
          'success': false,
          'message': 'Ошибка добавления участника!',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при добавление участника !',
      };
    }
  }

  Future<Map<String, dynamic>> deleteUserFromGroup({
    required int chatId,
    int? userId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'chatId': chatId,
        'userId': userId,
      };

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path =
          await _appendQueryParams('/chat/removeUserFromGroup/$chatId/$userId');
      if (kDebugMode) {
        //debugPrint('ApiService: deleteUserFromGroup - Generated path: $path');
      }

      final response = await _postRequest(
        path,
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Участник успешно добавлен.',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'Ошибка на сервере. Попробуйте позже.',
        };
      } else {
        return {
          'success': false,
          'message': 'Ошибка добавления участника!',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при добавление участника !',
      };
    }
  }

  Future<void> DeleteMessage({int? messageId}) async {
    if (messageId == null) {
      throw Exception('MessageId не может быть null');
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/delete-message/$messageId');
    if (kDebugMode) {
      //debugPrint('ApiService: DeleteMessage - Generated path: $path');
    }

    ////debugPrint('Sending DELETE request to API with path: $path');

    // Используем _deleteRequest для отправки DELETE-запроса
    final response = await _deleteRequest(path);

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления уведомлений!');
    }

    final data = json.decode(response.body);
    if (data['result'] == 'deleted') {
      return;
    } else {
      throw Exception('Ошибка удаления уведомления');
    }
  }

  Future<TemplateResponse> getTemplates() async {
    final token = await getToken();

    // Проверяем инициализацию baseUrl
    if (baseUrl == null || baseUrl!.isEmpty || baseUrl == 'null') {
      await initialize();
      if (baseUrl == null || baseUrl!.isEmpty || baseUrl == 'null') {
        throw Exception('Base URL не может быть инициализирован');
      }
    }

    final path = await _appendQueryParams('/v2/chat/templates');
    if (kDebugMode) {
      //debugPrint('ApiService: getTemplates - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return TemplateResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при загрузке шаблонов: ${response.statusCode}');
    }
  }

  Future<List<NoticeSmsSample>> getNoticeSmsSamples() async {
    final path = await _appendQueryParams('/sample');
    final response = await _getRequest(path);

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to get sms notice samples: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final result = data['result'];
    if (result is! List) {
      return <NoticeSmsSample>[];
    }

    return result
        .whereType<Map<String, dynamic>>()
        .map(NoticeSmsSample.fromJson)
        .toList();
  }

  Future<List<SmsSenderIntegration>> getSmsIntegrations({
    String? organizationId,
    String? salesFunnelId,
  }) async {
    final resolvedOrganizationId =
        organizationId ?? await getSelectedOrganization();
    final resolvedSalesFunnelId =
        salesFunnelId ?? await getSelectedSalesFunnel();

    var path =
        '/integrations/get-by-category/sms?organization_id=${resolvedOrganizationId ?? '1'}';
    if (resolvedSalesFunnelId != null && resolvedSalesFunnelId.isNotEmpty) {
      path += '&sales_funnel_id=$resolvedSalesFunnelId';
    }

    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw Exception('Failed to get sms integrations: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final result = data['result'];
    if (result is! List) {
      return <SmsSenderIntegration>[];
    }

    return result
        .whereType<Map<String, dynamic>>()
        .map(SmsSenderIntegration.fromJson)
        .toList();
  }

  Future<void> sendLeadSmsMessage({
    required int leadId,
    required int integrationId,
    required String text,
    String? organizationId,
    String? salesFunnelId,
  }) async {
    final resolvedOrganizationId =
        organizationId ?? await getSelectedOrganization() ?? '1';
    final resolvedSalesFunnelId =
        salesFunnelId ?? await getSelectedSalesFunnel();

    var path =
        '/lead/send-message/$leadId?organization_id=$resolvedOrganizationId';
    if (resolvedSalesFunnelId != null && resolvedSalesFunnelId.isNotEmpty) {
      path += '&sales_funnel_id=$resolvedSalesFunnelId';
    }

    final body = <String, dynamic>{
      'integration_id': integrationId,
      'text': text,
      'organization_id': resolvedOrganizationId,
      if (resolvedSalesFunnelId != null && resolvedSalesFunnelId.isNotEmpty)
        'sales_funnel_id': resolvedSalesFunnelId,
    };

    final response = await _postRequest(path, body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send sms: ${response.statusCode}');
    }
  }

  Future<List<LeadSmsMessage>> getLeadSmsMessages({
    required int leadId,
    String? organizationId,
    String? salesFunnelId,
  }) async {
    final resolvedOrganizationId =
        organizationId ?? await getSelectedOrganization() ?? '1';
    final resolvedSalesFunnelId =
        salesFunnelId ?? await getSelectedSalesFunnel();

    var path =
        '/lead/get-message/$leadId?organization_id=$resolvedOrganizationId';
    if (resolvedSalesFunnelId != null && resolvedSalesFunnelId.isNotEmpty) {
      path += '&sales_funnel_id=$resolvedSalesFunnelId';
    }

    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw Exception('Failed to get sms messages: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final result = data['result'];
    if (result is! List) {
      return <LeadSmsMessage>[];
    }

    return result
        .whereType<Map<String, dynamic>>()
        .map(LeadSmsMessage.fromJson)
        .toList();
  }

  Future<ChatProfile> getChatProfile(int chatId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/lead/getByChat/$chatId');
      if (kDebugMode) {
        //debugPrint('ApiService: getChatProfile - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        if (decodedJson['result'] != null) {
          return ChatProfile.fromJson(decodedJson['result']);
        } else {
          throw Exception('Данные профиля не найдены');
        }
      } else if (response.statusCode == 404) {
        throw ('Такого Лида не существует');
      } else {
        ////debugPrint('Ошибка загрузки профиля чата!');
        throw Exception('${response.statusCode}');
      }
    } catch (e) {
      ////debugPrint('Ошибка в getChatProfile!');
      throw ('Ошибка загрузки профиля чата!');
    }
  }

  Future<ChatsGetId> getChatByIdWithIntegration(int chatId) async {
    try {
      final token = await getToken();

      if (baseUrl == null || baseUrl!.isEmpty || baseUrl == 'null') {
        await initialize();
      }

      String path = '/v2/chat/$chatId';
      path = await _appendQueryParams(path);

      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'FlutterApp/1.0',
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          return ChatsGetId.fromJson(data['result']);
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('getChatByIdWithIntegration error: $e');
      rethrow;
    }
  }

  Future<String> readMessages(int chatId, int messageId) async {
    final token = await getToken();
    final path = await _appendQueryParams('/v2/chat/readMessages/$chatId');
    // Лог для отладки пути и параметров
    if (kDebugMode) {
      //debugPrint('ApiService: readMessages - Путь: $path, messageId: $messageId, token: $token');
    }

    final body = json.encode({'up_to_message_id': messageId});

    try {
      // Добавлен таймаут в 10 секунд для запроса
      final response = await http
          .post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'FlutterApp/1.0',
          'Cache-Control': 'no-cache',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Запрос readMessages превысил время ожидания');
      });

      // Лог для ответа сервера
      if (kDebugMode) {
        //debugPrint('ApiService.readMessages: Код ответа: ${response.statusCode}');
        //debugPrint('ApiService.readMessages: Тело ответа: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] ?? 'Сообщения успешно помечены как прочитанные';
      } else {
        throw Exception('Ошибка ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Лог для всех ошибок, включая TimeoutException
      if (kDebugMode) {
        //debugPrint('ApiService.readMessages: Поймано исключение: $e');
      }
      rethrow;
    }
  }
}
