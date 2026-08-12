part of '../api_service.dart';

extension ApiMiscX on ApiService {
  Future<Map<String, dynamic>> getCustomFields() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/get/custom-fields');
    if (kDebugMode) {
      //debugPrint('ApiService: getCustomFields - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return data; // Возвращаем данные, если они есть
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<MainFieldResponse> getMainFields(int directoryId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/directory/getMainFields/$directoryId');
    if (kDebugMode) {
      //debugPrint('ApiService: getMainFields - Generated path: $path');
    }

    ////debugPrint('Вызов getMainFields для directoryId: $directoryId');
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Ответ getMainFields для directoryId $directoryId: $data');
      if (data['result'] != null) {
        return MainFieldResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw Exception('Внутренняя ошибка сервера');
    } else {
      throw Exception('Ошибка при получении данных справочника!');
    }
  }

  Future<Map<String, dynamic>> getMyCustomFields() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task/get/custom-fields');
    if (kDebugMode) {
      //debugPrint('ApiService: getMyCustomFields - Generated path: $path');
    }

    // Выполняем запрос
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return data; // Возвращаем данные, если они есть
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<FieldConfigurationResponse> getFieldPositions({
    required String tableName,
  }) async {
    try {
      final path = await _appendQueryParams('/field-position?table=$tableName');

      if (kDebugMode) {
        debugPrint('ApiService: getFieldPositions - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FieldConfigurationResponse.fromJson(data);
      } else {
        throw Exception(
            'Ошибка загрузки конфигурации полей: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: getFieldPositions - Error: $e');
      }
      throw Exception('Ошибка загрузки конфигурации полей!');
    }
  }

  Future<void> cacheFieldConfiguration({
    required String tableName,
    required FieldConfigurationResponse configuration,
  }) async {
    // Кэширование конфигурации временно отключено.
    // try {
    //   final prefs = await SharedPreferences.getInstance();
    //   final organizationId = await getSelectedOrganization();
    //   final cacheKey = 'field_config_${tableName}_org_${organizationId}';
    //
    //   final jsonData = json.encode(configuration.toJson());
    //   await prefs.setString(cacheKey, jsonData);
    //
    //   // Сохраняем timestamp последнего обновления
    //   await prefs.setInt('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    //
    //   if (kDebugMode) {
    //     debugPrint('ApiService: Cached field configuration for $tableName');
    //   }
    // } catch (e) {
    //   if (kDebugMode) {
    //     debugPrint('ApiService: Error caching field configuration: $e');
    //   }
    // }
  }

  Future<FieldConfigurationResponse?> getCachedFieldConfiguration({
    required String tableName,
  }) async {
    // Кэширование конфигурации временно отключено, всегда возвращаем null.
    return null;
    // try {
    //   final prefs = await SharedPreferences.getInstance();
    //   final organizationId = await getSelectedOrganization();
    //   final cacheKey = 'field_config_${tableName}_org_${organizationId}';
    //
    //   final cachedData = prefs.getString(cacheKey);
    //
    //   if (cachedData != null) {
    //     final jsonData = json.decode(cachedData);
    //     final config = FieldConfigurationResponse.fromJson(jsonData);
    //
    //     if (kDebugMode) {
    //       debugPrint('ApiService: Loaded cached field configuration for $tableName');
    //     }
    //
    //     return config;
    //   }
    //
    //   return null;
    // } catch (e) {
    //   if (kDebugMode) {
    //     debugPrint('ApiService: Error loading cached field configuration: $e');
    //   }
    //   return null;
    // }
  }

  Future<void> loadAndCacheAllFieldConfigurations() async {
    try {
      if (kDebugMode) {
        debugPrint('ApiService: Loading all field configurations');
      }

      final tables = ['leads', 'tasks', 'deals', 'orders'];

      for (final tableName in tables) {
        try {
          final config = await getFieldPositions(tableName: tableName);
          // not used as this method is not used
          await cacheFieldConfiguration(
              tableName: tableName, configuration: config);

          if (kDebugMode) {
            debugPrint(
                'ApiService: Successfully cached configuration for $tableName');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'ApiService: Error loading configuration for $tableName: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('ApiService: Finished loading all field configurations');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ApiService: Error in loadAndCacheAllFieldConfigurations: $e');
      }
    }
  }

  Future<void> clearFieldConfigurationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final organizationId = await getSelectedOrganization();

      final tables = ['leads', 'tasks', 'deals', 'orders'];

      for (final tableName in tables) {
        final cacheKey = 'field_config_${tableName}_org_${organizationId}';
        await prefs.remove(cacheKey);
        await prefs.remove('${cacheKey}_timestamp');
      }

      if (kDebugMode) {
        debugPrint('ApiService: Cleared all field configuration cache');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: Error clearing field configuration cache: $e');
      }
    }
  }

  Future<void> clearFieldConfigurationCacheForTable(String tableName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final organizationId = await getSelectedOrganization();

      final cacheKey = 'field_config_${tableName}_org_$organizationId';
      await prefs.remove(cacheKey);
      await prefs.remove('${cacheKey}_timestamp');

      if (kDebugMode) {
        debugPrint(
            'ApiService: Cleared field configuration cache for $tableName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ApiService: Error clearing field configuration cache for $tableName: $e');
      }
    }
  }

  Future<Map<String, dynamic>> updateFieldPositions({
    required String tableName,
    required List<Map<String, dynamic>> updates,
  }) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/field-position?table=$tableName');

      if (kDebugMode) {
        debugPrint('ApiService: updateFieldPositions - Generated path: $path');
        debugPrint('ApiService: updateFieldPositions - Updates: $updates');
      }

      // Подготавливаем тело запроса
      final organizationId = await getSelectedOrganization();
      final salesFunnelId = await getSelectedSalesFunnel();

      final normalizedUpdates = updates.map((update) {
        if (update.containsKey('show_on_site')) {
          return {
            ...update,
            'show_to_site': update['show_on_site'],
          }..remove('show_on_site');
        }
        return update;
      }).toList();

      final body = {
        'updates': normalizedUpdates,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
      };

      final response = await _patchRequest(path, body);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('ApiService: Field positions updated successfully');
        }
        return {
          'success': true,
          'message': 'Field positions updated successfully',
        };
      } else {
        throw Exception(
            'Ошибка обновления позиций полей: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: updateFieldPositions - Error: $e');
      }
      throw Exception('Ошибка обновления позиций полей: $e');
    }
  }

  Future<dynamic> addNewField({
    required String tableName,
    required String fieldName,
    required String fieldType,
  }) async {
    final path = await _appendQueryParams('/field-position');
    final body = {
      "table": tableName,
      "field_name": fieldName,
      "type": fieldType
    };

    try {
      final response = await _postRequest(path, body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при добавлении нового поля',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
