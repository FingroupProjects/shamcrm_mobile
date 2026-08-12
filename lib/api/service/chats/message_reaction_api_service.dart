import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crm_task_manager/api/service/api_service.dart';

/// API сервис для работы с реакциями на сообщения
class MessageReactionApiService {
  final ApiService _apiService = ApiService();

  /// Web-compatible endpoint:
  /// POST /api/v2/chat/sendReaction/{chatId}
  /// body: {message_id, reaction, remove}
  Future<Map<String, dynamic>> sendReaction({
    required int chatId,
    required int messageId,
    required String reaction,
    required bool remove,
  }) async {
    try {
      final baseUrl = await _apiService.getDynamicBaseUrl();
      final token = await _apiService.getToken();

      if (baseUrl.isEmpty || token == null || token.isEmpty) {
        throw Exception('Не удалось получить baseUrl или token');
      }

      // Получаем параметры организации и воронки продаж
      final organizationId = await _apiService.getSelectedOrganization();
      final salesFunnelId = await _apiService.getSelectedSalesFunnel();

      final path =
          '$baseUrl/v2/chat/sendReaction/$chatId?organization_id=${organizationId ?? ""}&sales_funnel_id=${salesFunnelId ?? ""}';
      final body = {
        'message_id': messageId,
        'reaction': reaction,
        'remove': remove,
      };

      if (kDebugMode) {
        debugPrint('MessageReactionApiService: sendReaction - path: $path');
        debugPrint('MessageReactionApiService: sendReaction - body: $body');
      }

      final response = await http.post(
        Uri.parse(path),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          debugPrint('MessageReactionApiService: Реакция успешно отправлена');
        }
        return data;
      }

      if (kDebugMode) {
        debugPrint(
            'MessageReactionApiService: Ошибка ${response.statusCode}: ${response.body}');
      }
      throw Exception('Ошибка отправки реакции: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessageReactionApiService: sendReaction - Error: $e');
      }
      rethrow;
    }
  }
}
