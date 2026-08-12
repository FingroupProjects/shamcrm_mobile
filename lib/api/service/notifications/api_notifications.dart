part of '../api_service.dart';

extension ApiNotificationsX on ApiService {
  Future<List<Notifications>> getAllNotifications(
      {int page = 1, int perPage = 20}) async {
    String path = await _appendQueryParams(
        '/notification/unread?page=$page&per_page=$perPage');
    if (kDebugMode) {
      //debugPrint('ApiService: getAllNotifications - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data['result']['data'] != null) {
          return (data['result']['data'] as List).map((json) {
            try {
              return Notifications.fromJson(json);
            } catch (e) {
              //debugPrint('Ошибка десериализации уведомления: $e, JSON: $json');
              rethrow;
            }
          }).toList();
        } else {
          throw Exception('Нет данных о уведомлениях в ответе');
        }
      } catch (e) {
        //debugPrint('Ошибка декодирования ответа: $e');
        throw Exception('Ошибка обработки ответа сервера: $e');
      }
    } else {
      throw Exception('Ошибка загрузки уведомлений: ${response.statusCode}');
    }
  }

  Future<int> DeleteAllNotifications() async {
    // Используем эндпоинт /notification/readAll с POST методом
    String path = await _appendQueryParams('/notification/readAll');

    if (kDebugMode) {
      debugPrint('ApiService: DeleteAllNotifications - Generated path: $path');
    }

    debugPrint('Sending POST request to API with path: $path');

    // Используем POST метод как и раньше
    final response = await _postRequest(path, {});

    final successCodes = [200, 201, 204, 429];
    if (successCodes.contains(response.statusCode)) {
      debugPrint(
          '✅ All notifications deleted successfully. Status: ${response.statusCode}');
      return response.statusCode;
    } else {
      throw Exception(
          'Ошибка удаления уведомлений! Status: ${response.statusCode}');
    }
  }

  Future<int> DeleteNotifications({int? notificationId}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path =
        await _appendQueryParams('/notification/read/$notificationId');
    if (kDebugMode) {
      //debugPrint('ApiService: DeleteNotifications - Generated path: $path');
    }

    Map<String, dynamic> body = {
      'notificationId': notificationId,
      'organization_id': await getSelectedOrganization(),
    };

    ////debugPrint('Sending POST request to API with path: $path');

    final response = await _postRequest(path, body);

    // Успешные коды: 200, 201, 204, 429
    final successCodes = [200, 201, 204, 429];
    if (successCodes.contains(response.statusCode)) {
      return response.statusCode;
    } else {
      throw Exception('Ошибка удаления уведомлений!');
    }
  }
}
