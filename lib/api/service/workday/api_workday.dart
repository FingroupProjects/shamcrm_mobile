part of '../api_service.dart';

extension ApiWorkdayX on ApiService {
  Future<bool> canReadTimesheet() {
    return hasPermission(ApiService.workdayReadPermission);
  }

  Future<WorkdayStatusResponse?> getWorkdayStatus() async {
    await ensureSelectedSalesFunnelInitialized();
    final response = await _getRequest('/workday/get-status');

    if (response.statusCode == 200) {
      return WorkdayStatusResponse.fromJson(
        _decodeWorkdayJsonMap(response.body),
      );
    }

    if (response.statusCode == 404) {
      return null;
    }

    throw Exception('Ошибка получения статуса рабочего дня');
  }

  Future<WorkdayStatusResponse> startWorkday({
    required double latitude,
    required double longitude,
    required File photo,
  }) async {
    return _submitWorkdayAction(
      path: '/workday/start',
      timestampField: 'time_start',
      timestamp: DateTime.now().toUtc(),
      latitude: latitude,
      longitude: longitude,
      photo: photo,
      debugLabel: 'startWorkday',
    );
  }

  Future<WorkdayStatusResponse> endWorkday({
    required double latitude,
    required double longitude,
    required File photo,
  }) async {
    return _submitWorkdayAction(
      path: '/workday/end',
      timestampField: 'time_end',
      timestamp: DateTime.now().toUtc(),
      latitude: latitude,
      longitude: longitude,
      photo: photo,
      debugLabel: 'endWorkday',
    );
  }

  Future<TimesheetListResponse> getTimesheet({
    int page = 1,
    List<String> userIds = const [],
  }) async {
    String path = '/workday?page=$page';
    if (userIds.isNotEmpty) {
      final userQuery = userIds
          .asMap()
          .entries
          .map(
            (entry) =>
                'users%5B${entry.key}%5D=${Uri.encodeQueryComponent(entry.value)}',
          )
          .join('&');
      path = '$path&$userQuery';
    }

    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки табеля');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Неожиданный формат табеля');
    }

    return TimesheetListResponse.fromJson(decoded);
  }

  Future<List<TimesheetEntry>> getTimesheetDetails({
    required int userId,
    required String month,
  }) async {
    final response = await _getRequest('/workday/$userId?month=$month');
    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки деталей табеля');
    }

    final decoded = jsonDecode(response.body);
    return parseTimesheetDetails(decoded);
  }

  Future<WorkdayStatusResponse> _submitWorkdayAction({
    required String path,
    required String timestampField,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    required File photo,
    required String debugLabel,
  }) async {
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

    final organizationId = await getSelectedOrganization() ?? '1';
    final salesFunnelId = await ensureSelectedSalesFunnelInitialized() ?? '1';
    final updatedPath = await _appendQueryParams(path);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$updatedPath'),
    );

    request.fields[timestampField] = timestamp.toIso8601String();
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    request.fields['organization_id'] = organizationId;
    request.fields['sales_funnel_id'] = salesFunnelId;
    request.files.add(
      await http.MultipartFile.fromPath('photo', photo.path),
    );

    final response = await _multipartPostRequest(path, request);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return WorkdayStatusResponse.fromJson(
        _decodeWorkdayJsonMap(response.body),
      );
    }

    throw Exception('Ошибка отправки рабочего дня');
  }

  Map<String, dynamic> _decodeWorkdayJsonMap(String body) {
    final decoded = json.decode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception('Неожиданный формат ответа API');
  }

  Future<bool> _shouldHandleWorkdayResponse(http.Response response) async {
    if (!await canReadTimesheet()) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final localPin = prefs.getString('user_pin');
    if (localPin == null || localPin.trim().isEmpty) {
      return false;
    }

    final requestPath = response.request?.url.path ?? '';
    return !requestPath.contains('/workday/');
  }

  Future<void> _handleWorkdayAccessDenied(String message) async {
    final now = DateTime.now();
    final shouldNotify = ApiService._lastWorkdayWarningAt == null ||
        now.difference(ApiService._lastWorkdayWarningAt!) > const Duration(seconds: 2);

    if (shouldNotify) {
      ApiService._lastWorkdayWarningAt = now;
      final messenger = ApiService.scaffoldMessengerKey.currentState;
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF4C7DFF),
          ),
        );
    }

    if (ApiService._isWorkdayRedirectInProgress) {
      return;
    }

    ApiService._isWorkdayRedirectInProgress = true;

    try {
      final navigator = ApiService.navigatorKey.currentState;
      if (navigator == null) return;

      WorkdayProfileRedirectService.requestOpenProfile();
      await navigator.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: const {
          'showWorkdayProfile': true,
        },
      );
    } catch (e) {
      debugPrint('ApiService: workday redirect failed: $e');
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        ApiService._isWorkdayRedirectInProgress = false;
      });
    }
  }
}
