part of '../api_service.dart';

extension ApiAbsenceX on ApiService {
  bool _hasAbsencePermission(List<String> permissions, String action) {
    final keys = <String>{
      'absence.$action',
      'absence_$action',
      'absence-$action',
    };
    return permissions.any((permission) => keys.contains(permission.toLowerCase().trim()));
  }

  /// Права, роль и признак руководителя отдела.
  /// Раздел виден только при `absence.index` в permissions.
  Future<AbsenceAccess> loadAbsenceAccess() async {
    final permissions = await getPermissions();
    final admin = await isAdminRole();
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.getString('userID');
    final userId = int.tryParse(rawId ?? '');
    var head = false;
    if (userId != null) {
      try {
        final path = await _appendQueryParams('/user/$userId');
        final response = await _absenceSend(() => _getRequest(path));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          head = absenceJsonIsHead(decoded);
        }
      } catch (_) {
        head = false;
      }
    }

    return AbsenceAccess(
      userId: userId,
      canIndexPermission: _hasAbsencePermission(permissions, 'index'),
      canReadPermission: _hasAbsencePermission(permissions, 'read') ||
          permissions.any((item) => item.toLowerCase().trim() == 'absence'),
      canCreatePermission: _hasAbsencePermission(permissions, 'create'),
      canReviewPermission: _hasAbsencePermission(permissions, 'review'),
      canSettingsPermission: _hasAbsencePermission(permissions, 'settings'),
      isAdminRole: admin,
      isHeadOfDepartment: head,
    );
  }

  Future<bool> canOpenAbsenceRequests() async {
    try {
      final access = await loadAbsenceAccess();
      return access.showMenu;
    } catch (_) {
      return false;
    }
  }

  Future<AbsencePage> getMyAbsenceRequests({
    required int page,
    required AbsenceFilters filters,
  }) {
    return _getAbsencePage(
      absenceListPath(mine: true, page: page, filters: filters),
    );
  }

  Future<AbsencePage> getAbsenceRequests({
    required int page,
    required AbsenceFilters filters,
  }) {
    return _getAbsencePage(
      absenceListPath(mine: false, page: page, filters: filters),
    );
  }

  Future<AbsenceStats> getAbsenceStats(AbsenceFilters filters) async {
    final response = await _absenceSend(
      () => _getRequest(absenceStatsPath(filters)),
    );
    final decoded = _absenceDecode(response);
    return parseAbsenceStats(decoded);
  }

  Future<AbsenceRequest> getAbsenceRequest(int id) async {
    final response = await _absenceSend(
      () => _getRequest('/absence-requests/$id'),
    );
    final decoded = _absenceDecode(response);
    final request = parseAbsenceRequestPayload(decoded);
    if (request == null || request.id == 0) {
      throw AbsenceApiException(
        statusCode: response.statusCode,
        message: 'absence_unavailable',
      );
    }
    return request;
  }

  Future<AbsenceRequest?> createAbsenceRequest(Map<String, dynamic> body) async {
    final response = await _absenceSend(
      () => _postRequest('/absence-requests', body),
    );
    _absenceEnsureSuccess(response, created: true);
    return parseAbsenceRequestPayload(_tryDecode(response.body));
  }

  Future<AbsenceRequest?> updateAbsenceRequest(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await _absenceSend(
      () => _putRequest('/absence-requests/$id', body),
    );
    _absenceEnsureSuccess(response);
    return parseAbsenceRequestPayload(_tryDecode(response.body));
  }

  Future<AbsenceRequest?> cancelAbsenceRequest(int id) async {
    final response = await _absenceSend(
      () => _postRequest('/absence-requests/$id/cancel', {}),
    );
    _absenceEnsureSuccess(response);
    return parseAbsenceRequestPayload(_tryDecode(response.body));
  }

  Future<AbsenceRequest?> approveAbsenceRequest(int id) async {
    final response = await _absenceSend(
      () => _postRequest('/absence-requests/$id/approve', {}),
    );
    _absenceEnsureSuccess(response);
    return parseAbsenceRequestPayload(_tryDecode(response.body));
  }

  Future<AbsenceRequest?> rejectAbsenceRequest(
    int id,
    String reason,
  ) async {
    final response = await _absenceSend(
      () => _postRequest('/absence-requests/$id/reject', {
        'rejection_reason': reason,
      }),
    );
    _absenceEnsureSuccess(response);
    return parseAbsenceRequestPayload(_tryDecode(response.body));
  }

  Future<AbsenceSettings> getAbsenceSettings() async {
    final response = await _absenceSend(
      () => _getRequest('/absence-settings'),
    );
    return parseAbsenceSettings(_absenceDecode(response));
  }

  Future<void> updateAbsenceSettings(Map<String, dynamic> body) async {
    final response = await _absenceSend(
      () => _putRequest('/absence-settings', body),
    );
    _absenceEnsureSuccess(response);
  }

  /// Файл не разбираем как JSON. Имя задаёт экран: «Заявки-на-отсутствие.xlsx».
  Future<List<int>> exportAbsenceRequests(AbsenceFilters filters) async {
    final response = await _absenceSend(
      () => _getRequest(absenceExportPath(filters)),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw absenceErrorFromBody(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('json')) {
      throw absenceErrorFromBody(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    return response.bodyBytes;
  }

  Future<AbsencePage> _getAbsencePage(String path) async {
    final response = await _absenceSend(() => _getRequest(path));
    return parseAbsencePage(_absenceDecode(response));
  }

  Future<http.Response> _absenceSend(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on SocketException {
      throw const AbsenceApiException(
        statusCode: 0,
        message: 'absence_offline',
        network: true,
      );
    } on http.ClientException {
      throw const AbsenceApiException(
        statusCode: 0,
        message: 'absence_offline',
        network: true,
      );
    } on TimeoutException {
      throw const AbsenceApiException(
        statusCode: 0,
        message: 'absence_offline',
        network: true,
      );
    }
  }

  dynamic _absenceDecode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw absenceErrorFromBody(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    final decoded = _tryDecode(response.body);
    if (decoded == null) {
      throw AbsenceApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
    return decoded;
  }

  void _absenceEnsureSuccess(http.Response response, {bool created = false}) {
    final ok = response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204 ||
        (created && response.statusCode == 201);
    if (!ok) {
      throw absenceErrorFromBody(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  dynamic _tryDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
