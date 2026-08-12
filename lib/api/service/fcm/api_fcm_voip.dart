part of '../api_service.dart';

extension ApiFcmVoipX on ApiService {
  Future<void> sendDeviceToken(String deviceToken) async {
    try {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('sendDeviceToken: Начало отправки FCM-токена');
      debugPrint('sendDeviceToken: Token: ${deviceToken.substring(0, 20)}...');

      // 1. Ждём, пока всё инициализировано
      await ensureInitialized();
      if (baseUrl == null || baseUrl!.isEmpty) {
        debugPrint(
            'sendDeviceToken: baseUrl не готов → сохраняем как отложенный');
        await _savePendingToken(deviceToken);
        return;
      }

      final token = await getToken();
      if (token == null || token.isEmpty) {
        debugPrint('sendDeviceToken: Нет авторизационного токена → отложенный');
        await _savePendingToken(deviceToken);
        return;
      }

      final organizationId = await getSelectedOrganization();
      final url =
          '$baseUrl/add-fcm-token${organizationId != null ? '?organization_id=$organizationId' : ''}';

      debugPrint('sendDeviceToken: URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Device': 'mobile',
        },
        body: json.encode({
          'type': 'mobile',
          'token': deviceToken,
        }),
      );

      debugPrint(
          'sendDeviceToken: Ответ: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('sendDeviceToken: УСПЕШНО отправлен');
        await _removePendingToken(); // Удаляем только при успехе
      } else {
        debugPrint(
            'sendDeviceToken: Ошибка ${response.statusCode} → отложенный');
        await _savePendingToken(deviceToken);
      }
    } catch (e, s) {
      debugPrint('sendDeviceToken: Исключение: $e\n$s');
      await _savePendingToken(deviceToken);
    } finally {
      debugPrint('═══════════════════════════════════════════════════════════');
    }
  }

  Future<void> _savePendingToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiService._pendingFcmKey, token);
    debugPrint('sendDeviceToken: Токен сохранён как отложенный');
  }

  Future<void> _removePendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final hadToken = prefs.containsKey(ApiService._pendingFcmKey);
    await prefs.remove(ApiService._pendingFcmKey);
    if (hadToken) debugPrint('sendDeviceToken: Отложенный токен удалён');
  }

  Future<void> sendPendingFCMTokenIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(ApiService._pendingFcmKey);

    if (pending == null || pending.isEmpty) {
      debugPrint('sendPendingFCMTokenIfNeeded: Нет отложенного токена');
      return;
    }

    debugPrint(
        'sendPendingFCMTokenIfNeeded: Найден отложенный токен → отправляем');
    await sendDeviceToken(pending); // ← внутри уже всё обработается
    // НЕ удаляем здесь! Удаление только в sendDeviceToken при успехе
  }

  Future<void> sendVoipToken(String voipToken) async {
    try {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('sendVoipToken: Начало отправки iOS VoIP токена');
      debugPrint(
          'sendVoipToken: Token: ${voipToken.substring(0, voipToken.length > 20 ? 20 : voipToken.length)}...');

      await ensureInitialized();
      if (baseUrl == null || baseUrl!.isEmpty) {
        debugPrint(
            'sendVoipToken: baseUrl не готов → сохраняем как отложенный');
        await _savePendingVoipToken(voipToken);
        await _saveVoipSyncDiagnostics(
          status: 'pending_base_url',
          error: 'Base URL is not initialized',
        );
        return;
      }

      final token = await getToken();
      if (token == null || token.isEmpty) {
        debugPrint('sendVoipToken: Нет авторизационного токена → отложенный');
        await _savePendingVoipToken(voipToken);
        await _saveVoipSyncDiagnostics(
          status: 'pending_auth',
          error: 'Authorization token is missing',
        );
        return;
      }

      final organizationId = await getSelectedOrganization();
      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString('userID') ?? prefs.getString('user_id') ?? '';
      if (userId.trim().isEmpty) {
        debugPrint('sendVoipToken: user_id не найден → отложенный');
        await _savePendingVoipToken(voipToken);
        await _saveVoipSyncDiagnostics(
          status: 'pending_user_id',
          error: 'User ID is missing',
        );
        return;
      }
      final url =
          '$baseUrl/user/add-voip-token/${userId.trim()}${organizationId != null ? '?organization_id=$organizationId' : ''}';

      debugPrint('sendVoipToken: URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Device': 'mobile',
        },
        body: json.encode({
          'type': 'mobile',
          'token': voipToken,
          'platform': 'ios',
          'provider': 'apns_voip',
          if (organizationId != null) 'organization_id': organizationId,
          if (userId.trim().isNotEmpty) 'user_id': userId.trim(),
        }),
      );

      debugPrint(
          'sendVoipToken: Ответ: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('sendVoipToken: УСПЕШНО отправлен');
        await _removePendingVoipToken();
        await _saveVoipSyncDiagnostics(
          status: 'synced',
          httpCode: response.statusCode,
        );
      } else {
        debugPrint('sendVoipToken: Ошибка ${response.statusCode} → отложенный');
        await _savePendingVoipToken(voipToken);
        await _saveVoipSyncDiagnostics(
          status: 'failed',
          httpCode: response.statusCode,
          error: response.body,
        );
      }
    } catch (e, s) {
      debugPrint('sendVoipToken: Исключение: $e\n$s');
      await _savePendingVoipToken(voipToken);
      await _saveVoipSyncDiagnostics(
        status: 'exception',
        error: e.toString(),
      );
    } finally {
      debugPrint('═══════════════════════════════════════════════════════════');
    }
  }

  Future<void> _savePendingVoipToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiService._pendingVoipKey, token);
    debugPrint('sendVoipToken: Токен сохранён как отложенный');
  }

  Future<void> _removePendingVoipToken() async {
    final prefs = await SharedPreferences.getInstance();
    final hadToken = prefs.containsKey(ApiService._pendingVoipKey);
    await prefs.remove(ApiService._pendingVoipKey);
    if (hadToken) debugPrint('sendVoipToken: Отложенный токен удалён');
  }

  Future<void> clearPendingVoipToken() async {
    await _removePendingVoipToken();
  }

  Future<bool> deleteVoipToken({String? voipToken}) async {
    try {
      await ensureInitialized();
      if (baseUrl == null || baseUrl!.isEmpty) {
        debugPrint('deleteVoipToken: baseUrl не готов');
        return false;
      }

      final authToken = await getToken();
      if (authToken == null || authToken.isEmpty) {
        debugPrint('deleteVoipToken: отсутствует токен авторизации');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString('userID') ?? prefs.getString('user_id') ?? '';
      if (userId.trim().isEmpty) {
        debugPrint('deleteVoipToken: user_id не найден');
        return false;
      }

      final organizationId = await getSelectedOrganization();
      final url =
          '$baseUrl/user/delete-voip-token/${userId.trim()}${organizationId != null ? '?organization_id=$organizationId' : ''}';
      final normalizedToken = voipToken?.trim();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
        'Device': 'mobile',
      };
      final body = json.encode({
        'type': 'mobile',
        'platform': 'ios',
        'provider': 'apns_voip',
        if (normalizedToken != null && normalizedToken.isNotEmpty)
          'token': normalizedToken,
        if (organizationId != null) 'organization_id': organizationId,
        'user_id': userId.trim(),
      });
      var response = await http
          .delete(Uri.parse(url), headers: headers, body: body)
          .timeout(ApiService._defaultRequestTimeout);

      // Support both DELETE and legacy POST route definitions during rollout.
      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await http
            .post(Uri.parse(url), headers: headers, body: body)
            .timeout(ApiService._defaultRequestTimeout);
      }

      final succeeded = response.statusCode >= 200 && response.statusCode < 300;
      debugPrint(
        'deleteVoipToken: status=${response.statusCode}, success=$succeeded',
      );
      await _saveVoipSyncDiagnostics(
        status: succeeded ? 'revoked' : 'revoke_failed',
        httpCode: response.statusCode,
        error: succeeded ? null : response.body,
      );
      return succeeded;
    } catch (error, stackTrace) {
      debugPrint('deleteVoipToken: error=$error');
      debugPrint('deleteVoipToken: stackTrace=$stackTrace');
      await _saveVoipSyncDiagnostics(
        status: 'revoke_exception',
        error: error.toString(),
      );
      return false;
    }
  }

  Future<void> _saveVoipSyncDiagnostics({
    required String status,
    int? httpCode,
    String? error,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiService._voipSyncStatusKey, status);
    await prefs.setInt(ApiService._voipSyncAtKey, DateTime.now().millisecondsSinceEpoch);
    if (httpCode != null) {
      await prefs.setInt(ApiService._voipSyncHttpCodeKey, httpCode);
    } else {
      await prefs.remove(ApiService._voipSyncHttpCodeKey);
    }
    if (error != null && error.trim().isNotEmpty) {
      await prefs.setString(ApiService._voipSyncErrorKey, error.trim());
    } else {
      await prefs.remove(ApiService._voipSyncErrorKey);
    }
  }

  Future<Map<String, dynamic>> getVoipSyncDiagnostics() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingToken = prefs.getString(ApiService._pendingVoipKey);
    return <String, dynamic>{
      'status': prefs.getString(ApiService._voipSyncStatusKey) ?? 'unknown',
      'syncedAt': prefs.getInt(ApiService._voipSyncAtKey),
      'httpCode': prefs.getInt(ApiService._voipSyncHttpCodeKey),
      'error': prefs.getString(ApiService._voipSyncErrorKey),
      'hasPendingToken': pendingToken != null && pendingToken.isNotEmpty,
    };
  }

  Future<void> sendPendingVoipTokenIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(ApiService._pendingVoipKey);

    if (pending == null || pending.isEmpty) {
      debugPrint('sendPendingVoipTokenIfNeeded: Нет отложенного токена');
      return;
    }

    debugPrint(
        'sendPendingVoipTokenIfNeeded: Найден отложенный токен → отправляем');
    await sendVoipToken(pending);
  }

  Future<void> setSendIncomingCallPush(bool enabled) async {
    await ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getString('userID') ?? prefs.getString('user_id') ?? '';

    if (userId.trim().isEmpty) {
      throw Exception(
        'ApiService.setSendIncomingCallPush: userID not found in SharedPreferences',
      );
    }

    final response = await _postRequest(
      '/user/send-incoming-call-push/$userId',
      <String, dynamic>{
        'send_incoming_call_push': enabled,
      },
    );

    if (kDebugMode) {
      debugPrint(
        'ApiService.setSendIncomingCallPush: userId=$userId, enabled=$enabled, status=${response.statusCode}',
      );
    }
  }

  Future<int?> sendSipReady({
    required String callId,
    required String callUUID,
    // Test flow: optional SIP Call-ID is separate from Push/Linkedid call_id.
    // Previous behavior for quick rollback: remove this parameter and omit sip_call_id from body.
    String? sipCallId,
    required String extension,
  }) async {
    await ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getString('userID') ?? prefs.getString('user_id') ?? '';

    if (userId.trim().isEmpty) {
      throw Exception(
        'ApiService.sendSipReady: userID not found in SharedPreferences',
      );
    }

    final organizationId = await getSelectedOrganization();
    final body = <String, dynamic>{
      'call_id': callId,
      'call_uuid': callUUID,
      // Test flow: keep call_id from Push; send SIP Call-ID only as nullable extra context.
      if (sipCallId != null && sipCallId.trim().isNotEmpty)
        'sip_call_id': sipCallId.trim(),
      'extension': extension,
      'platform': 'ios',
      'provider': 'apns_voip',
      if (organizationId != null) 'organization_id': organizationId,
      'user_id': userId.trim(),
    };

    final response = await _postRequest(
      '/user/sip-ready/${userId.trim()}',
      body,
    );

    if (kDebugMode) {
      debugPrint(
        'ApiService.sendSipReady: userId=$userId, callId=$callId, callUUID=$callUUID, sipCallId=${sipCallId ?? ''}, extension=$extension, status=${response.statusCode}',
      );
    }
    return response.statusCode;
  }
}
