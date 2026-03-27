import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crm_task_manager/api/service/api_service.dart';

/// API сервис для работы с реакциями на сообщения
class MessageReactionApiService {
  final ApiService _apiService = ApiService();

  /// Добавить реакцию на сообщение
  /// POST /api/message/{messageId}/reaction
  Future<Map<String, dynamic>> addReaction({
    required int messageId,
    required String emoji,
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

      String path = '$baseUrl/api/message/$messageId/reaction';

      // Добавляем параметры
      path += '?organization_id=${organizationId ?? ""}';
      path += '&sales_funnel_id=${salesFunnelId ?? ""}';

      final body = {
        'emoji': emoji,
      };

      if (kDebugMode) {
        debugPrint('MessageReactionApiService: addReaction - path: $path');
        debugPrint('MessageReactionApiService: addReaction - body: $body');
      }

      // Выполняем POST запрос
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
          debugPrint('MessageReactionApiService: Реакция успешно добавлена');
        }
        return data;
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageReactionApiService: Ошибка ${response.statusCode}: ${response.body}');
        }
        throw Exception('Ошибка добавления реакции: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessageReactionApiService: addReaction - Error: $e');
      }
      rethrow;
    }
  }

  /// Удалить реакцию с сообщения
  /// DELETE /api/message/{messageId}/reaction
  Future<Map<String, dynamic>> removeReaction({
    required int messageId,
    required String emoji,
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

      String path = '$baseUrl/api/message/$messageId/reaction';

      // Добавляем параметры
      path += '?organization_id=${organizationId ?? ""}';
      path += '&sales_funnel_id=${salesFunnelId ?? ""}';
      path += '&emoji=${Uri.encodeComponent(emoji)}';

      if (kDebugMode) {
        debugPrint('MessageReactionApiService: removeReaction - path: $path');
      }

      // Выполняем DELETE запрос
      final response = await http.delete(
        Uri.parse(path),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) {
          debugPrint('MessageReactionApiService: Реакция успешно удалена');
        }
        return {'result': 'Success'};
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageReactionApiService: Ошибка ${response.statusCode}: ${response.body}');
        }
        throw Exception('Ошибка удаления реакции: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessageReactionApiService: removeReaction - Error: $e');
      }
      rethrow;
    }
  }
}
