part of '../api_service.dart';

extension ApiHttpX on ApiService {
  bool _shouldApplyAnalyticsDashboardFilters(String path) {
    final pathOnly = path.split('?').first;
    return pathOnly.contains('/v2/dashboard') ||
        pathOnly.contains('/dashboard-settings');
  }

  String _appendAnalyticsFiltersToPath(String path) {
    final filters = ApiService._analyticsFilters;
    if (filters == null || filters.isEmpty) {
      if (kDebugMode) {
        debugPrint(
            '🟡 _appendAnalyticsFiltersToPath: No filters to apply to $path');
      }
      return path;
    }

    if (!_shouldApplyAnalyticsDashboardFilters(path)) {
      return path;
    }

    try {
      final uri = Uri.parse(path);
      // Create mutable copies of the lists to avoid "Cannot add to an unmodifiable list" error
      final params = uri.queryParametersAll.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );

      bool hasParamKey(String key) {
        return params.containsKey(key) || params.containsKey('$key[]');
      }

      void addValue(String key, dynamic value) {
        if (value == null) {
          if (key == 'channel') {
            if (!hasParamKey(key)) {
              params.putIfAbsent(key, () => []).add('');
            }
          }
          return;
        }
        if (value is String && value.isEmpty) return;

        if (value is Iterable) {
          final arrayKey = '$key[]';
          if (params.containsKey(arrayKey) || params.containsKey(key)) {
            return;
          }
          for (final item in value) {
            if (item == null) continue;
            final stringValue = item.toString();
            if (stringValue.isEmpty) continue;
            // Use bracket notation for arrays: managers[] instead of managers[0]
            params.putIfAbsent(arrayKey, () => []).add(stringValue);
          }
          return;
        }

        final stringValue = value.toString();
        if (stringValue.isEmpty) return;
        if (!hasParamKey(key)) {
          params.putIfAbsent(key, () => []).add(stringValue);
        }
      }

      filters.forEach(addValue);

      final queryParts = <String>[];
      params.forEach((key, values) {
        for (final value in values) {
          queryParts
              .add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
        }
      });

      final queryString =
          queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
      final result = '${uri.path}$queryString';

      if (kDebugMode) {
        debugPrint(
            '🟢 _appendAnalyticsFiltersToPath: Applied filters to $path');
        debugPrint('   Filters: $filters');
        debugPrint('   Result: $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔴 _appendAnalyticsFiltersToPath: Exception caught: $e');
        debugPrint('   Original path: $path');
      }
      return path;
    }
  }

  String? _extractErrorMessageFromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final rawMessage = body['message'] ?? body['error'] ?? body['errors'];
        if (rawMessage == null) {
          return null;
        }
        if (rawMessage is String) {
          return rawMessage;
        }
        if (rawMessage is List) {
          return rawMessage.map((item) => item.toString()).join('\n');
        }
        if (rawMessage is Map) {
          final parts = <String>[];
          rawMessage.forEach((key, value) {
            if (value is List) {
              parts.add(value.map((item) => item.toString()).join('\n'));
            } else if (value != null) {
              parts.add(value.toString());
            }
          });
          return parts.where((item) => item.trim().isNotEmpty).join('\n');
        }
        return rawMessage.toString();
      }
      return body?.toString();
    } catch (_) {
      return response.body.isEmpty ? null : response.body;
    }
  }

  String? _extractPrimaryMessageFromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final rawMessage = body['message'];
        if (rawMessage == null) {
          return null;
        }
        if (rawMessage is String) {
          return rawMessage.trim().isEmpty ? null : rawMessage.trim();
        }
        return rawMessage.toString().trim().isEmpty
            ? null
            : rawMessage.toString().trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _getOrderStatusChangeErrorMessage(http.Response response) {
    return _extractErrorMessageFromResponse(response) ??
        'Вы не можете переместить заказ на этот статус';
  }

  Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // debugPrint('ApiService: Received 401, forcing logout and redirect');
      await _forceLogoutAndRedirect();
      throw Exception('Неавторизованный доступ!');
    }

    if (response.statusCode == 407 &&
        await _shouldHandleWorkdayResponse(response)) {
      final message =
          _extractResponseMessage(response.body) ?? 'Рабочий день не начат';
      await _handleWorkdayAccessDenied(message);
      throw WorkdayAccessException(message);
    }

    // Дополнительная проверка на другие критические ошибки
    if (response.statusCode >= 500) {
      // debugPrint('ApiService: Server error ${response.statusCode}');
      // Можно добавить дополнительную логику для серверных ошибок
    }

    return response;
  }

  Future<http.Response> _getRequest(String path, {Duration? timeout}) async {
    // Проверяем сессию перед каждым запросом
    if (!await _isSessionValid()) {
      await _forceLogoutAndRedirect();
      throw Exception('Session is invalid');
    }

    if (baseUrl == null) {
      await _initializeIfDomainExists();
      if (baseUrl == null) {
        throw Exception('Base URL is not initialized');
      }
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final fullUrl = '$baseUrl$updatedPath';

    // HTTP Inspector: Создаем лог запроса (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Device': 'mobile'
      };
      String? requestPayload;
      try {
        final query = Uri.parse(fullUrl).queryParametersAll;
        if (query.isNotEmpty) {
          requestPayload = json.encode(
            query.map((k, v) => MapEntry(k, v.length == 1 ? v.first : v)),
          );
        }
      } catch (_) {
        requestPayload = null;
      }
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'GET',
        url: fullUrl,
        requestHeaders: headers,
        requestBody: requestPayload,
      ));
    }

    final startTime = DateTime.now();
    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Device': 'mobile'
        },
      ).timeout(
        timeout ?? ApiService._defaultRequestTimeout,
        onTimeout: () => throw TimeoutException(
          'Превышено время ожидания ответа сервера',
          timeout ?? ApiService._defaultRequestTimeout,
        ),
      );

      // HTTP Inspector: Обновляем лог с ответом (только в DEBUG)
      if (kDebugMode && logId != null) {
        final duration = DateTime.now().difference(startTime);
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              statusCode: response.statusCode,
              responseHeaders: response.headers,
              responseBody: response.body,
              duration: duration,
            ),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      // HTTP Inspector: Логируем ошибку (только в DEBUG)
      if (kDebugMode && logId != null) {
        final duration = DateTime.now().difference(startTime);
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              error: e.toString(),
              duration: duration,
            ),
          );
        }
      }
      rethrow;
    }
  }

  Future<http.Response> _postRequest(
      String path, Map<String, dynamic> body) async {
    // Проверяем сессию только если эндпоинт требует этого
    if (!ApiService._noSessionCheckEndpoints.any((endpoint) => path.contains(endpoint))) {
      if (!await _isSessionValid()) {
        await _forceLogoutAndRedirect();
        throw Exception('Session is invalid');
      }
    }

    if (baseUrl == null) {
      await _initializeIfDomainExists();
      if (baseUrl == null) {
        debugPrint('Error: baseUrl is null');
        throw Exception('Base URL is not initialized');
      }
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final fullUrl = '$baseUrl$updatedPath';
    debugPrint('ApiService: _postRequest with updatedPath: $fullUrl');
    debugPrint('ApiService: Request body: ${json.encode(body)}');

    // HTTP Inspector: Создаем лог запроса (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'Device': 'mobile'
      };
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'POST',
        url: fullUrl,
        requestHeaders: headers,
        requestBody: json.encode(body),
      ));
    }

    final startTime = DateTime.now();
    try {
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Device': 'mobile'
        },
        body: json.encode(body),
      );

      debugPrint(
          'ApiService: _postRequest response status: ${response.statusCode}');
      debugPrint('ApiService: _postRequest response body: ${response.body}');

      // HTTP Inspector: Обновляем лог с ответом (только в DEBUG)
      if (kDebugMode && logId != null) {
        final duration = DateTime.now().difference(startTime);
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              statusCode: response.statusCode,
              responseHeaders: response.headers,
              responseBody: response.body,
              duration: duration,
            ),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      // HTTP Inspector: Логируем ошибку (только в DEBUG)
      if (kDebugMode && logId != null) {
        final duration = DateTime.now().difference(startTime);
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              error: e.toString(),
              duration: duration,
            ),
          );
        }
      }
      rethrow;
    }
  }

  Future<http.Response> _analyticsRequest(
    String path, {
    bool bypassCache = false,
  }) async {
    if (kDebugMode) {
      debugPrint('🔵 _analyticsRequest called with path: $path');
      debugPrint('   Current ApiService._analyticsFilters: $ApiService._analyticsFilters');
    }
    final filteredPath = _appendAnalyticsFiltersToPath(path);
    if (kDebugMode) {
      debugPrint('🔵 _analyticsRequest filtered path: $filteredPath');
    }
    final cachedBody = ApiService._analyticsResponseCache[filteredPath];
    if (!bypassCache && cachedBody != null) {
      if (kDebugMode) {
        debugPrint('🟢 _analyticsRequest cache HIT: $filteredPath');
      }
      return http.Response(
        cachedBody,
        200,
        headers: const {'x-analytics-cache': 'HIT'},
      );
    }

    if (bypassCache && kDebugMode) {
      debugPrint('🟠 _analyticsRequest cache BYPASS: $filteredPath');
    }

    if (!bypassCache) {
      final inFlight = ApiService._analyticsInFlight[filteredPath];
      if (inFlight != null) {
        if (kDebugMode) {
          debugPrint('🟡 _analyticsRequest in-flight JOIN: $filteredPath');
        }
        return inFlight;
      }
    }

    final request = () async {
      final response = await _getRequest(filteredPath);
      if (response.statusCode == 200) {
        ApiService._analyticsResponseCache[filteredPath] = response.body;
        if (kDebugMode) {
          debugPrint('🟢 _analyticsRequest cache SAVE: $filteredPath');
        }
      }
      return response;
    }();

    if (!bypassCache) {
      ApiService._analyticsInFlight[filteredPath] = request;
    }

    try {
      return await request;
    } finally {
      ApiService._analyticsInFlight.remove(filteredPath);
    }
  }

  Future<Map<String, dynamic>> _getAnalyticsChartJsonMap(
    String path, {
    required String debugLabel,
    required String fallbackMessage,
    bool bypassCache = false,
    bool applyAnalyticsFilters = true,
  }) async {
    try {
      final response = applyAnalyticsFilters
          ? await _analyticsRequest(
              path,
              bypassCache: bypassCache,
            )
          : await _getRequest(path);

      if (response.statusCode != 200) {
        _throwAnalyticsChartApiError(response, fallbackMessage);
      }

      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw Exception('Неожиданный формат ответа API');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: $debugLabel error: $e');
      }
      rethrow;
    }
  }

  /// Новый метод для обработки MultipartRequest
  Future<http.Response> _multipartPostRequest(
      String path, http.MultipartRequest request) async {
    final token = await getToken();
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Device': 'mobile',
    });

    //debugPrint('ApiService: _multipartPostRequest with path: ${request.url}');

    // HTTP Inspector: логируем multipart запрос/ответ (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      final multipartPayload = <String, dynamic>{
        'fields': request.fields,
        'files': request.files
            .map((file) => {
                  'field': file.field,
                  'filename': file.filename,
                  'length': file.length,
                  'contentType': file.contentType.toString(),
                })
            .toList(),
      };
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'POST',
        url: request.url.toString(),
        requestHeaders: request.headers,
        requestBody: json.encode(multipartPayload),
      ));
    }

    final startTime = DateTime.now();
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (kDebugMode && logId != null) {
      final existingLog = HttpLogger().getLogById(logId);
      if (existingLog != null) {
        HttpLogger().updateLog(
          logId,
          existingLog.copyWith(
            statusCode: response.statusCode,
            responseHeaders: response.headers,
            responseBody: response.body,
            duration: DateTime.now().difference(startTime),
          ),
        );
      }
    }

    //debugPrint(
    // 'ApiService: _multipartPostRequest response status: ${response.statusCode}');
    //debugPrint('ApiService: _multipartPostRequest response body: ${response.body}');
    return _handleResponse(response);
  }

  String _boolToMultipartFlag(dynamic value) {
    if (value is bool) {
      return value ? '1' : '0';
    }
    if (value is int) {
      return value == 1 ? '1' : '0';
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return (normalized == '1' || normalized == 'true') ? '1' : '0';
    }
    return '0';
  }

  Future<bool> _goodsRequestHasFiles(
    List<File> images,
    List<Map<String, dynamic>> variants,
  ) async {
    for (final image in images) {
      if (await image.exists()) {
        return true;
      }
    }

    for (final variant in variants) {
      final variantFiles = variant['files'];
      if (variantFiles is! List) continue;

      for (final file in variantFiles) {
        if (file is File && await file.exists()) {
          return true;
        }
      }
    }

    return false;
  }

  Future<Map<String, dynamic>> _buildGoodsRequestBody({
    required bool isService,
    required String name,
    String? barcode,
    required int parentId,
    required String description,
    required int? quantity,
    required int? unitId,
    required List<Map<String, dynamic>> attributes,
    required List<Map<String, dynamic>> variants,
    required bool isActive,
    required double? price,
    required int? storageId,
    required int? labelId,
    required String? productionType,
    required List<Map<String, dynamic>> materialGoods,
    required List<Map<String, dynamic>> relatedGoods,
    String? comments,
  }) async {
    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    final body = <String, dynamic>{
      'name': name,
      'barcode': barcode,
      'category_id': parentId.toString(),
      'label_id': labelId?.toString(),
      'quantity': quantity?.toString() ?? 'null',
      'description': description,
      'unit_id': unitId?.toString(),
      'is_active': isActive ? '1' : '0',
      'is_popular': '0',
      'is_new': '0',
      'is_sale': '0',
      'is_service': isService ? '1' : '0',
      'is_subscription': '0',
      'price': (price ?? 0).toString(),
      'organization_id': organizationId ?? '1',
      'sales_funnel_id': salesFunnelId ?? '1',
    };

    if (productionType != null && productionType.isNotEmpty) {
      body['production_type'] = productionType;
    }

    if (storageId != null) {
      body['storage_id'] = storageId.toString();
      body['branch_id'] = storageId.toString();
    }

    if (comments != null && comments.isNotEmpty) {
      body['comments'] = comments;
    }

    if (barcode != null && barcode.isNotEmpty) {
      body['barcode'] = barcode;
    }

    if (attributes.isNotEmpty) {
      body['attributes'] = attributes
          .map((attribute) => {
                'category_attribute_id':
                    attribute['category_attribute_id']?.toString(),
                'value': attribute['value']?.toString(),
              })
          .toList();
    }

    if (variants.isNotEmpty) {
      body['variants'] = variants.map((variant) {
        final item = <String, dynamic>{
          'is_active': _boolToMultipartFlag(variant['is_active']),
          'price': (variant['price'] ?? 0).toString(),
        };

        if (variant['id'] != null) {
          item['id'] = variant['id'].toString();
        }

        if (variant['barcode'] != null &&
            variant['barcode'].toString().isNotEmpty) {
          item['barcode'] = variant['barcode'].toString();
        }

        final variantAttributes =
            (variant['variant_attributes'] as List<dynamic>? ?? []).map((attr) {
          final map = <String, dynamic>{
            'category_attribute_id': attr['category_attribute_id']?.toString(),
            'value': attr['value']?.toString(),
          };

          if (attr['id'] != null) {
            map['id'] = attr['id'].toString();
          }

          return map;
        }).toList();

        if (variantAttributes.isNotEmpty) {
          item['variant_attributes'] = variantAttributes;
        }

        return item;
      }).toList();
    }

    if (materialGoods.isNotEmpty) {
      body['good_ids'] = materialGoods
          .map((material) => {
                'good_id': material['good_id']?.toString(),
                'norm': material['norm']?.toString(),
              })
          .toList();
    }

    body['related_goods'] = relatedGoods
        .where((related) => related['variant_id'] != null)
        .map((related) => {
              'variant_id': related['variant_id']?.toString(),
              'is_required': _boolToMultipartFlag(related['is_required']),
            })
        .toList();

    return body;
  }

  Future<http.Response> _patchRequest(
      String path, Map<String, dynamic> body) async {
    if (!await _isSessionValid()) {
      await _forceLogoutAndRedirect();
      throw Exception('Session is invalid');
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final fullUrl = '$baseUrl$updatedPath';

    // HTTP Inspector: Создаем лог запроса (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'PATCH',
        url: fullUrl,
        requestBody: json.encode(body),
      ));
    }

    final startTime = DateTime.now();
    try {
      final response = await http.patch(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Device': 'mobile'
        },
        body: json.encode(body),
      );

      // HTTP Inspector: Обновляем лог с ответом (только в DEBUG)
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: DateTime.now().difference(startTime),
            ),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger()
              .updateLog(logId, existingLog.copyWith(error: e.toString()));
        }
      }
      rethrow;
    }
  }

  Future<http.Response> _putRequest(
      String path, Map<String, dynamic> body) async {
    if (!await _isSessionValid()) {
      await _forceLogoutAndRedirect();
      throw Exception('Session is invalid');
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final fullUrl = '$baseUrl$updatedPath';

    // HTTP Inspector: Создаем лог запроса (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'PUT',
        url: fullUrl,
        requestBody: json.encode(body),
      ));
    }

    final startTime = DateTime.now();
    try {
      final response = await http.put(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Device': 'mobile'
        },
        body: json.encode(body),
      );

      // HTTP Inspector: Обновляем лог с ответом (только в DEBUG)
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: DateTime.now().difference(startTime),
            ),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger()
              .updateLog(logId, existingLog.copyWith(error: e.toString()));
        }
      }
      rethrow;
    }
  }

  Future<http.Response> _deleteRequest(String path) async {
    if (!await _isSessionValid()) {
      await _forceLogoutAndRedirect();
      throw Exception('Session is invalid');
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final fullUrl = '$baseUrl$updatedPath';

    // HTTP Inspector: Создаем лог запроса (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'DELETE',
        url: fullUrl,
      ));
    }

    final startTime = DateTime.now();
    try {
      final response = await http.delete(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Device': 'mobile'
        },
      );

      // HTTP Inspector: Обновляем лог с ответом (только в DEBUG)
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: DateTime.now().difference(startTime),
            ),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger()
              .updateLog(logId, existingLog.copyWith(error: e.toString()));
        }
      }
      rethrow;
    }
  }

  Future<http.Response> _deleteRequestWithBody(
      String path, Map<String, dynamic> body) async {
    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final request = http.Request('DELETE', Uri.parse('$baseUrl$updatedPath'));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Device': 'mobile'
    });
    request.body = json.encode(body);

    // HTTP Inspector: логируем DELETE с body (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'DELETE',
        url: request.url.toString(),
        requestHeaders:
            request.headers.map((k, v) => MapEntry(k, v.toString())),
        requestBody: json.encode(body),
      ));
    }

    final startTime = DateTime.now();
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (kDebugMode && logId != null) {
      final existingLog = HttpLogger().getLogById(logId);
      if (existingLog != null) {
        HttpLogger().updateLog(
          logId,
          existingLog.copyWith(
            statusCode: response.statusCode,
            responseHeaders: response.headers,
            responseBody: response.body,
            duration: DateTime.now().difference(startTime),
          ),
        );
      }
    }

    return _handleResponse(response);
  }

  Future<http.Response> _postRequestDomain(
      String path, Map<String, dynamic> body) async {
    final enteredDomainMap = await getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    final String domainUrl = 'https://$enteredMainDomain/api';
    final token = await getToken();
    final updatedPath =
        await _appendQueryParams(path); // Уже использует _appendQueryParams
    final response = await http.post(
      Uri.parse('$domainUrl$updatedPath'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'Device': 'mobile'
      },
      body: json.encode(body),
    );
    return response;
  }

  Future<String> _appendQueryParams(String path) async {
    try {
      // Парсим существующий URI
      final uri = Uri.parse(path);
      // Используем queryParametersAll для сохранения всех значений (включая повторяющиеся ключи)
      final existingParamsAll =
          Map<String, List<String>>.from(uri.queryParametersAll);
      // Получаем ID из SharedPreferences
      final organizationId = await getSelectedOrganization();
      final salesFunnelId = await getSelectedSalesFunnel();

      // ✅ Добавляем organization_id ТОЛЬКО если его нет
      if (organizationId != null &&
          organizationId.isNotEmpty &&
          organizationId != 'null' &&
          !existingParamsAll.containsKey('organization_id')) {
        existingParamsAll['organization_id'] = [organizationId];
      }

      // ✅ Добавляем sales_funnel_id ТОЛЬКО если его нет
      if (salesFunnelId != null &&
          salesFunnelId.isNotEmpty &&
          salesFunnelId != 'null' &&
          !existingParamsAll.containsKey('sales_funnel_id')) {
        existingParamsAll['sales_funnel_id'] = [salesFunnelId];
      }

      // Собираем query string вручную для сохранения всех значений
      final queryParts = <String>[];
      existingParamsAll.forEach((key, values) {
        for (final value in values) {
          queryParts
              .add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
        }
      });

      final queryString =
          queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
      final result = '${uri.path}$queryString';

      debugPrint('✅ _appendQueryParams: $path → $result');
      return result;
    } catch (e) {
      debugPrint('❌ _appendQueryParams error: $e');
      return path;
    }
  }

  /// Возвращает сообщение об ошибке по коду статуса
  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Неверные данные для создания статуса';
      case 401:
        return 'Необходима авторизация';
      case 403:
        return 'Недостаточно прав для создания статуса';
      case 404:
        return 'Ресурс не найден';
      case 409:
        return 'Статус с таким названием уже существует';
      case 500:
        return 'Внутренняя ошибка сервера';
      default:
        return 'Произошла ошибка при создании статуса (код: $statusCode)';
    }
  }
}
