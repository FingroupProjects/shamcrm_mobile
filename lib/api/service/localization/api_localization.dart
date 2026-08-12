part of '../api_service.dart';

extension ApiLocalizationX on ApiService {
  /// Получить настройки локализации с сервера
  /// GET /api/localization?organization_id=1&sales_funnel_id=1
  Future<LocalizationResponse?> getLocalization() async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      String path = await _appendQueryParams('/localization');

      if (kDebugMode) {
        debugPrint('ApiService: getLocalization - Path: $path');
      }

      final response = await _getRequest(path);

      if (kDebugMode) {
        debugPrint(
            'ApiService: getLocalization - Status: ${response.statusCode}');
        debugPrint('ApiService: getLocalization - Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final localizationResponse = LocalizationResponse.fromJson(data);

        if (kDebugMode) {
          debugPrint('ApiService: Локализация получена успешно');
          debugPrint('  - Language: ${localizationResponse.result?.language}');
          debugPrint(
              '  - Phone code: ${localizationResponse.result?.countryPhoneCodes}');
        }

        return localizationResponse;
      } else {
        if (kDebugMode) {
          debugPrint(
              'ApiService: Ошибка получения локализации: ${response.statusCode}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('ApiService: Исключение при получении локализации: $e');
        debugPrint('ApiService: StackTrace: $stackTrace');
      }
      return null;
    }
  }

  /// Изменить язык на сервере
  /// POST /api/localization/change-language
  Future<bool> changeLanguage(String language) async {
    try {
      final organizationId = await getSelectedOrganization();
      final salesFunnelId = await getSelectedSalesFunnel();

      final Map<String, dynamic> body = {
        'language': language,
        'organization_id':
            organizationId != null ? int.parse(organizationId) : null,
        'sales_funnel_id':
            salesFunnelId != null ? int.parse(salesFunnelId) : null,
      };

      if (kDebugMode) {
        debugPrint('ApiService: changeLanguage - Body: $body');
      }

      final response =
          await _postRequest('/localization/change-language', body);

      if (kDebugMode) {
        debugPrint(
            'ApiService: changeLanguage - Status: ${response.statusCode}');
        debugPrint('ApiService: changeLanguage - Response: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint('ApiService: Язык успешно изменён на сервере: $language');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint(
              'ApiService: Ошибка изменения языка: ${response.statusCode}');
        }
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('ApiService: Исключение при изменении языка: $e');
        debugPrint('ApiService: StackTrace: $stackTrace');
      }
      return false;
    }
  }
}
