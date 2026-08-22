part of '../api_service.dart';

extension ApiAuthX on ApiService {
  Future<LoginResponse> login(LoginModel loginModel) async {
    debugPrint('ApiService: Starting login process');
    debugPrint('ApiService: Login model: ${json.encode(loginModel.toJson())}');

    final organizationId = await getSelectedOrganization();
    debugPrint('ApiService: Using organization_id: $organizationId');

    // Проверяем baseUrl перед запросом
    if (baseUrl == null) {
      debugPrint('ApiService: baseUrl is null, trying to initialize');
      await _initializeIfDomainExists();
      if (baseUrl == null) {
        throw Exception('Failed to initialize baseUrl for login');
      }
    }
    debugPrint('ApiService: Current baseUrl: $baseUrl');

    final response = await _postRequest(
      '/login${organizationId != null ? '?organization_id=$organizationId' : ''}',
      loginModel.toJson(),
    );

    if (kDebugMode) {
      debugPrint('ApiService: login - Response: ${response.body}');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final loginResponse = LoginResponse.fromJson(data);

      await _saveToken(loginResponse.token);
      await savePermissions(loginResponse.permissions);

      // Проверяем organization_id из ответа
      String? effectiveOrgId = loginResponse.organizationId;
      if (effectiveOrgId != null && effectiveOrgId.isNotEmpty) {
        await saveSelectedOrganization(effectiveOrgId);
        if (kDebugMode) {
          debugPrint(
              'ApiService: login - Saved organization_id from response: $effectiveOrgId');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              'ApiService: login - Warning: organization_id is null, trying /organization');
        }
        // Пробуем получить organization_id из /organization
        try {
          final organizationsResponse = await _getRequest('/organization');
          if (organizationsResponse.statusCode == 200) {
            final organizations = json.decode(organizationsResponse.body);
            if (kDebugMode) {
              debugPrint(
                  'ApiService: login - /organization response: $organizations');
            }
            if (organizations is List && organizations.isNotEmpty) {
              effectiveOrgId = organizations[0]['id']?.toString();
              if (effectiveOrgId != null && effectiveOrgId.isNotEmpty) {
                await saveSelectedOrganization(effectiveOrgId);
                if (kDebugMode) {
                  debugPrint(
                      'ApiService: login - Saved organization_id from /organization: $effectiveOrgId');
                }
              } else {
                effectiveOrgId = '1'; // Дефолт id = 1
                await saveSelectedOrganization(effectiveOrgId);
                if (kDebugMode) {
                  debugPrint(
                      'ApiService: login - No valid organization_id, using default: $effectiveOrgId');
                }
              }
            } else {
              effectiveOrgId = '1'; // Дефолт id = 1
              await saveSelectedOrganization(effectiveOrgId);
              if (kDebugMode) {
                debugPrint(
                    'ApiService: login - Empty organizations list, using default: $effectiveOrgId');
              }
            }
          } else {
            effectiveOrgId = '1'; // Дефолт id = 1
            await saveSelectedOrganization(effectiveOrgId);
            if (kDebugMode) {
              debugPrint(
                  'ApiService: login - Failed to fetch /organization, using default: $effectiveOrgId');
            }
          }
        } catch (e) {
          effectiveOrgId = '1'; // Дефолт id = 1
          await saveSelectedOrganization(effectiveOrgId);
          if (kDebugMode) {
            debugPrint(
                'ApiService: login - Exception fetching /organization: $e, using default: $effectiveOrgId');
          }
        }
      }

      debugPrint('ApiService: Login successful, token saved');
      return loginResponse;
    } else {
      if (kDebugMode) {
        debugPrint(
            'ApiService: login - Error: Status ${response.statusCode}, Body: ${response.body}');
      }

      // Извлекаем сообщение об ошибке из ответа сервера
      String errorMessage = 'Неправильный Логин или Пароль!';
      try {
        final errorData = json.decode(response.body);
        if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      } catch (e) {
        debugPrint('ApiService: login - Error parsing error response: $e');
      }

      throw Exception('$errorMessage Status: ${response.statusCode}');
    }
  }

  Future<void> savePermissions(List<String> permissions) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('permissions', permissions);
    // ////debugPrint('Сохранённые права доступа: ${prefs.getStringList('permissions')}');
  }

  Future<List<String>> getPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final permissions = prefs.getStringList('permissions') ?? [];
    // ////debugPrint('Извлечённые права доступа: $permissions');
    return permissions;
  }

  Future<bool> hasPermission(String permission) async {
    final permissions = await getPermissions();
    return permissions.contains(permission);
  }

  Future<List<String>> fetchPermissionsByRoleId() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/get-all-permissions');
    if (kDebugMode) {
      //debugPrint('ApiService: fetchPermissionsByRoleId - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['permissions'] != null) {
          // Преобразование списка разрешений в List<String>
          return (data['permissions'] as List<dynamic>)
              .map((permission) => permission as String)
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка при получении прав доступа!!');
      }
    } catch (e) {
      ////debugPrint('Ошибка при выполнении запроса fetchPermissionsByRoleId: $e');
      rethrow;
    }
  }

  Future<bool> checkUserAccess(int userId) async {
    final response = await _postRequest(
      '/check-access/$userId',
      {'id': userId},
    );

    if (response.statusCode == 200) {
      final decodedJson = json.decode(response.body);
      final result = decodedJson['result'];

      if (result is bool) {
        return result;
      }

      if (result is num) {
        return result != 0;
      }

      if (result is String) {
        final normalized = result.toLowerCase().trim();
        return normalized == 'true' || normalized == '1';
      }
    }

    throw Exception('Не удалось проверить доступ пользователя');
  }

  Future<ForgotPinResponse> forgotPin(LoginModel loginModel) async {
    try {
      final organizationId = await getSelectedOrganization();
      final url =
          '/forgotPin${organizationId != null ? '?organization_id=$organizationId' : ''}';

      final response = await _postRequest(
        url,
        {
          'login': loginModel.login,
          'password': loginModel.password,
        },
      );

      // ✅ Успешный ответ
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);

        if (decodedJson['result'] != null) {
          return ForgotPinResponse.fromJson(decodedJson['result']);
        } else {
          throw Exception('Не удалось получить временный PIN.');
        }
      }
      // 🔴 Ошибка валидации (422)
      else if (response.statusCode == 422) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);

        // Приоритет 1: message
        if (decodedJson['message'] != null &&
            decodedJson['message'].toString().isNotEmpty) {
          throw Exception(decodedJson['message']);
        }
        // Приоритет 2: errors.login[0]
        else if (decodedJson['errors'] != null) {
          if (decodedJson['errors']['login'] != null) {
            final loginErrors = decodedJson['errors']['login'] as List;
            if (loginErrors.isNotEmpty) {
              throw Exception(loginErrors[0]);
            }
          }
          // Общая ошибка из errors
          throw Exception('Проверьте введённые данные');
        }
        // Fallback
        else {
          throw Exception('Неверный логин или пользователь не найден');
        }
      }
      // 🔴 Некорректный запрос (400)
      else if (response.statusCode == 400) {
        throw Exception('Некорректные данные запроса');
      }
      // 🔴 Другие ошибки
      else {
        throw Exception('Ошибка сервера (${response.statusCode})');
      }
    } catch (e) {
      // Пробрасываем исключение для обработки в BLoC
      rethrow;
    }
  }
}
