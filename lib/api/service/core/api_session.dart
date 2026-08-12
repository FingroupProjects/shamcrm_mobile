part of '../api_service.dart';

extension ApiSessionX on ApiService {
  void _redirectToLogin() {
    ApiService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/local_auth',
      (route) => false,
    );
  }

  Future<void> reset() async {
    // Сброс значений при выходе
    baseUrl = null;
    baseUrlSocket = null;
    ////debugPrint('API сброшено');
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Получаем токен из SharedPreferences
  }

  Future<void> _saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token); // Сохраняем токен
  }

  Future<void> _removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Удаляем токен
  }

  Future<void> logout() async {
    // Удаляем токен, права доступа и организацию
    await _removeToken();
    await _removePermissions();
    await _removeOrganizationId();

    // Очищаем новые данные email-flow
    await clearEmailVerificationData();

    // Clear widget permissions on iOS (via App Groups)
    await _clearWidgetPermissions();
  }

  Future<void> _clearWidgetPermissions() async {
    try {
      // Import is at the top of the file, but we need to call the static method
      // This will be handled by the WidgetService
      const platform = MethodChannel('com.softtech.crm_task_manager/widget');
      if (Platform.isIOS) {
        await platform.invokeMethod('syncPermissionsToWidget', {
          'permissions': <String>[],
        });
        debugPrint('ApiService: Cleared widget permissions on logout');
      }
    } catch (e) {
      debugPrint('ApiService: Error clearing widget permissions: $e');
    }
  }

  Future<Map<String, String>> getUserByEmail(String email) async {
    const String fixedDomainUrl = 'https://shamcrm.com/api';

    final response = await http.post(
      Uri.parse('$fixedDomainUrl/get-user-by-email'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Device': 'mobile'
      },
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        // debugPrint('ApiService: getUserByEmail - Response: $data');
      }
      final organizationId = data['organization_id']?.toString() ??
          data['user']?['organization_id']?.toString() ??
          '1'; // Дефолт id = 1
      return {
        'domain': data['domain']?.toString() ?? '',
        'login': data['login']?.toString() ?? '',
        'organization_id': organizationId,
      };
    } else {
      if (kDebugMode) {
        // debugPrint(
        //     'ApiService: getUserByEmail - Error: Status ${response.statusCode}, Body: ${response.body}');
      }
      throw Exception('Пользователь с таким email не найден');
    }
  }

  Future<void> saveEmailVerificationData(String domain, String login,
      {String? organizationId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('verifiedDomain', domain);
    await prefs.setString('verifiedLogin', login);

    if (organizationId != null && organizationId.isNotEmpty) {
      await prefs.setString('selectedOrganization', organizationId);
      if (kDebugMode) {
        debugPrint(
            'ApiService: saveEmailVerificationData - Saved organization_id: $organizationId');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
            'ApiService: saveEmailVerificationData - Warning: organization_id is null or empty');
      }
    }

    baseUrl = 'https://$domain/api';
    if (kDebugMode) {
      debugPrint(
          'ApiService: saveEmailVerificationData - Saved domain: $domain, login: $login');
    }
  }

  Future<String?> getVerifiedLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('verifiedLogin');
  }

  Future<String?> getVerifiedDomain() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final verifiedDomain = prefs.getString('verifiedDomain');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getVerifiedDomain - verifiedDomain: $verifiedDomain');
    }
    return verifiedDomain;
  }

  Future<void> initializeWithEmailFlow() async {
    final domain = await getVerifiedDomain();
    final organizationId = await getSelectedOrganization();
    if (domain != null && domain.isNotEmpty) {
      baseUrl = 'https://$domain/api';
      baseUrlSocket = 'https://$domain/broadcasting/auth';
      if (kDebugMode) {
        debugPrint(
            'ApiService: initializeWithEmailFlow - Initialized with domain: $domain, organization_id: $organizationId');
      }
    } else {
      debugPrint(
          'ApiService: initializeWithEmailFlow - Error: verifiedDomain is null');
      throw Exception('Домен не установлен');
    }
  }

  Future<void> clearEmailVerificationData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('verifiedDomain');
    await prefs.remove('verifiedLogin');
  }

  Future<void> _removePermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Выводим в консоль текущие права доступа до удаления
    ////debugPrint('Перед удалением: ${prefs.getStringList('permissions')}');

    // Удаляем права доступа
    await prefs.remove('permissions');

    // Проверяем, что ключ действительно удалён
    ////debugPrint('После удаления: ${prefs.getStringList('permissions')}');
  }

  Future<bool> _isSessionValid() async {
    try {
      // Проверяем токен
      final token = await getToken();
      if (token == null || token.isEmpty) {
        debugPrint('ApiService: Token is null or empty');
        return false;
      }

      // Проверяем домен
      String? domain = await getVerifiedDomain();
      if (domain == null || domain.isEmpty) {
        // Пробуем QR данные
        Map<String, String?> qrData = await getQrData();
        String? qrDomain = qrData['domain'];
        String? qrMainDomain = qrData['mainDomain'];

        if (qrDomain == null ||
            qrDomain.isEmpty ||
            qrMainDomain == null ||
            qrMainDomain.isEmpty) {
          // Пробуем старую логику
          Map<String, String?> domains = await getEnteredDomain();
          String? enteredDomain = domains['enteredDomain'];
          String? enteredMainDomain = domains['enteredMainDomain'];

          if (enteredDomain == null ||
              enteredDomain.isEmpty ||
              enteredMainDomain == null ||
              enteredMainDomain.isEmpty) {
            debugPrint('ApiService: No valid domain found');
            return false;
          }
        }
      }

      // Проверяем организацию
      final organizationId = await getSelectedOrganization();
      if (organizationId == null || organizationId.isEmpty) {
        debugPrint('ApiService: Organization ID is null or empty');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('ApiService: Error checking session validity: $e');
      return false;
    }
  }

  Future<void> _forceLogoutAndRedirect() async {
    if (ApiService._isForceLogoutInProgress) {
      debugPrint(
          'ApiService: Force logout уже выполняется, повторный переход пропущен');
      return;
    }

    // После первого logout токен уже удалён. Не запускаем второй logout и
    // второй переход, если параллельный запрос тоже получил 401.
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    ApiService._isForceLogoutInProgress = true;
    try {
      debugPrint('ApiService: Force logout and redirect to auth');

      // Полная очистка данных
      await logout();
      await reset();

      // Очищаем дополнительные данные
      SharedPreferences prefs = await SharedPreferences.getInstance();
      const appearanceKeys = <String>{
        'app_theme_mode_v1',
        'app_palette_preset_v1',
        'app_background_preset_v1',
        'app_background_image_path_v1',
        'app_background_asset_path_v1',
        'app_background_blur_v1',
        'app_palette_seed_color_v1',
      };
      final preservedAppearanceValues = <String, Object?>{
        for (final key in prefs.getKeys().where(appearanceKeys.contains))
          key: prefs.get(key),
      };
      await prefs.clear();
      for (final entry in preservedAppearanceValues.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }

      // Перенаправляем на экран авторизации
      final context = ApiService.navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/local_auth',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('ApiService: Error in force logout: $e');
    } finally {
      ApiService._isForceLogoutInProgress = false;
    }
  }

  Future<void> logoutAccount() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/logout');
    if (kDebugMode) {
      //debugPrint('ApiService: logoutAccount - Generated path: $path');
    }

    final response = await _postRequest(path, {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка logout аккаунта!');
    }
  }
}
