part of '../api_service.dart';

extension ApiInitX on ApiService {
  Future<void> _initializeIfDomainExists() async {
    // ApiService создаётся и на экране авторизации. При отсутствии токена
    // это обычное состояние, поэтому нельзя запускать принудительную
    // навигацию на AuthScreen из конструктора каждого экземпляра.
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    // Сначала проверяем валидность сессии
    if (!await _isSessionValid()) {
      // debugPrint('ApiService: Session is invalid, redirecting to auth');
      await _forceLogoutAndRedirect();
      return;
    }

    // Проверяем новую логику (email)
    String? verifiedDomain = await getVerifiedDomain();
    if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
      await initialize();
      return;
    }

    // Проверяем данные QR-кода
    Map<String, String?> qrData = await getQrData();
    String? qrDomain = qrData['domain'];
    String? qrMainDomain = qrData['mainDomain'];

    if (qrDomain != null &&
        qrDomain.isNotEmpty &&
        qrMainDomain != null &&
        qrMainDomain.isNotEmpty) {
      await initialize();
      return;
    }

    // Проверяем старую логику
    bool isDomainSet = await isDomainChecked();
    if (isDomainSet) {
      await initialize();
    } else {
      // Если ничего не найдено, перенаправляем на авторизацию
      await _forceLogoutAndRedirect();
    }
  }

  Future<void> initialize() async {
    // ОПТИМИЗАЦИЯ: Пропускаем если уже инициализирован
    if (_isInitialized && baseUrl != null) {
      return;
    }

    // ОПТИМИЗАЦИЯ: Пропускаем если уже идет инициализация
    if (_isInitializing) {
      // Ждем завершения текущей инициализации
      while (_isInitializing) {
        await Future.delayed(Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;

    try {
      debugPrint('ApiService: Starting initialization');

      // Получаем базовый URL
      String dynamicBaseUrl = await getDynamicBaseUrl();

      // Проверяем что URL валидный
      if (dynamicBaseUrl.isEmpty || dynamicBaseUrl.contains('null')) {
        throw Exception(
            'Получен недействительный базовый URL: $dynamicBaseUrl');
      }

      baseUrl = dynamicBaseUrl;
      _isInitialized = true;
      debugPrint('ApiService: Initialized with baseUrl: $baseUrl');
    } catch (e) {
      debugPrint('ApiService: initialize error: $e');

      // Пытаемся установить fallback значения
      try {
        await _setFallbackDomain();
        baseUrl = await getDynamicBaseUrl();
        _isInitialized = true;
        debugPrint('ApiService: Fallback initialization successful: $baseUrl');
      } catch (fallbackError) {
        debugPrint(
            'ApiService: Fallback initialization failed: $fallbackError');
        throw Exception('Не удалось инициализировать ApiService: $e');
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _setFallbackDomain() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Проверяем, есть ли сохраненные данные пользователя
    String? userId = prefs.getString('userID');
    String? token = prefs.getString('token');

    if (userId != null && token != null) {
      // Используем базовые значения для восстановления подключения
      String fallbackMainDomain = 'shamcrm.com';
      String fallbackDomain =
          'default'; // Замените на реальный домен организации

      await prefs.setString('enteredMainDomain', fallbackMainDomain);
      await prefs.setString('enteredDomain', fallbackDomain);

      debugPrint(
          'ApiService: Set fallback domain: $fallbackDomain-back.$fallbackMainDomain');
    } else {
      throw Exception('Нет данных для восстановления подключения');
    }
  }

  Future<void> initializeWithDomain(String domain, String mainDomain) async {
    baseUrl = 'https://$domain-back.$mainDomain/api';
    baseUrlSocket = 'https://$domain-back.$mainDomain/broadcasting/auth';
    // debugPrint('Initialized baseUrl: $baseUrl, baseUrlSocket: $baseUrlSocket');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('domain', domain);
    await prefs.setString('mainDomain', mainDomain);
  }

  Future<String> getDynamicBaseUrl() async {
    try {
      // Сначала пробуем новую логику с email
      String? verifiedDomain = await getVerifiedDomain();
      if (verifiedDomain != null &&
          verifiedDomain.isNotEmpty &&
          verifiedDomain != 'null') {
        return 'https://$verifiedDomain/api';
      }

      // Проверяем QR данные
      String? qrDomain = await _getQrDomain();
      if (qrDomain != null && qrDomain.isNotEmpty && qrDomain != 'null') {
        return 'https://$qrDomain/api';
      }

      // Используем старую логику для обратной совместимости
      Map<String, String?> domains = await getEnteredDomain();
      String? mainDomain = domains['enteredMainDomain'];
      String? domain = domains['enteredDomain'];

      if (domain != null &&
          domain.isNotEmpty &&
          domain != 'null' &&
          mainDomain != null &&
          mainDomain.isNotEmpty &&
          mainDomain != 'null') {
        return 'https://$domain-back.$mainDomain/api';
      } else {
        throw Exception(
            'Домен не установлен или содержит недействительные значения');
      }
    } catch (e) {
      debugPrint('getDynamicBaseUrl error: $e');
      throw Exception('Не удалось определить базовый URL: $e');
    }
  }

  Future<String> getSocketBaseUrl() async {
    // Сначала пробуем новую логику с email
    String? verifiedDomain = await getVerifiedDomain();
    if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
      return 'https://$verifiedDomain/broadcasting/auth';
    }

    // Если нет, используем старую логику для обратной совместимости
    Map<String, String?> domains = await getEnteredDomain();
    String? mainDomain = domains['enteredMainDomain'];
    String? domain = domains['enteredDomain'];

    if (domain != null && domain.isNotEmpty) {
      return 'https://$domain-back.$mainDomain/broadcasting/auth';
    } else {
      throw Exception('Домен не установлен');
    }
  }

  Future<String?> getCurrentTenantSubdomain() async {
    final verifiedDomain = await getVerifiedDomain();
    if (verifiedDomain != null &&
        verifiedDomain.isNotEmpty &&
        verifiedDomain != 'null') {
      final host =
          Uri.tryParse('https://$verifiedDomain')?.host ?? verifiedDomain;
      final parts = host.split('.');
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        return parts.first;
      }
    }

    final qrDomain = await _getQrDomain();
    if (qrDomain != null && qrDomain.isNotEmpty && qrDomain != 'null') {
      final host = Uri.tryParse('https://$qrDomain')?.host ?? qrDomain;
      final parts = host.split('.');
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        return parts.first;
      }
    }

    final enteredDomains = await getEnteredDomain();
    final domain = enteredDomains['enteredDomain'];
    if (domain != null && domain.isNotEmpty && domain != 'null') {
      return domain.endsWith('-back') ? domain : '${domain}-back';
    }

    return null;
  }

  Future<bool> isTojsokhtmontjTenant() async {
    final subdomain = await getCurrentTenantSubdomain();
    return subdomain != null && ApiService._tojsokhtmontjSubdomains.contains(subdomain);
  }

  Future<bool> isStomatradeTenant() async {
    final subdomain = await getCurrentTenantSubdomain();
    return subdomain != null && ApiService._stomatradeSubdomains.contains(subdomain);
  }

  Future<bool> isFuzaylovazamTenant() async {
    final subdomain = await getCurrentTenantSubdomain();
    return subdomain != null &&
        ApiService._fuzaylovazamSubdomains.contains(subdomain);
  }

  Future<bool> isRetisegTenant() async {
    final subdomain = await getCurrentTenantSubdomain();
    return subdomain != null &&
        ApiService._retisegSubdomains.contains(subdomain);
  }

  // Итого в приходе и расходе денег: как в продажах, только на двух доменах.
  Future<bool> supportsCheckingAccountSum() async {
    return await isFuzaylovazamTenant() || await isRetisegTenant();
  }

  Future<bool> isFingroupcrmTenant() async {
    final subdomain = await getCurrentTenantSubdomain();
    return subdomain != null &&
        ApiService._fingroupcrmSubdomains.contains(subdomain);
  }

  Future<Set<String>> _currentUserRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final roles = <String>{};

    void addRoleSource(String? raw) {
      if (raw == null || raw.isEmpty) return;
      for (final part in raw.split(',')) {
        final role = part.trim().toLowerCase();
        if (role.isNotEmpty) roles.add(role);
      }
    }

    addRoleSource(prefs.getString('userRoleName'));
    addRoleSource(prefs.getString('userRoles'));
    final cachedRoles = prefs.getStringList('cached_user_roles');
    if (cachedRoles != null) {
      for (final role in cachedRoles) {
        addRoleSource(role);
      }
    }

    if (roles.isEmpty) {
      final userId = prefs.getString('userID');
      if (userId != null && userId.isNotEmpty) {
        try {
          final profile = await getUserById(int.parse(userId));
          for (final role in profile.role ?? []) {
            addRoleSource(role.name);
          }
        } catch (_) {}
      }
    }

    return roles;
  }

  Future<bool> isAdminRole() async {
    final roles = await _currentUserRoles();
    return roles.contains('admin');
  }

  Future<bool> isAdminOrManagerRole() async {
    final roles = await _currentUserRoles();
    return roles.contains('admin') || roles.contains('manager');
  }

  Future<void> ensureInitialized() async {
    if (baseUrl != null && baseUrl!.isNotEmpty) return;

    await initialize(); // твой текущий initialize()
    if (baseUrl == null || baseUrl!.isEmpty) {
      await _initializeIfDomainExists(); // если есть сохранённый домен
    }
  }

  Future<String?> _getQrDomain() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? domain = prefs.getString('domain');
    String? mainDomain = prefs.getString('mainDomain');

    if (domain != null &&
        domain.isNotEmpty &&
        mainDomain != null &&
        mainDomain.isNotEmpty) {
      return '$domain-back.$mainDomain';
    }
    return null;
  }

  Future<void> initializeFromQrData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? domain = prefs.getString('domain');
    String? mainDomain = prefs.getString('mainDomain');

    if (domain != null &&
        domain.isNotEmpty &&
        mainDomain != null &&
        mainDomain.isNotEmpty) {
      baseUrl = 'https://$domain-back.$mainDomain/api';
      baseUrlSocket = 'https://$domain-back.$mainDomain/broadcasting/auth';
      debugPrint(
          'Initialized baseUrl: $baseUrl, baseUrlSocket: $baseUrlSocket');
      debugPrint('Saved domain: $domain, mainDomain: $mainDomain');
    } else {
      throw Exception('QR данные не найдены в SharedPreferences');
    }
  }

  Future<void> saveQrData(String domain, String mainDomain, String login,
      String token, String userId, String organizationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('domain', domain);
    await prefs.setString('mainDomain', mainDomain);
    await prefs.setString('userLogin', login);
    await prefs.setString('token', token);
    await prefs.setString('userID', userId);
    await prefs.setString('selectedOrganization', organizationId);

    // Сразу инициализируем baseUrl после сохранения данных
    await initializeFromQrData();

    if (kDebugMode) {
      debugPrint(
          'ApiService: saveQrData - domain: $domain, mainDomain: $mainDomain, organizationId: $organizationId');
      debugPrint('ApiService: saveQrData - baseUrl after init: $baseUrl');
    }
  }

  Future<Map<String, String?>> getQrData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? domain = prefs.getString('domain') ?? '';
    String? mainDomain = prefs.getString('mainDomain') ?? '';

    String? login = prefs.getString('userLogin') ?? '';
    String? token = prefs.getString('token') ?? '';
    String userId = prefs.getString('userID') ?? '';
    String? organizationId = prefs.getString('selectedOrganization') ?? '';
    return {
      'domain': domain,
      'mainDomain': mainDomain,
      'login': login,
      'token': token,
      'userID': userId,
      'selectedOrganization': organizationId
    };
  }

  Future<DomainCheck> checkDomain(String domain) async {
    ////debugPrint(
    // '-=--=-=-=-=-=-=-==-=-=-=CHECK-DOMAIN-=--==-=-=--=-==--==-=-=-=-=-=-=-');
    ////debugPrint(domain);
    // Эндпоинт /checkDomain входит в ApiService._excludedEndpoints, поэтому не используем _appendQueryParams
    final organizationId = await getSelectedOrganization();
    final response = await _postRequestDomain(
        '/checkDomain${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {'domain': domain});

    if (response.statusCode == 200) {
      return DomainCheck.fromJson(json.decode(response.body));
    } else {
      throw Exception('Не удалось загрузить поддомен!');
    }
  }

  Future<void> saveDomainChecked(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'domainChecked', value); // Сохраняем статус проверки домена
  }

  Future<bool> isDomainChecked() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('domainChecked') ??
        false; // Проверяем статус или возвращаем false
  }

  Future<void> saveDomain(String domain, String mainDomain) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('enteredMainDomain', mainDomain);
    await prefs.setString('enteredDomain', domain);
    ////debugPrint('Ввведеный Doмен:----------------------');
    ////debugPrint('ДОМЕН: ${prefs.getString('enteredMainDomain')}');
    ////debugPrint('Ввведеный Poddomen---=----:----------------------');
    ////debugPrint('ПОДДОМЕН: ${prefs.getString('enteredDomain')}');
  }

  Future<Map<String, String?>> getEnteredDomain() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mainDomain = prefs.getString('enteredMainDomain');
    String? domain = prefs.getString('enteredDomain');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getEnteredDomain - mainDomain: $mainDomain, domain: $domain');
    }
    return {
      'enteredMainDomain': mainDomain,
      'enteredDomain': domain,
    };
  }

  Future<String> getStaticBaseUrl() async {
    debugPrint('🔍 [ApiService] Начинаем получение StaticBaseUrl...');

    // Сначала пробуем новую логику с email
    String? verifiedDomain = await getVerifiedDomain();
    debugPrint('🔍 [ApiService] verifiedDomain: "$verifiedDomain"');

    if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
      final result = 'https://$verifiedDomain/storage';
      debugPrint('✅ [ApiService] Используем verifiedDomain: "$result"');
      return result;
    }

    // Проверяем QR данные
    Map<String, String?> qrData = await getQrData();
    String? qrDomain = qrData['domain'];
    String? qrMainDomain = qrData['mainDomain'];
    debugPrint(
        '🔍 [ApiService] qrDomain: "$qrDomain", qrMainDomain: "$qrMainDomain"');

    if (qrDomain != null &&
        qrDomain.isNotEmpty &&
        qrMainDomain != null &&
        qrMainDomain.isNotEmpty) {
      final result = 'https://$qrDomain-back.$qrMainDomain/storage';
      debugPrint('✅ [ApiService] Используем QR данные: "$result"');
      return result;
    }

    // Если нет, используем старую логику для обратной совместимости
    Map<String, String?> domains = await getEnteredDomain();
    String? mainDomain = domains['enteredMainDomain'];
    String? domain = domains['enteredDomain'];
    debugPrint(
        '🔍 [ApiService] enteredDomain: "$domain", enteredMainDomain: "$mainDomain"');

    if (domain != null &&
        domain.isNotEmpty &&
        mainDomain != null &&
        mainDomain.isNotEmpty) {
      final result = 'https://$domain-back.$mainDomain/storage';
      debugPrint('✅ [ApiService] Используем entered domains: "$result"');
      return result;
    } else {
      // Fallback на дефолтный домен, если ничего не найдено
      const result = 'https://shamcrm.com/storage';
      debugPrint('⚠️ [ApiService] Используем fallback URL: "$result"');
      return result;
    }
  }

  Future<String> getFileUrl(String filePath) async {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    final baseUrl = await getStaticBaseUrl();
    // Убираем лишние слеши, если они есть в начале filePath
    final cleanPath =
        filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$baseUrl/$cleanPath';
  }
}
