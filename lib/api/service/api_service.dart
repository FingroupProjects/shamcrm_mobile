import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'package:crm_task_manager/models/chart_data.dart';
// import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';
// import 'package:crm_task_manager/firebase_options.dart';
import 'package:crm_task_manager/models/LeadStatusForFilter.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
import 'package:crm_task_manager/models/calendar_model.dart';
import 'package:crm_task_manager/models/money/add_cash_desk_model.dart';
import 'package:crm_task_manager/models/money/cash_register_model.dart';
import 'package:crm_task_manager/models/money/expense_model.dart';
import 'package:crm_task_manager/models/money/add_expense_model.dart';
import 'package:crm_task_manager/models/money/income_model.dart';
import 'package:crm_task_manager/models/money/add_income_model.dart';
import 'package:crm_task_manager/models/chatById_model.dart';
import 'package:crm_task_manager/models/chatGetId_model.dart';
import 'package:crm_task_manager/models/chatTaskProfile_model.dart';
import 'package:crm_task_manager/models/contact_person_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/deal_stats_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/process_speed%20_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/user_task%20_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/deal_stats_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/lead_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/lead_conversion_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/process_speed%20_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/task_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/user_task_model.dart';
import 'package:crm_task_manager/models/deal_name_list.dart';
import 'package:crm_task_manager/models/deal_task_model.dart';
import 'package:crm_task_manager/models/department.dart';
import 'package:crm_task_manager/models/directory_link_model.dart';
import 'package:crm_task_manager/models/directory_model.dart';
import 'package:crm_task_manager/models/event_by_Id_model.dart';
import 'package:crm_task_manager/models/event_model.dart';
import 'package:crm_task_manager/models/history_model_my-task.dart';
import 'package:crm_task_manager/models/integration_model.dart';
import 'package:crm_task_manager/models/lead_deal_model.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart' hide LeadData;
import 'package:crm_task_manager/models/lead_navigate_to_chat.dart'
    hide Integration;
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/mini_app_settiings.dart';
import 'package:crm_task_manager/models/my-task_Status_Name_model.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/models/my-taskbyId_model.dart';
import 'package:crm_task_manager/models/notice_history_model.dart';
import 'package:crm_task_manager/models/notice_subject_model.dart';
import 'package:crm_task_manager/models/notifications_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/task_chart_model.dart';
import 'package:crm_task_manager/models/organization_model.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/call_analytics_model.dart';
import 'package:crm_task_manager/models/page_2/call_center_by_id_model.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:crm_task_manager/models/page_2/call_statistics1_model.dart';
import 'package:crm_task_manager/models/page_2/call_summary_stats_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/character_list_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/dashboard_goods_report.dart';
import 'package:crm_task_manager/models/page_2/dashboard/cash_balance_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/dashboard_top.dart';
import 'package:crm_task_manager/models/page_2/dashboard/debtors_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/creditors_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/illiquids_model.dart';
import 'package:crm_task_manager/models/page_2/delivery_address_model.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_history_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/models/page_2/label_list_model.dart';
import 'package:crm_task_manager/models/page_2/lead_order_model.dart';
import 'package:crm_task_manager/models/page_2/measure_unit_model.dart';
import 'package:crm_task_manager/models/page_2/monthly_call_stats.dart';
import 'package:crm_task_manager/models/page_2/operator_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_history_model.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/models/page_2/price_type_model.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryById.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/price_type_model.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:crm_task_manager/models/source_list_model.dart';
import 'package:crm_task_manager/models/source_model.dart';
import 'package:crm_task_manager/models/supplier_list_model.dart';
import 'package:crm_task_manager/models/task_Status_Name_model.dart';
import 'package:crm_task_manager/models/chats_model.dart' hide Integration;
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_history_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/lead_history_model.dart';
import 'package:crm_task_manager/models/history_model_task.dart';
import 'package:crm_task_manager/models/leadById_model.dart' hide Integration;
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:crm_task_manager/models/pagination_dto.dart';
import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/role_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart' hide ChatById;
import 'package:crm_task_manager/models/template_model.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/models/user_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_dropdown_bottom_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/batch_model.dart';
import '../../models/cash_register_list_model.dart';
import '../../models/domain_check.dart';
import '../../models/income_categories_data_response.dart';
import '../../models/login_model.dart';
import '../../models/money/money_income_document_model.dart';
import '../../models/money/money_outcome_document_model.dart';
import '../../models/outcome_categories_data_response.dart';
import '../../models/page_2/dashboard/expense_structure.dart';
import '../../models/page_2/dashboard/net_profit_model.dart';
import '../../models/page_2/dashboard/order_dashboard_model.dart';
import '../../models/page_2/dashboard/profitability_dashboard_model.dart';
import '../../models/page_2/dashboard/sales_model.dart';
import '../../models/page_2/dashboard/top_selling_model.dart';

// final String baseUrl = 'https://fingroup-back.shamcrm.com/api';
// final String baseUrl = 'https://ede8-95-142-94-22.ngrok-free.app';

// final String baseUrlSocket ='https://fingroup-back.shamcrm.com/broadcasting/auth';

class ApiService {
  String? baseUrl;
  String? baseUrlSocket;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  // Добавьте этот список эндпоинтов, которые не требуют проверки сессии
  static const List<String> _noSessionCheckEndpoints = [
    '/login',
    '/get-user-by-email',
    '/checkDomain',
    '/add-fcm-token',
  ];
  ApiService() {
    _initializeIfDomainExists();
  }


// Новый метод для получения message из body ответа
String? _extractErrorMessageFromResponse(http.Response response) {
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final rawMessage = body['message'] ?? body['error'] ?? body['errors'];
  final message = jsonDecode(jsonEncode(rawMessage));

  return message;
}

  // Также нужно обновить метод _initializeIfDomainExists
  // Обновленный метод инициализации с проверкой сессии
  Future<void> _initializeIfDomainExists() async {
    // Сначала проверяем валидность сессии
    if (!await _isSessionValid()) {
      print('ApiService: Session is invalid, redirecting to auth');
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
  try {
    debugPrint('ApiService: Starting initialization');

    // Получаем базовый URL
    String dynamicBaseUrl = await getDynamicBaseUrl();

    // Проверяем что URL валидный
    if (dynamicBaseUrl.isEmpty || dynamicBaseUrl.contains('null')) {
      throw Exception('Получен недействительный базовый URL: $dynamicBaseUrl');
    }

    baseUrl = dynamicBaseUrl;
    debugPrint('ApiService: Initialized with baseUrl: $baseUrl');

  } catch (e) {
    debugPrint('ApiService: initialize error: $e');

    // Пытаемся установить fallback значения
    try {
      await _setFallbackDomain();
      baseUrl = await getDynamicBaseUrl();
      debugPrint('ApiService: Fallback initialization successful: $baseUrl');
    } catch (fallbackError) {
      debugPrint('ApiService: Fallback initialization failed: $fallbackError');
      throw Exception('Не удалось инициализировать ApiService: $e');
    }
  }
}
// Вспомогательный метод для установки резервного домена
Future<void> _setFallbackDomain() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Проверяем, есть ли сохраненные данные пользователя
  String? userId = prefs.getString('userID');
  String? token = prefs.getString('token');

  if (userId != null && token != null) {
    // Используем базовые значения для восстановления подключения
    String fallbackMainDomain = 'shamcrm.com';
    String fallbackDomain = 'default'; // Замените на реальный домен организации

    await prefs.setString('enteredMainDomain', fallbackMainDomain);
    await prefs.setString('enteredDomain', fallbackDomain);

    debugPrint('ApiService: Set fallback domain: $fallbackDomain-back.$fallbackMainDomain');
  } else {
    throw Exception('Нет данных для восстановления подключения');
  }
}

  // Инициализация API с доменом из QR-кода
  Future<void> initializeWithDomain(String domain, String mainDomain) async {
    baseUrl = 'https://$domain-back.$mainDomain/api';
    baseUrlSocket = 'https://$domain-back.$mainDomain/broadcasting/auth';
    print('Initialized baseUrl: $baseUrl, baseUrlSocket: $baseUrlSocket');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('domain', domain);
    await prefs.setString('mainDomain', mainDomain);
  }

Future<String> getDynamicBaseUrl() async {
  try {
    // Сначала пробуем новую логику с email
    String? verifiedDomain = await getVerifiedDomain();
    if (verifiedDomain != null && verifiedDomain.isNotEmpty && verifiedDomain != 'null') {
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

    if (domain != null && domain.isNotEmpty && domain != 'null' &&
        mainDomain != null && mainDomain.isNotEmpty && mainDomain != 'null') {
      return 'https://$domain-back.$mainDomain/api';
    } else {
      throw Exception('Домен не установлен или содержит недействительные значения');
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

  // Общая обработка ответа от сервера 401
    Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      print('ApiService: Received 401, forcing logout and redirect');
      await _forceLogoutAndRedirect();
      throw Exception('Неавторизованный доступ!');
    }

    // Дополнительная проверка на другие критические ошибки
    if (response.statusCode >= 500) {
      print('ApiService: Server error ${response.statusCode}');
      // Можно добавить дополнительную логику для серверных ошибок
    }

    return response;
  }

  // Метод для перенаправления на окно входа
  void _redirectToLogin() {
    final navigatorKey = GlobalKey<NavigatorState>();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/local_auth',
      (route) => false,
    );
  }

  Future<void> reset() async {
    // Сброс значений при выходе
    baseUrl = null;
    baseUrlSocket = null;
    ////print('API сброшено');
  }

  // Метод для получения токена из SharedPreferences
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Получаем токен из SharedPreferences
  }

  // Метод для сохранения токена в SharedPreferences
  Future<void> _saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token); // Сохраняем токен
  }

  // Метод для удаления токена (используется при логауте)
  Future<void> _removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Удаляем токен
  }

  // Метод для логаута — очистка токена
  // Обновленный метод логаута
  Future<void> logout() async {
    // Удаляем токен, права доступа и организацию
    await _removeToken();
    await _removePermissions();
    await _removeOrganizationId();

    // Очищаем новые данные email-flow
    await clearEmailVerificationData();
  }

// Метод для получения информации о пользователе по email
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
        print('ApiService: getUserByEmail - Response: $data');
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
        print(
            'ApiService: getUserByEmail - Error: Status ${response.statusCode}, Body: ${response.body}');
      }
      throw Exception('Пользователь с таким email не найден');
    }
  }

// Метод для сохранения данных после верификации email
  Future<void> saveEmailVerificationData(String domain, String login,
      {String? organizationId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('verifiedDomain', domain);
    await prefs.setString('verifiedLogin', login);

    if (organizationId != null && organizationId.isNotEmpty) {
      await prefs.setString('selectedOrganization', organizationId);
      if (kDebugMode) {
        print(
            'ApiService: saveEmailVerificationData - Saved organization_id: $organizationId');
      }
    } else {
      if (kDebugMode) {
        print(
            'ApiService: saveEmailVerificationData - Warning: organization_id is null or empty');
      }
    }

    baseUrl = 'https://$domain/api';
    if (kDebugMode) {
      print(
          'ApiService: saveEmailVerificationData - Saved domain: $domain, login: $login');
    }
  }

// Метод для получения сохраненного логина
  Future<String?> getVerifiedLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('verifiedLogin');
  }

// Метод для получения сохраненного домена
  Future<String?> getVerifiedDomain() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final verifiedDomain = prefs.getString('verifiedDomain');
    if (kDebugMode) {
      print('ApiService: getVerifiedDomain - verifiedDomain: $verifiedDomain');
    }
    return verifiedDomain;
  }

// Обновленный метод initialize для работы с новой логикой
  Future<void> initializeWithEmailFlow() async {
    final domain = await getVerifiedDomain();
    final organizationId = await getSelectedOrganization();
    if (domain != null && domain.isNotEmpty) {
      baseUrl = 'https://$domain/api';
      baseUrlSocket = 'https://$domain/broadcasting/auth';
      if (kDebugMode) {
        print(
            'ApiService: initializeWithEmailFlow - Initialized with domain: $domain, organization_id: $organizationId');
      }
    } else {
      print(
          'ApiService: initializeWithEmailFlow - Error: verifiedDomain is null');
      throw Exception('Домен не установлен');
    }
  }

// Обновленный метод для сброса данных при логауте
  Future<void> clearEmailVerificationData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('verifiedDomain');
    await prefs.remove('verifiedLogin');
  }

  Future<void> _removePermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Выводим в консоль текущие права доступа до удаления
    ////print('Перед удалением: ${prefs.getStringList('permissions')}');

    // Удаляем права доступа
    await prefs.remove('permissions');

    // Проверяем, что ключ действительно удалён
    ////print('После удаления: ${prefs.getStringList('permissions')}');
  }

  //_________________________________ START___API__METHOD__GET__POST__PATCH__DELETE____________________________________________//

   Future<http.Response> _getRequest(String path) async {
    // Проверяем сессию перед каждым запросом
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

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final response = await http.get(
      Uri.parse('$baseUrl$updatedPath'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Device': 'mobile'
      },
    );
    return _handleResponse(response);
  }

  Future<http.Response> _postRequest(
    String path, Map<String, dynamic> body) async {
  // Проверяем сессию только если эндпоинт требует этого
  if (!_noSessionCheckEndpoints.any((endpoint) => path.contains(endpoint))) {
    if (!await _isSessionValid()) {
      await _forceLogoutAndRedirect();
      throw Exception('Session is invalid');
    }
  }

  if (baseUrl == null) {
    await _initializeIfDomainExists();
    if (baseUrl == null) {
      print('Error: baseUrl is null');
      throw Exception('Base URL is not initialized');
    }
  }

  final token = await getToken();
  final updatedPath = await _appendQueryParams(path);
  print('ApiService: _postRequest with updatedPath: $baseUrl$updatedPath');
  print('ApiService: Request body: ${json.encode(body)}');

  final response = await http.post(
    Uri.parse('$baseUrl$updatedPath'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'Device': 'mobile'
    },
    body: json.encode(body),
  );

  print('ApiService: _postRequest response status: ${response.statusCode}');
  print('ApiService: _postRequest response body: ${response.body}');
  return _handleResponse(response);
}

  /// Новый метод для обработки MultipartRequest
  Future<http.Response> _multipartPostRequest(
      String path, http.MultipartRequest request) async {
    final token = await getToken();
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Device': 'mobile',
    });

    //print('ApiService: _multipartPostRequest with path: ${request.url}');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    //print(
    // 'ApiService: _multipartPostRequest response status: ${response.statusCode}');
    //print('ApiService: _multipartPostRequest response body: ${response.body}');
    return _handleResponse(response);
  }

Future<http.Response> _patchRequest(
      String path, Map<String, dynamic> body) async {
    if (!await _isSessionValid()) {
      await _forceLogoutAndRedirect();
      throw Exception('Session is invalid');
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final response = await http.patch(
      Uri.parse('$baseUrl$updatedPath'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'Device': 'mobile'
      },
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> _putRequest(
      String path, Map<String, dynamic> body) async {
    if (!await _isSessionValid()) {
      await _forceLogoutAndRedirect();
      throw Exception('Session is invalid');
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final response = await http.put(
      Uri.parse('$baseUrl$updatedPath'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'Device': 'mobile'
      },
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> _deleteRequest(String path) async {
    if (!await _isSessionValid()) {
      await _forceLogoutAndRedirect();
      throw Exception('Session is invalid');
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final response = await http.delete(
      Uri.parse('$baseUrl$updatedPath'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Device': 'mobile'
      },
    );
    return _handleResponse(response);
  }

  //delete with body
  Future<http.Response> _deleteRequestWithBody(
      String path, Map<String, dynamic> body) async {
    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final request = http.Request('DELETE', Uri.parse('$baseUrl$updatedPath'));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Device': 'mobile'
    });
    request.body = json.encode(body);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
// Новый метод для проверки валидности сессии
  Future<bool> _isSessionValid() async {
  try {
    // Проверяем токен
    final token = await getToken();
    if (token == null || token.isEmpty) {
      print('ApiService: Token is null or empty');
      return false;
    }

    // Проверяем домен
    String? domain = await getVerifiedDomain();
    if (domain == null || domain.isEmpty) {
      // Пробуем QR данные
      Map<String, String?> qrData = await getQrData();
      String? qrDomain = qrData['domain'];
      String? qrMainDomain = qrData['mainDomain'];

      if (qrDomain == null || qrDomain.isEmpty ||
          qrMainDomain == null || qrMainDomain.isEmpty) {
        // Пробуем старую логику
        Map<String, String?> domains = await getEnteredDomain();
        String? enteredDomain = domains['enteredDomain'];
        String? enteredMainDomain = domains['enteredMainDomain'];

        if (enteredDomain == null || enteredDomain.isEmpty ||
            enteredMainDomain == null || enteredMainDomain.isEmpty) {
          print('ApiService: No valid domain found');
          return false;
        }
      }
    }

    // Проверяем организацию
    final organizationId = await getSelectedOrganization();
    if (organizationId == null || organizationId.isEmpty) {
      print('ApiService: Organization ID is null or empty');
      return false;
    }

    return true;
  } catch (e) {
    print('ApiService: Error checking session validity: $e');
    return false;
  }
}

  // Новый метод для принудительного сброса к начальному экрану
  Future<void> _forceLogoutAndRedirect() async {
    try {
      print('ApiService: Force logout and redirect to auth');

      // Полная очистка данных
      await logout();
      await reset();

      // Очищаем дополнительные данные
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Перенаправляем на экран авторизации
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/local_auth',
          (route) => false,
        );
      }
    } catch (e) {
      print('ApiService: Error in force logout: $e');
    }
  }

  //_________________________________ END___API__METHOD__GET__POST__PATCH__DELETE____________________________________________//

  //        if (!await hasPermission('deal.read')) {
  //   throw Exception('У вас нет прав для просмотра сделки'); // Сообщение об отсутствии прав доступа
  // }

  //_________________________________ START___API__METHOD__POST__DEVICE__TOKEN_________________________________________________//

  // Добавление метода для отправки токена устройства
  Future<void> sendDeviceToken(String deviceToken) async {
    final token =
        await getToken(); // Получаем токен пользователя (если он есть)
    // Эндпоинт /add-fcm-token входит в _excludedEndpoints, поэтому не используем _appendQueryParams
    final organizationId = await getSelectedOrganization();

    final response = await http.post(
      Uri.parse(
          '$baseUrl/add-fcm-token${organizationId != null ? '?organization_id=$organizationId' : ''}'), // Используем оригинальный путь, так как исключён
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'Device': 'mobile'
      },
      body: json.encode({
        'type': 'mobile', // Указываем тип устройства
        'token': deviceToken, // Передаем FCM-токен устройства
      }),
    );

    if (response.statusCode == 200) {
      ////print('FCM-токен успешно отправлен!');
    } else {
      ////print('Ошибка при отправке FCM-токена!');
      throw Exception('Ошибка!');
    }
  }

//_________________________________ END___API__METHOD__POST__DEVICE__TOKEN_________________________________________________//
  // Новый метод для получения домена из QR данных
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

  // Новый метод для инициализации из QR данных
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
      print('Initialized baseUrl: $baseUrl, baseUrlSocket: $baseUrlSocket');
      print('Saved domain: $domain, mainDomain: $mainDomain');
    } else {
      throw Exception('QR данные не найдены в SharedPreferences');
    }
  }

// Метод для сохранения данных из QR-кода
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
      print(
          'ApiService: saveQrData - domain: $domain, mainDomain: $mainDomain, organizationId: $organizationId');
      print('ApiService: saveQrData - baseUrl after init: $baseUrl');
    }
  }

// Метод для получения данных из QR-кода
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

//_________________________________ START___API__DOMAIN_CHECK____________________________________________//

  Future<http.Response> _postRequestDomain(
      String path, Map<String, dynamic> body) async {
    final enteredDomainMap = await getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    final String domainUrl = 'https://$enteredMainDomain/api';
    final token = await getToken();
    final updatedPath =
        await _appendQueryParams(path); // Уже использует _appendQueryParams
    final response = await http.post(
      Uri.parse('$domainUrl$updatedPath'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'Device': 'mobile'
      },
      body: json.encode(body),
    );
    return response;
  }

// Метод для проверки домена
  Future<DomainCheck> checkDomain(String domain) async {
    ////print(
    // '-=--=-=-=-=-=-=-==-=-=-=CHECK-DOMAIN-=--==-=-=--=-==--==-=-=-=-=-=-=-');
    ////print(domain);
    // Эндпоинт /checkDomain входит в _excludedEndpoints, поэтому не используем _appendQueryParams
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

// Метод для сохранения домена
  Future<void> saveDomainChecked(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'domainChecked', value); // Сохраняем статус проверки домена
  }

// Метод для проверки домена из SharedPreferences
  Future<bool> isDomainChecked() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('domainChecked') ??
        false; // Проверяем статус или возвращаем false
  }

// Метод для сохранения введенного домена
  Future<void> saveDomain(String domain, String mainDomain) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('enteredMainDomain', mainDomain);
    await prefs.setString('enteredDomain', domain);
    ////print('Ввведеный Doмен:----------------------');
    ////print('ДОМЕН: ${prefs.getString('enteredMainDomain')}');
    ////print('Ввведеный Poddomen---=----:----------------------');
    ////print('ПОДДОМЕН: ${prefs.getString('enteredDomain')}');
  }

// Метод для получения введенного домена
  Future<Map<String, String?>> getEnteredDomain() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mainDomain = prefs.getString('enteredMainDomain');
    String? domain = prefs.getString('enteredDomain');
    if (kDebugMode) {
      print(
          'ApiService: getEnteredDomain - mainDomain: $mainDomain, domain: $domain');
    }
    return {
      'enteredMainDomain': mainDomain,
      'enteredDomain': domain,
    };
  }

  Future<String> getStaticBaseUrl() async {
    // Сначала пробуем новую логику с email
    String? verifiedDomain = await getVerifiedDomain();
    if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
      return 'https://$verifiedDomain/storage';
    }

    // Проверяем QR данные
    Map<String, String?> qrData = await getQrData();
    String? qrDomain = qrData['domain'];
    String? qrMainDomain = qrData['mainDomain'];

    if (qrDomain != null &&
        qrDomain.isNotEmpty &&
        qrMainDomain != null &&
        qrMainDomain.isNotEmpty) {
      return 'https://$qrDomain-back.$qrMainDomain/storage';
    }

    // Если нет, используем старую логику для обратной совместимости
    Map<String, String?> domains = await getEnteredDomain();
    String? mainDomain = domains['enteredMainDomain'];
    String? domain = domains['enteredDomain'];

    if (domain != null &&
        domain.isNotEmpty &&
        mainDomain != null &&
        mainDomain.isNotEmpty) {
      return 'https://$domain-back.$mainDomain/storage';
    } else {
      // Fallback на дефолтный домен, если ничего не найдено
      return 'https://shamcrm.com/storage';
    }
  }

// Метод для получения полного URL файла
  Future<String> getFileUrl(String filePath) async {
    final baseUrl = await getStaticBaseUrl();
    // Убираем лишние слеши, если они есть в начале filePath
    final cleanPath =
        filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$baseUrl/$cleanPath';
  }
//_________________________________ END___API__DOMAIN_CHECK____________________________________________//

//_________________________________ START___API__LOGIN____________________________________________//

// Метод для проверки логина и пароля
 Future<LoginResponse> login(LoginModel loginModel) async {
  print('ApiService: Starting login process');
  print('ApiService: Login model: ${json.encode(loginModel.toJson())}');

  final organizationId = await getSelectedOrganization();
  print('ApiService: Using organization_id: $organizationId');

  // Проверяем baseUrl перед запросом
  if (baseUrl == null) {
    print('ApiService: baseUrl is null, trying to initialize');
    await _initializeIfDomainExists();
    if (baseUrl == null) {
      throw Exception('Failed to initialize baseUrl for login');
    }
  }
  print('ApiService: Current baseUrl: $baseUrl');

  final response = await _postRequest(
    '/login${organizationId != null ? '?organization_id=$organizationId' : ''}',
    loginModel.toJson(),
  );

  if (kDebugMode) {
    print('ApiService: login - Response: ${response.body}');
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
        print('ApiService: login - Saved organization_id from response: $effectiveOrgId');
      }
    } else {
      if (kDebugMode) {
        print('ApiService: login - Warning: organization_id is null, trying /organization');
      }
      // Пробуем получить organization_id из /organization
      try {
        final organizationsResponse = await _getRequest('/organization');
        if (organizationsResponse.statusCode == 200) {
          final organizations = json.decode(organizationsResponse.body);
          if (kDebugMode) {
            print('ApiService: login - /organization response: $organizations');
          }
          if (organizations is List && organizations.isNotEmpty) {
            effectiveOrgId = organizations[0]['id']?.toString();
            if (effectiveOrgId != null && effectiveOrgId.isNotEmpty) {
              await saveSelectedOrganization(effectiveOrgId);
              if (kDebugMode) {
                print('ApiService: login - Saved organization_id from /organization: $effectiveOrgId');
              }
            } else {
              effectiveOrgId = '1'; // Дефолт id = 1
              await saveSelectedOrganization(effectiveOrgId);
              if (kDebugMode) {
                print('ApiService: login - No valid organization_id, using default: $effectiveOrgId');
              }
            }
          } else {
            effectiveOrgId = '1'; // Дефолт id = 1
            await saveSelectedOrganization(effectiveOrgId);
            if (kDebugMode) {
              print('ApiService: login - Empty organizations list, using default: $effectiveOrgId');
            }
          }
        } else {
          effectiveOrgId = '1'; // Дефолт id = 1
          await saveSelectedOrganization(effectiveOrgId);
          if (kDebugMode) {
            print('ApiService: login - Failed to fetch /organization, using default: $effectiveOrgId');
          }
        }
      } catch (e) {
        effectiveOrgId = '1'; // Дефолт id = 1
        await saveSelectedOrganization(effectiveOrgId);
        if (kDebugMode) {
          print('ApiService: login - Exception fetching /organization: $e, using default: $effectiveOrgId');
        }
      }
    }

    print('ApiService: Login successful, token saved');
    return loginResponse;
  } else {
    if (kDebugMode) {
      print('ApiService: login - Error: Status ${response.statusCode}, Body: ${response.body}');
    }

    // Извлекаем сообщение об ошибке из ответа сервера
    String errorMessage = 'Неправильный Логин или Пароль!';
    try {
      final errorData = json.decode(response.body);
      if (errorData['message'] != null) {
        errorMessage = errorData['message'].toString();
      }
    } catch (e) {
      print('ApiService: login - Error parsing error response: $e');
    }

    throw Exception('$errorMessage Status: ${response.statusCode}');
  }
}

// Сохранение прав доступа в SharedPreferences
  Future<void> savePermissions(List<String> permissions) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('permissions', permissions);
    // ////print('Сохранённые права доступа: ${prefs.getStringList('permissions')}');
  }

// Получение списка прав доступа из SharedPreferences
  Future<List<String>> getPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final permissions = prefs.getStringList('permissions') ?? [];
    // ////print('Извлечённые права доступа: $permissions');
    return permissions;
  }

// Проверка наличия определенного права
  Future<bool> hasPermission(String permission) async {
    final permissions = await getPermissions();
    return permissions.contains(permission);
  }

// Метод для получения прав доступа по ID роли
  Future<List<String>> fetchPermissionsByRoleId() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/get-all-permissions');
    if (kDebugMode) {
      //print('ApiService: fetchPermissionsByRoleId - Generated path: $path');
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
      ////print('Ошибка при выполнении запроса fetchPermissionsByRoleId: $e');
      rethrow;
    }
  }

//_________________________________ END___API__LOGIN____________________________________________//

  Future<String> forgotPin(LoginModel loginModel) async {
    try {
      // Эндпоинт /forgotPin входит в _excludedEndpoints, поэтому не используем _appendQueryParams
      final organizationId = await getSelectedOrganization();

      // Формирование URL с учетом ID организации
      final url =
          '/forgotPin${organizationId != null ? '?organization_id=$organizationId' : ''}';

      // Запрос к API
      final response = await _postRequest(
        url,
        {
          'login': loginModel.login,
          'password': loginModel.password,
        },
      );

      // Обработка успешного ответа
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);

        if (decodedJson['result'] != null) {
          return decodedJson['result'].toString();
        } else {
          throw Exception('Не удалось получить временный PIN.');
        }
      }
      // Обработка ошибок сервера
      else if (response.statusCode == 400) {
        throw Exception('Некорректные данные запроса.');
      } else {
        ////print('Ошибка API forgotPin!');
        throw Exception('Ошибка сервера!');
      }
    } catch (e) {
      ////print('Ошибка в forgotPin!');
      throw Exception('Ошибка в запросе!');
    }
  }

//_________________________________ START_____API__SCREEN__LEAD____________________________________________//

//Метод для получения Лида через его ID
  Future<LeadById> getLeadById(int leadId) async {
    try {
      final path = await _appendQueryParams('/lead/$leadId');
      //print('ApiService: getLeadById - Generated path: $path');

      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic> jsonLead = decodedJson['result'];
        return LeadById.fromJson(jsonLead, jsonLead['leadStatus']['id']);
      } else {
        throw Exception('Ошибка загрузки лида ID!');
      }
    } catch (e) {
      //print('ApiService: getLeadById - Error:');
      throw Exception('Ошибка загрузки лида ID!');
    }
  }

// Метод для получения списка Лидов с пагинацией
  Future<List<Lead>> getLeads(
    int? leadStatusId, {
    int page = 1,
    int perPage = 20,
    String? search,
    List<int>? managers,
    List<int>? regions,
    List<int>? sources,
    int? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    bool? hasSuccessDeals,
    bool? hasInProgressDeals,
    bool? hasFailureDeals,
    bool? hasNotices,
    bool? hasContact,
    bool? hasChat,
    bool? hasDeal,
    int? daysWithoutActivity,
    bool? hasNoReplies,
    bool? hasUnreadMessages,
    List<Map<String, dynamic>>? directoryValues,
    int? salesFunnelId, // Новый параметр
  }) async {
    // Формируем базовый путь
    String path = '/lead?page=$page&per_page=$perPage';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //print('ApiService: getLeads - After _appendQueryParams: $path');
    }

    // Добавляем sales_funnel_id из аргумента, если он передан
    if (salesFunnelId != null) {
      path += '&sales_funnel_id=$salesFunnelId';
    }

    bool hasFilters = (search != null && search.isNotEmpty) ||
        (managers != null && managers.isNotEmpty) ||
        (regions != null && regions.isNotEmpty) ||
        (sources != null && sources.isNotEmpty) ||
        (fromDate != null) ||
        (toDate != null) ||
        (hasSuccessDeals == true) ||
        (hasInProgressDeals == true) ||
        (hasFailureDeals == true) ||
        (hasNotices == true) ||
        (hasContact == true) ||
        (hasChat == true) ||
        (hasDeal == true) ||
        (hasNoReplies == true) ||
        (hasUnreadMessages == true) ||
        (daysWithoutActivity != null) ||
        (statuses != null) ||
        (directoryValues != null && directoryValues.isNotEmpty);

    if (leadStatusId != null && !hasFilters) {
      path += '&lead_status_id=$leadStatusId';
    }

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    if (managers != null && managers.isNotEmpty) {
      for (int i = 0; i < managers.length; i++) {
        path += '&managers[$i]=${managers[i]}';
      }
    }
    if (regions != null && regions.isNotEmpty) {
      for (int i = 0; i < regions.length; i++) {
        path += '&regions[$i]=${regions[i]}';
      }
    }
    if (sources != null && sources.isNotEmpty) {
      for (int i = 0; i < sources.length; i++) {
        path += '&sources[$i]=${sources[i]}';
      }
    }
    if (hasNoReplies == true) {
      path += '&hasNoReplies=1';
    }
    if (hasUnreadMessages == true) {
      path += '&hasUnreadMessages=1';
    }
    if (statuses != null) {
      path += '&lead_status_id=$statuses';
    }
    if (fromDate != null && toDate != null) {
      final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
      path += '&from=$formattedFromDate&to=$formattedToDate';
    }
    if (hasSuccessDeals == true) {
      path += '&hasSuccessDeals=1';
    }
    if (hasInProgressDeals == true) {
      path += '&hasInProgressDeals=1';
    }
    if (hasFailureDeals == true) {
      path += '&hasFailureDeals=1';
    }
    if (hasNotices == true) {
      path += '&hasNotices=1';
    }
    if (hasContact == true) {
      path += '&hasContact=1';
    }
    if (hasChat == true) {
      path += '&hasChat=1';
    }
    if (hasDeal == true) {
      path += '&withoutDeal=1';
    }
    if (daysWithoutActivity != null) {
      path += '&lastUpdate=$daysWithoutActivity';
    }
    if (directoryValues != null && directoryValues.isNotEmpty) {
      for (int i = 0; i < directoryValues.length; i++) {
        final directoryId = directoryValues[i]['directory_id'];
        final entryId = directoryValues[i]['entry_id'];
        path += '&directory_values[$i][directory_id]=$directoryId';
        path += '&directory_values[$i][entry_id]=$entryId';
      }
    }

    if (kDebugMode) {
      //print('ApiService: getLeads - Final path: $path');
    }
    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => Lead.fromJson(json, leadStatusId ?? -1))
            .toList();
      } else {
        throw Exception('Данные лидов отсутствуют в ответе');
      }
    } else {
      throw Exception('Ошибка загрузки лидов!');
    }
  }

  Future<List<LeadStatus>> getLeadStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();
    //print('ApiService: getLeadStatuses - organizationId: $organizationId');

    try {
      // Используем _appendQueryParams для формирования пути
      final path = await _appendQueryParams('/lead/statuses');
      //print('ApiService: getLeadStatuses - Generated path: $path');

      final response = await _getRequest(path);
      //print('ApiService: getLeadStatuses - Response status: ${response.statusCode}');
      //print('ApiService: getLeadStatuses - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        //print('ApiService: getLeadStatuses - Parsed data: $data');
        if (data['result'] != null) {
          final statuses = (data['result'] as List)
              .map((status) => LeadStatus.fromJson(status))
              .toList();
          //print('ApiService: getLeadStatuses - Retrieved statuses: ${statuses.map((s) => {'id': s.id, 'title': s.title})}');

          // Кэширование
          await prefs.setString('cachedLeadStatuses_$organizationId',
              json.encode(data['result']));
          //print('ApiService: getLeadStatuses - Cached new statuses: ${data['result']}');

          return statuses;
        } else {
          //print('ApiService: getLeadStatuses - Result is null in response');
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        //print('ApiService: getLeadStatuses - Error status: ${response.statusCode}');
        throw Exception('Ошибка при получении данных: ${response.statusCode}');
      }
    } catch (e) {
      //print('ApiService: getLeadStatuses - Error');
      // Загрузка из кэша
      final cachedStatuses =
          prefs.getString('cachedLeadStatuses_$organizationId');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => LeadStatus.fromJson(status))
            .toList();
        //print('ApiService: getLeadStatuses - Returning cached statuses: ${cachedList.map((s) => {'id': s.id, 'title': s.title})}');
        return cachedList;
      } else {
        //print('ApiService: getLeadStatuses - No cached statuses available');
        throw Exception(
            'Ошибка загрузки статусов лидов и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasLeads(int leadStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<Lead> leads =
          await getLeads(leadStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return leads.isNotEmpty;
    } catch (e) {
      ////print('Error while checking if status has leads!');
      return false;
    }
  }

// Метод для создания Cтатуса Лида
  Future<Map<String, dynamic>> createLeadStatus(
      String title, String color, bool? isFailure, bool? isSuccess) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead-status');
    if (kDebugMode) {
      //print('ApiService: createLeadStatus - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'title': title,
      'color': color,
      "is_success": isSuccess == true ? 1 : 0,
      "is_failure": isFailure == true ? 1 : 0,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Статус лида создан успешно'};
    } else {
      return {'success': false, 'message': 'Ошибка создания статуса лида!'};
    }
  }

//Обновление статуса карточки Лида в колонке
  Future<void> updateLeadStatus(int leadId, int position, int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/changeStatus/$leadId');
    if (kDebugMode) {
      //print('ApiService: updateLeadStatus - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        'position': position,
        'status_id': statusId,
      },
    );

    if (response.statusCode == 200) {
      ////print('Статус задачи успешно обновлен');
    } else if (response.statusCode == 422) {
      final responseData = jsonDecode(response.body);
      final errorMessage = responseData['message'];

      throw LeadStatusUpdateException(422, errorMessage);
    } else {
      throw Exception('Ошибка обновления задач лида!');
    }
  }

// Метод для получения Истории Лида
  Future<List<LeadHistory>> getLeadHistory(int leadId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/lead/history/$leadId');
      if (kDebugMode) {
        //print('ApiService: getLeadHistory - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => LeadHistory.fromJson(json)).toList();
      } else {
        ////print('Failed to load lead history!');
        throw Exception('Ошибка загрузки истории лида!');
      }
    } catch (e) {
      ////print('Error occurred!');
      throw Exception('Ошибка загрузки истории лида!');
    }
  }

  Future<List<NoticeHistory>> getNoticeHistory(int leadId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path =
          await _appendQueryParams('/notices/history-by-lead-id/$leadId');
      if (kDebugMode) {
        //print('ApiService: getNoticeHistory - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result'];
        return jsonList.map((json) => NoticeHistory.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки истории заметок!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки истории заметок!');
    }
  }

  Future<List<DealHistoryLead>> getDealHistoryLead(int leadId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/deal/history-by-lead-id/$leadId');
      if (kDebugMode) {
        //print('ApiService: getDealHistoryLead - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result'];
        return jsonList.map((json) => DealHistoryLead.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки истории сделок!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки истории сделок!');
    }
  }

  Future<List<Notes>> getLeadNotes(int leadId,
      {int page = 1, int perPage = 20}) async {
    // Формируем базовый путь
    final basePath = '/notices/$leadId?page=$page&per_page=$perPage';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(basePath);
    if (kDebugMode) {
      //print('ApiService: getLeadNotes - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result']['data'] as List)
          .map((note) => Notes.fromJson(note))
          .toList();
    } else {
      throw Exception('Ошибка загрузки заметок');
    }
  }

  Future<Map<String, dynamic>> createNotes({
    required String title,
    required String body,
    required int leadId,
    DateTime? date,
    required List<int> users,
    List<String>? filePaths, // Новое поле для файлов
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/notices');
      if (kDebugMode) {
        //print('ApiService: createNotes - Generated path: $path');
      }
      var uri = Uri.parse('$baseUrl$path');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем поля в запрос
      request.fields['title'] = title;
      request.fields['body'] = body;
      request.fields['lead_id'] = leadId.toString();
      if (date != null) {
        request.fields['date'] = DateFormat('yyyy-MM-dd HH:mm').format(date);
      }
      final organizationId = await getSelectedOrganization();
      request.fields['organization_id'] = organizationId?.toString() ?? '2';
      for (int i = 0; i < users.length; i++) {
        request.fields['users[$i]'] = users[i].toString();
      }

      // Добавляем файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'note_created_successfully'};
      } else if (response.statusCode == 422) {
        if (response.body.contains('title')) {
          return {'success': false, 'message': 'invalid_title_length'};
        } else if (response.body.contains('body')) {
          return {'success': false, 'message': 'error_field_is_not_empty'};
        } else if (response.body.contains('date')) {
          return {'success': false, 'message': 'error_valid_date'};
        } else if (response.body.contains('users')) {
          return {'success': false, 'message': 'error_users'};
        } else {
          return {'success': false, 'message': 'validation_error'};
        }
      } else if (response.statusCode == 500) {
        return {'success': false, 'message': 'error_server_text'};
      } else {
        return {'success': false, 'message': 'error_create_note'};
      }
    } catch (e) {
      return {'success': false, 'message': 'error_create_note'};
    }
  }

// Метод для Редактирование Заметки Лида
  Future<Map<String, dynamic>> updateNotes({
    required int noteId,
    required int leadId,
    required String title,
    required String body,
    DateTime? date,
  }) async {
    date ??= DateTime.now();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/notices/$noteId');
    if (kDebugMode) {
      //print('ApiService: updateNotes - Generated path: $path');
    }

    final response = await _patchRequest(path, {
      'title': title,
      'body': body,
      'lead_id': leadId,
      'date': date.toIso8601String(),
    });

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Заметка успешно обновлена'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('title')) {
        return {'success': false, 'message': 'error_field_is_not_empty'};
      } else if (response.body.contains('body')) {
        return {'success': false, 'message': 'error_field_is_not_empty'};
      } else if (response.body.contains('date')) {
        return {'success': false, 'message': 'error_valid_date'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else {
      return {'success': false, 'message': 'error_update_note'};
    }
  }

// Метод для Удаления Заметки Лида
  Future<Map<String, dynamic>> deleteNotes(int noteId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/notices/$noteId');
    if (kDebugMode) {
      //print('ApiService: deleteNotes - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete note!');
    }
  }

// Метод для Получения Сделки в Окно Лида
  Future<List<LeadDeal>> getLeadDeals(int leadId,
      {int page = 1, int perPage = 20}) async {
    // Формируем базовый путь
    final basePath =
        '/deal/get-by-lead-id/$leadId?page=$page&per_page=$perPage';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(basePath);
    if (kDebugMode) {
      //print('ApiService: getLeadDeals - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result']['data'] as List)
          .map((deal) => LeadDeal.fromJson(deal))
          .toList();
    } else {
      throw Exception('Ошибка загрузки заметок');
    }
  }

// Обновленный метод createLead
  Future<Map<String, dynamic>> createLead({
    required String name,
    required int leadStatusId,
    required String phone,
    int? regionId,
    int? managerId,
    int? sourceId,
    String? instaLogin,
    String? facebookLogin,
    String? tgNick,
    DateTime? birthday,
    String? email,
    String? description,
    String? waPhone,
    List<Map<String, dynamic>>? customFields,
    String? manager,
  }) async {
    final Map<String, dynamic> requestData = {
      'name': name,
      'lead_status_id': leadStatusId,
      'phone': phone,
      'position': 1,
      if (regionId != null) 'region_id': regionId,
      if (managerId != null) 'manager_id': managerId,
      if (manager != null) 'manager': manager,
      if (sourceId != null) 'source_id': sourceId,
      if (instaLogin != null) 'insta_login': instaLogin,
      if (facebookLogin != null) 'facebook_login': facebookLogin,
      if (tgNick != null) 'tg_nick': tgNick,
      if (birthday != null) 'birthday': birthday.toIso8601String(),
      if (email != null) 'email': email,
      if (description != null) 'description': description,
      if (waPhone != null) 'wa_phone': waPhone,
      if (customFields != null && customFields.isNotEmpty)
        'lead_custom_fields': customFields,
    };

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead');
    if (kDebugMode) {
      //print('ApiService: createLead - Generated path: $path');
    }

    final response = await _postRequest(path, requestData);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'lead_created_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      }
      if (response.body
          .contains('The email field must be a valid email address.')) {
        return {'success': false, 'message': 'error_enter_email'};
      }
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('insta_login')) {
        return {'success': false, 'message': 'instagram_login_exists'};
      }
      if (response.body.contains('tg_nick')) {
        return {'success': false, 'message': 'telegram_nick_exists'};
      }
      if (response.body.contains('birthday')) {
        return {'success': false, 'message': 'invalid_birthday'};
      }
      if (response.body.contains('wa_phone')) {
        return {'success': false, 'message': 'whatsapp_number_exists'};
      }
      if (response.body.contains('type')) {
        return {'success': false, 'message': 'invalid_field_type'};
      }
      if (response.body.contains('lead_custom_fields')) {
        return {'success': false, 'message': 'invalid_custom_fields'};
      }
      return {'success': false, 'message': 'unknown_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'lead_creation_error'};
    }
  }

  Future<Map<String, dynamic>> createLeadWithData(
    Map<String, dynamic> data, {
    List<String>? filePaths,
  }) async {
    // Формируем путь с query-параметрами
    final updatedPath = await _appendQueryParams('/lead');
    if (kDebugMode) {
      //print('ApiService: createLeadWithData - Generated path: $updatedPath');
    }
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl$updatedPath'));

    // Добавляем поля, кроме lead_custom_fields
    data.forEach((key, value) {
      if (key != 'lead_custom_fields') {
        if (value is List) {
          request.fields[key] = json.encode(value);
        } else if (value != null) {
          request.fields[key] = value.toString();
        }
      }
    });

    // Обрабатываем lead_custom_fields как массив объектов
    if (data['lead_custom_fields'] != null &&
        data['lead_custom_fields'] is List &&
        data['lead_custom_fields'].isNotEmpty) {
      List<Map<String, dynamic>> customFields =
          data['lead_custom_fields'] as List<Map<String, dynamic>>;
      for (int i = 0; i < customFields.length; i++) {
        request.fields['lead_custom_fields[$i][key]'] =
            customFields[i]['key'] ?? '';
        request.fields['lead_custom_fields[$i][value]'] =
            customFields[i]['value'] ?? '';
        request.fields['lead_custom_fields[$i][type]'] =
            customFields[i]['type'] ?? 'string';
      }
    }

    // Добавляем файлы
    if (filePaths != null && filePaths.isNotEmpty) {
      for (var filePath in filePaths) {
        final file = await http.MultipartFile.fromPath('files[]', filePath);
        request.files.add(file);
      }
    }

    final response = await _multipartPostRequest('/lead', request);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'lead_created_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      }
      if (response.body
          .contains('The email field must be a valid email address.')) {
        return {'success': false, 'message': 'error_enter_email'};
      }
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('insta_login')) {
        return {'success': false, 'message': 'instagram_login_exists'};
      }
      if (response.body.contains('facebook_login')) {
        return {'success': false, 'message': 'facebook_login_exists'};
      }
      if (response.body.contains('tg_nick')) {
        return {'success': false, 'message': 'telegram_nick_exists'};
      }
      if (response.body.contains('birthday')) {
        return {'success': false, 'message': 'invalid_birthday'};
      }
      if (response.body.contains('wa_phone')) {
        return {'success': false, 'message': 'whatsapp_number_exists'};
      }
      if (response.body.contains('type')) {
        return {'success': false, 'message': 'invalid_field_type'};
      }
      if (response.body.contains('lead_custom_fields')) {
        return {'success': false, 'message': 'invalid_custom_fields'};
      }
      return {'success': false, 'message': 'unknown_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'lead_creation_error'};
    }
  }

  Future<Map<String, dynamic>> updateLead({
    required int leadId,
    required String name,
    required int leadStatusId,
    required String phone,
    int? regionId,
    int? sourceId,
    int? managerId,
    String? instaLogin,
    String? facebookLogin,
    String? tgNick,
    DateTime? birthday,
    String? email,
    String? description,
    String? waPhone,
    List<Map<String, dynamic>>? customFields, // Изменён тип
    List<Map<String, int>>? directoryValues,
    String? priceTypeId, // Добавляем priceTypeId
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/$leadId');
    if (kDebugMode) {
      //print('ApiService: updateLead - Generated path: $path');
    }

    final response = await _patchRequest(
      path,
      {
        'name': name,
        'lead_status_id': leadStatusId,
        'phone': phone,
        if (regionId != null) 'region_id': regionId,
        if (sourceId != null) 'source_id': sourceId,
        if (managerId != null) 'manager_id': managerId,
        if (instaLogin != null) 'insta_login': instaLogin,
        if (facebookLogin != null) 'facebook_login': facebookLogin,
        if (tgNick != null) 'tg_nick': tgNick,
        if (birthday != null) 'birthday': birthday.toIso8601String(),
        if (email != null) 'email': email,
        if (description != null) 'description': description,
        if (waPhone != null) 'wa_phone': waPhone,
        if (priceTypeId != null)
          'price_type_id': priceTypeId, // Добавляем price_type_id
        'lead_custom_fields': customFields ?? [],
        'directory_values': directoryValues ?? [],
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'lead_updated_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      }
      if (response.body
          .contains('The email field must be a valid email address.')) {
        return {'success': false, 'message': 'error_enter_email'};
      }
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('insta_login')) {
        return {'success': false, 'message': 'instagram_login_exists'};
      }
      if (response.body.contains('facebook_login')) {
        return {'success': false, 'message': 'facebook_login_exists'};
      }
      if (response.body.contains('tg_nick')) {
        return {'success': false, 'message': 'telegram_nick_exists'};
      }
      if (response.body.contains('birthday remont_nullable')) {
        return {'success': false, 'message': 'invalid_birthday'};
      }
      if (response.body.contains('wa_phone')) {
        return {'success': false, 'message': 'whatsapp_number_exists'};
      }
      if (response.body.contains('type')) {
        return {'success': false, 'message': 'invalid_field_type'};
      }
      if (response.body.contains('price_type_id')) {
        return {'success': false, 'message': 'invalid_price_type_id'};
      }
      if (response.body.contains('lead_custom_fields')) {
        return {'success': false, 'message': 'invalid_fields'};
      }
      return {'success': false, 'message': 'unknown_error'};
    } else {
      return {'success': false, 'message': 'error_updated_lead'};
    }
  }

  Future<Map<String, dynamic>> updateLeadWithData({
    required int leadId,
    required Map<String, dynamic> data,
    List<String>? filePaths,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/$leadId');
    if (kDebugMode) {
      //print('ApiService: updateLeadWithData - Generated path: $path');
    }
    var uri = Uri.parse('$baseUrl$path');

    var request = http.MultipartRequest('POST', uri);

    final token = await getToken();
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Device': 'mobile',
    });

    request.fields['name'] = data['name']?.toString() ?? '';
    request.fields['lead_status_id'] = data['lead_status_id']?.toString() ?? '';
    request.fields['phone'] = data['phone']?.toString() ?? '';
    if (data['region_id'] != null) {
      request.fields['region_id'] = data['region_id'].toString();
    }
    if (data['source_id'] != null) {
      request.fields['source_id'] = data['source_id'].toString();
    }
    if (data['manager_id'] != null) {
      request.fields['manager_id'] = data['manager_id'].toString();
    }
    if (data['insta_login'] != null) {
      request.fields['insta_login'] = data['insta_login'].toString();
    }
    if (data['facebook_login'] != null) {
      request.fields['facebook_login'] = data['facebook_login'].toString();
    }
    if (data['tg_nick'] != null) {
      request.fields['tg_nick'] = data['tg_nick'].toString();
    }
    if (data['birthday'] != null) {
      request.fields['birthday'] = data['birthday'].toString();
    }
    if (data['email'] != null) {
      request.fields['email'] = data['email'].toString();
    }
    if (data['description'] != null) {
      request.fields['description'] = data['description'].toString();
    }
    if (data['wa_phone'] != null) {
      request.fields['wa_phone'] = data['wa_phone'].toString();
    }
    if (data['price_type_id'] != null) {
      request.fields['price_type_id'] =
          data['price_type_id'].toString(); // Добавляем price_type_id
    }
    if (data['existing_file_ids'] != null) {
      request.fields['existing_files'] = jsonEncode(data['existing_file_ids']);
    }
    // Добавляем sales_funnel_id из данных, если он присутствует
    if (data['sales_funnel_id'] != null) {
      request.fields['sales_funnel_id'] = data['sales_funnel_id'].toString();
    }
    if (data['duplicate'] != null) {
      request.fields['duplicate'] =
          data['duplicate'].toString(); // Добавляем duplicate
    }
    // Обрабатываем lead_custom_fields
    final customFields = data['lead_custom_fields'] as List<dynamic>? ?? [];
    if (customFields.isNotEmpty) {
      for (int i = 0; i < customFields.length; i++) {
        var field = customFields[i] as Map<String, dynamic>;
        request.fields['lead_custom_fields[$i][key]'] =
            field['key']?.toString() ?? '';
        request.fields['lead_custom_fields[$i][value]'] =
            field['value']?.toString() ?? '';
        request.fields['lead_custom_fields[$i][type]'] =
            field['type']?.toString() ?? 'string';
      }
    }

    // Обрабатываем directory_values
    final directoryValues = data['directory_values'] as List<dynamic>? ?? [];
    if (directoryValues.isNotEmpty) {
      for (int i = 0; i < directoryValues.length; i++) {
        var value = directoryValues[i] as Map<String, dynamic>;
        request.fields['directory_values[$i][directory_id]'] =
            value['directory_id'].toString();
        request.fields['directory_values[$i][entry_id]'] =
            value['entry_id'].toString();
      }
    }

    if (filePaths != null && filePaths.isNotEmpty) {
      for (var filePath in filePaths) {
        final file = await http.MultipartFile.fromPath('files[]', filePath);
        request.files.add(file);
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'lead_updated_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      }
      if (response.body
          .contains('The email field must be a valid email address.')) {
        return {'success': false, 'message': 'error_enter_email'};
      }
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('insta_login')) {
        return {'success': false, 'message': 'instagram_login_exists'};
      }
      if (response.body.contains('facebook_login')) {
        return {'success': false, 'message': 'facebook_login_exists'};
      }
      if (response.body.contains('tg_nick')) {
        return {'success': false, 'message': 'telegram_nick_exists'};
      }
      if (response.body.contains('birthday')) {
        return {'success': false, 'message': 'invalid_birthday'};
      }
      if (response.body.contains('wa_phone')) {
        return {'success': false, 'message': 'whatsapp_number_exists'};
      }
      if (response.body.contains('type')) {
        return {'success': false, 'message': 'invalid_field_type'};
      }
      if (response.body.contains('lead_custom_fields')) {
        return {'success': false, 'message': 'invalid_custom_fields'};
      }
      if (response.body.contains('duplicate')) {
        return {'success': false, 'message': 'invalid_duplicate_value'};
      }
      if (response.body.contains('price_type_id')) {
        return {'success': false, 'message': 'invalid_price_type_id'};
      }
      return {'success': false, 'message': 'unknown_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'error_update_lead'};
    }
  }

// Api Service
  Future<DealNameDataResponse> getAllDealNames() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/service/by-sales-funnel-id');
    if (kDebugMode) {
      //print('ApiService: getAllDealNames - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DealNameDataResponse.fromJson(data);
    } else {
      throw ('Failed to load deal names');
    }
  }

//Метод для получения региона
  Future<RegionsDataResponse> getAllRegion() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/region');
    if (kDebugMode) {
      //print('ApiService: getAllRegion - Generated path: $path');
    }

    final response = await _getRequest(path);

    late RegionsDataResponse dataRegion;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataRegion = RegionsDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {
      // ////print('getAll region!');
    }

    return dataRegion;
  }

//Метод для получения региона
  Future<List<SourceData>> getAllSource() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/source');
    if (kDebugMode) {
      //print('ApiService: getAllSource - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null) {
        List<SourceData> dataSource = List<SourceData>.from(
            data.map((source) => SourceData.fromJson(source)));
        return dataSource;
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }
  }

//Метод для получения Менеджера
  Future<ManagersDataResponse> getAllManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/manager');
    if (kDebugMode) {
      //print('ApiService: getAllManager - Generated path: $path');
    }

    // Используем общий метод для выполнения GET-запроса
    final response = await _getRequest(path);

    late ManagersDataResponse dataManager;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataManager = ManagersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {}

    return dataManager;
  }

//Метод для получения Менеджера
  Future<LeadsMultiDataResponse> getAllLeadMulti() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead');
    if (kDebugMode) {
      //print('ApiService: getAllLeadMulti - Generated path: $path');
    }

    // Используем общий метод для выполнения GET-запроса
    final response = await _getRequest(path);

    late LeadsMultiDataResponse dataLead;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataLead = LeadsMultiDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {}

    return dataLead;
  }

//Метод для получения лида
Future<LeadsDataResponse> getAllLeadWithAllPages() async {
  List<LeadData> allLeads = [];
  int currentPage = 1;
  bool hasMorePages = true;

  while (hasMorePages) {
    try {
      // Добавляем параметр page к запросу
      final path = await _appendQueryParams('/lead?page=$currentPage');

      if (kDebugMode) {
        print('ApiService: getAllLeadWithAllPages - Loading page $currentPage, path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] != null) {
          final pageResponse = LeadsDataResponse.fromJson(data);

          if (pageResponse.result != null && pageResponse.result!.isNotEmpty) {
            allLeads.addAll(pageResponse.result!);

            // Проверяем, есть ли еще страницы
            // Предполагаем, что если количество элементов меньше размера страницы, то это последняя страница
            if (pageResponse.result!.length < 20) {
              hasMorePages = false;
            } else {
              currentPage++;
            }

            if (kDebugMode) {
              print('ApiService: Loaded page $currentPage, items: ${pageResponse.result!.length}, total collected: ${allLeads.length}');
            }
          } else {
            hasMorePages = false;
          }
        } else {
          hasMorePages = false;
        }
      } else {
        throw Exception('Ошибка при получении данных со страницы $currentPage!');
      }

      // Небольшая задержка между запросами, чтобы не перегружать сервер
      if (hasMorePages) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

    } catch (e) {
      if (kDebugMode) {
        print('ApiService: Error loading page $currentPage: $e');
      }
      // Если ошибка на первой странице - пробрасываем её
      if (currentPage == 1) {
        rethrow;
      }
      // Если ошибка на последующих страницах - просто прекращаем загрузку
      hasMorePages = false;
    }
  }

  if (kDebugMode) {
    print('ApiService: Total leads loaded: ${allLeads.length}');
  }

  return LeadsDataResponse(
    result: allLeads,
    errors: null,
  );
}

// Обновляем существующий метод, чтобы использовать новую логику
Future<LeadsDataResponse> getAllLead() async {
  return await getAllLeadWithAllPages();
}

// Метод для Удаления Статуса Лида
  Future<Map<String, dynamic>> deleteLeadStatuses(int leadStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead-status/$leadStatusId');
    if (kDebugMode) {
      //print('ApiService: deleteLeadStatuses - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete leadStatus!');
    }
  }

// Метод для изменения статуса лида в ApiService
  Future<Map<String, dynamic>> updateLeadStatusEdit(
      int leadStatusId, String title, bool isSuccess, bool isFailure) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead-status/$leadStatusId');
    if (kDebugMode) {
      //print('ApiService: updateLeadStatusEdit - Generated path: $path');
    }

    final payload = {
      "title": title,
      "is_success": isSuccess ? 1 : 0,
      "is_failure": isFailure ? 1 : 0,
      "organization_id": await getSelectedOrganization(),
    };

    final response = await _patchRequest(
      path, // Исправлено: Передача пути с query-параметрами
      payload, // Исправлено: Передача `payload` как второго аргумента
    );

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update leadStatus!');
    }
  }

// Метод для Удаления Лида
  Future<Map<String, dynamic>> deleteLead(int leadId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/$leadId');
    if (kDebugMode) {
      //print('ApiService: deleteLead - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete lead!');
    }
  }

// Метод для Получения Сделки в Окно Лида
  Future<List<ContactPerson>> getContactPerson(int leadId) async {
    // Формируем базовый путь
    final basePath = '/contactPerson/$leadId';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(basePath);
    if (kDebugMode) {
      //print('ApiService: getContactPerson - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result'] as List)
          .map((contactPerson) => ContactPerson.fromJson(contactPerson))
          .toList();
    } else {
      throw Exception('Ошибка загрузки Контактное Лицо ');
    }
  }

// Метод для Создания Контактного Лица
  Future<Map<String, dynamic>> createContactPerson({
    required int leadId,
    required String name,
    required String phone,
    required String position,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/contactPerson');
    if (kDebugMode) {
      //print('ApiService: createContactPerson - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'lead_id': leadId,
      'name': name,
      'phone': phone,
      'position': position,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'contact_create_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      } else if (response.body.contains('position')) {
        return {'success': false, 'message': 'field_is_not_empty'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else {
      return {'success': false, 'message': 'error_contact_create'};
    }
  }

// Метод для Создания Контактного Лица
  Future<Map<String, dynamic>> updateContactPerson({
    required int leadId,
    required int contactpersonId,
    required String name,
    required String phone,
    required String position,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/contactPerson/$contactpersonId');
    if (kDebugMode) {
      //print('ApiService: updateContactPerson - Generated path: $path');
    }

    final response = await _patchRequest(path, {
      'lead_id': leadId,
      'name': name,
      'phone': phone,
      'position': position,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'contact_update_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      } else if (response.body.contains('position')) {
        return {'success': false, 'message': 'field_is_not_empty'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else {
      return {'success': false, 'message': 'error_contact_update_successfully'};
    }
  }

// Метод для Удаления контактного Лица
  Future<Map<String, dynamic>> deleteContactPerson(int contactpersonId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/contactPerson/$contactpersonId');
    if (kDebugMode) {
      //print('ApiService: deleteContactPerson - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete contactPerson!');
    }
  }

// Метод для Получения Чата в Окно Лида
  Future<List<LeadNavigateChat>> getLeadToChat(int leadId) async {
    // Формируем базовый путь
    final basePath = '/lead/$leadId/chats';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(basePath);
    if (kDebugMode) {
      //print('ApiService: getLeadToChat - Generated path: $path');
    }

    final response = await _getRequest(path);
    ////print('Request path: $path');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result'] as List)
          .map((leadtochat) => LeadNavigateChat.fromJson(leadtochat))
          .toList();
    } else {
      throw Exception('Ошибка загрузки чата в Лид');
    }
  }

// Метод для получения Источников
  Future<List<SourceLead>> getSourceLead() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/source');
    if (kDebugMode) {
      //print('ApiService: getSourceLead - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////print('Полученные данные: $data');
      return (data as List)
          .map((sourceLead) => SourceLead.fromJson(sourceLead))
          .toList();
    } else {
      throw Exception('Ошибка загрузки источников');
    }
  }

  Future<List<LeadStatusForFilter>> getLeadStatusForFilter() async {
    final path = await _appendQueryParams('/lead/statuses');
    if (kDebugMode) {
      //print('ApiService: getLeadStatusForFilter - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result'] as List)
          .map((leadStatus) => LeadStatusForFilter.fromJson(leadStatus))
          .toList();
    } else {
      throw Exception('Ошибка загрузки статусов лидов');
    }
  }

  Future<List<PriceType>> getPriceType() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/priceType');
    if (kDebugMode) {
      //print('ApiService: getPriceType - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['result']['data'];
      return (data as List)
          .map((priceType) => PriceType.fromJson(priceType))
          .toList();
    } else {
      throw Exception('Ошибка загрузки типов цен');
    }
  }

  /// Метод для отправки на 1С
  Future<void> postLeadToC(int leadId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/lead/sendToOneC/$leadId');
      if (kDebugMode) {
        //print('ApiService: postLeadToC - Generated path: $path');
      }

      final response = await _postRequest(path, {});

      if (response.statusCode == 200) {
        ////print('Успешно отправлено в 1С');
      } else {
        ////print('Ошибка отправки в 1С Лид!');
        throw Exception('Ошибка отправки в 1С!');
      }
    } catch (e) {
      ////print('Произошла ошибка!');
      throw Exception('Ошибка отправки в 1С!');
    }
  }

// Метод для Обновления Данных 1С
  Future getData1C() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/get-all-data');
    if (kDebugMode) {
      //print('ApiService: getData1C - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List).toList();
      } else {
        // throw Exception('Результат отсутствует в ответе');
      }
    } else if (response.statusCode == 500) {
      throw Exception('Ошибка сервера (500): Внутреняя ошибка сервера');
    } else if (response.statusCode == 422) {
      throw Exception('Ошибка валидации (422): Некорректные данные');
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

//Метод для получение кастомных полей Задачи
  Future<Map<String, dynamic>> getCustomFieldslead() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/get/custom-fields');
    if (kDebugMode) {
      //print('ApiService: getCustomFieldslead - Generated path: $path');
    }

    // Выполняем запрос
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return data; // Возвращаем данные, если они есть
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<LeadStatus> getLeadStatus(int leadStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead-status/$leadStatusId');
    if (kDebugMode) {
      //print('ApiService: getLeadStatus - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return LeadStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

  Future<Map<String, dynamic>> addLeadsFromContacts(
      int statusId, List<Map<String, dynamic>> contacts) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/insert');
    if (kDebugMode) {
      //print('ApiService: addLeadsFromContacts - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        'leads': contacts,
      },
    );

    // Parse the response body
    final responseData = json.decode(response.body);

    // If status code is not 200, throw an exception with the response data
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    // Return the response data even for 200 status code
    // since it may contain partial errors
    return responseData;
  }
  //_________________________________ END_____API__SCREEN__LEAD____________________________________________//

  //_________________________________ START___API__SCREEN__DEAL____________________________________________//

  //Метод для получения Сделки через его ID
  Future<DealById> getDealById(int dealId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/deal/$dealId');
      if (kDebugMode) {
        //print('ApiService: getDealById - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonDeal = decodedJson['result'];

        if (jsonDeal == null || jsonDeal['deal_status'] == null) {
          throw Exception('Некорректные данные от API');
        }

        return DealById.fromJson(jsonDeal, jsonDeal['deal_status']['id'] ?? 0);
      } else {
        throw Exception('Ошибка загрузки deal ID!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки deal ID!');
    }
  }

  // Метод для получения списка Сделок с пагинацией
Future<List<Deal>> getDeals(
  int? dealStatusId, {
  int page = 1,
  int perPage = 20,
  String? search,
  List<int>? managers,
  List<int>? leads,
  int? statuses,
  DateTime? fromDate,
  DateTime? toDate,
  int? daysWithoutActivity,
  bool? hasTasks,
  List<Map<String, dynamic>>? directoryValues,
  List<String>? names, // Новое поле
  int? salesFunnelId,
}) async {
  String path = '/deal?page=$page&per_page=$perPage';
  path = await _appendQueryParams(path);
  if (salesFunnelId != null) {
    path += '&sales_funnel_id=$salesFunnelId';
  }

  bool hasFilters = (search != null && search.isNotEmpty) ||
      (managers != null && managers.isNotEmpty) ||
      (leads != null && leads.isNotEmpty) ||
      (fromDate != null) ||
      (toDate != null) ||
      (daysWithoutActivity != null) ||
      (hasTasks == true) ||
      (statuses != null) ||
      (directoryValues != null && directoryValues.isNotEmpty) ||
      (names != null && names.isNotEmpty); // Учитываем names

  if (dealStatusId != null && !hasFilters) {
    path += '&deal_status_id=$dealStatusId';
  }

  if (search != null && search.isNotEmpty) {
    path += '&search=$search';
  }

  if (managers != null && managers.isNotEmpty) {
    for (int i = 0; i < managers.length; i++) {
      path += '&managers[$i]=${managers[i]}';
    }
  }
  if (leads != null && leads.isNotEmpty) {
    for (int i = 0; i < leads.length; i++) {
      path += '&clients[$i]=${leads[i]}';
    }
  }
  if (daysWithoutActivity != null) {
    path += '&lastUpdate=$daysWithoutActivity';
  }
  if (hasTasks == true) {
    path += '&withTasks=1';
  }
  if (statuses != null) {
    path += '&deal_status_id=$statuses';
  }
  if (fromDate != null && toDate != null) {
    final formattedFromDate =
        "${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}";
    final formattedToDate =
        "${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}";
    path += '&created_from=$formattedFromDate&created_to=$formattedToDate';
  }
  if (directoryValues != null && directoryValues.isNotEmpty) {
    for (int i = 0; i < directoryValues.length; i++) {
      path += '&directory_values[$i][directory_id]=${directoryValues[i]['directory_id']}';
      path += '&directory_values[$i][entry_id]=${directoryValues[i]['entry_id']}';
    }
  }
  if (names != null && names.isNotEmpty) {
    for (int i = 0; i < names.length; i++) {
      path += '&names[$i]=${Uri.encodeComponent(names[i])}'; // Кодируем названия
    }
  }

  final response = await _getRequest(path);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['result']['data'] != null) {
      return (data['result']['data'] as List)
          .map((json) => Deal.fromJson(json, dealStatusId ?? -1))
          .toList();
    } else {
      throw Exception('Нет данных о сделках в ответе');
    }
  } else {
    throw Exception('Ошибка загрузки сделок!');
  }
}

// Метод для получения статусов Сделок
  Future<List<DealStatus>> getDealStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/deal/statuses');
      if (kDebugMode) {
        //print('ApiService: getDealStatuses - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          // Принт старых кэшированных данных (если они есть)
          final cachedStatuses =
              prefs.getString('cachedDealStatuses_$organizationId');
          if (cachedStatuses != null) {
            final decodedData = json.decode(cachedStatuses);
          }

          // Обновляем кэш новыми данными
          await prefs.setString('cachedDealStatuses_$organizationId',
              json.encode(data['result']));
          // ////print(
          //     '------------------------------------ Новые данные, которые сохраняются в кэш ---------------------------------');
          // ////print(data['result']); // Новые данные, которые будут сохранены в кэш

          // ////print(
          //     '----p---------------¿-----UPDATE CACHE DEALSTATUS----------------------------');
          // ////print('Статусы сделок обновлены в кэше');

          return (data['result'] as List)
              .map((status) => DealStatus.fromJson(status))
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      ////print('Ошибка загрузки статусов сделок. Используем кэшированные данные.');
      // Если запрос не удался, пытаемся загрузить данные из кэша
      final cachedStatuses =
          prefs.getString('cachedDealStatuses_$organizationId');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => DealStatus.fromJson(status))
            .toList();
        return cachedList;
      } else {
        throw Exception(
            'Ошибка загрузки статусов сделок и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasDeals(int dealStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<Deal> deals =
          await getDeals(dealStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return deals.isNotEmpty;
    } catch (e) {
      ////print('Error while checking if status has deals!');
      return false;
    }
  }

// Метод для создания Статуса Сделки
  Future<Map<String, dynamic>> createDealStatus(
    String title,
    String color,
    int? day,
    String? notificationMessage,
    bool showOnMainPage,
    bool isSuccess,
    bool isFailure,
  ) async {
    final path = await _appendQueryParams('/deal/statuses');
    if (kDebugMode) {
      //print('ApiService: createDealStatus - Generated path: $path');
    }

    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    final response = await _postRequest(
      path,
      {
        'title': title,
        'day': day,
        'color': color,
        'notification_message': notificationMessage,
        'show_on_main_page': showOnMainPage ? 1 : 0,
        'is_success': isSuccess ? 1 : 0,
        'is_failure': isFailure ? 1 : 0,
        'organization_id': organizationId?.toString() ?? '',
        if (salesFunnelId != null) 'sales_funnel_id': salesFunnelId.toString(),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Статус сделки успешно создан'};
    } else {
      return {'success': false, 'message': 'Ошибка создания статуса сделки!'};
    }
  }

// Метод для получения Истории Сделки
  Future<List<DealHistory>> getDealHistory(int dealId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/deal/history/$dealId');
      if (kDebugMode) {
        //print('ApiService: getDealHistory - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => DealHistory.fromJson(json)).toList();
      } else {
        ////print('Failed to load deal history!');
        throw Exception('Ошибка загрузки истории сделки!');
      }
    } catch (e) {
      ////print('Error occurred!');
      throw Exception('Ошибка загрузки истории сделки!');
    }
  }

  Future<List<OrderHistory>> getOrderHistory(int orderId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order/history/$orderId');
      if (kDebugMode) {
        //print('ApiService: getOrderHistory - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => OrderHistory.fromJson(json)).toList();
      } else {
        ////print('Failed to load order history!');
        throw Exception('Ошибка загрузки истории заказа!');
      }
    } catch (e) {
      ////print('Error occurred: $e');
      throw Exception('Ошибка загрузки истории заказа!');
    }
  }

// Обновление статуса карточки Сделки в колонке
  Future<void> updateDealStatus(int dealId, int position, int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/deal/changeStatus/$dealId');
    if (kDebugMode) {
      //print('ApiService: updateDealStatus - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        'position': 1,
        'status_id': statusId,
      },
    );

    if (response.statusCode == 200) {
      ////print('Статус задачи успешно обновлен.');
    } else if (response.statusCode == 422) {
      throw DealStatusUpdateException(
        422,
        'Вы не можете переместить задачу на этот статус',
      );
    } else {
      throw Exception('Ошибка обновления задач сделки!');
    }
  }

// Метод для Получения Сделки в Окно Лида
  Future<List<DealTask>> getDealTasks(int dealId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/getByDeal/$dealId');
    if (kDebugMode) {
      //print('ApiService: getDealTasks - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result'] as List)
          .map((task) => DealTask.fromJson(task))
          .toList();
    } else {
      throw Exception('Ошибка загрузки сделки задачи');
    }
  }

// Метод для создания Сделки
  Future<Map<String, dynamic>> createDeal({
    required String name,
    required int dealStatusId,
    required int? managerId,
    required DateTime? startDate,
    required DateTime? endDate,
    required String sum,
    String? description,
    int? dealtypeId,
    int? leadId,
    List<Map<String, dynamic>>? customFields,
    List<Map<String, int>>? directoryValues,
    List<String>? filePaths,
  }) async {
    try {
      // Формируем путь с query-параметрами
      final updatedPath = await _appendQueryParams('/deal');
      if (kDebugMode) {
        //print('ApiService: createDeal - Generated path: $updatedPath');
      }
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl$updatedPath'));

      request.fields['name'] = name;
      request.fields['deal_status_id'] = dealStatusId.toString();
      request.fields['position'] = '1';
      if (managerId != null) {
        request.fields['manager_id'] = managerId.toString();
      }
      if (startDate != null) {
        request.fields['start_date'] =
            DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        request.fields['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }
      request.fields['sum'] = sum;
      if (description != null) {
        request.fields['description'] = description;
      }
      if (dealtypeId != null) {
        request.fields['deal_type_id'] = dealtypeId.toString();
      }
      if (leadId != null) {
        request.fields['lead_id'] = leadId.toString();
      }

      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['deal_custom_fields[$i][key]'] = field['key'] ?? '';
          request.fields['deal_custom_fields[$i][value]'] =
              field['value'] ?? '';
          request.fields['deal_custom_fields[$i][type]'] =
              field['type'] ?? 'string';
        }
      }

      if (directoryValues != null && directoryValues.isNotEmpty) {
        for (int i = 0; i < directoryValues.length; i++) {
          var directoryValue = directoryValues[i];
          request.fields['directory_values[$i][entry_id]'] =
              directoryValue['entry_id'].toString();
          request.fields['directory_values[$i][directory_id]'] =
              directoryValue['directory_id'].toString();
        }
      }

      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }

      final response = await _multipartPostRequest('/deal', request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'deal_created_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('name')) {
          return {'success': false, 'message': 'invalid_name_length'};
        }
        if (response.body.contains('directory_values')) {
          return {'success': false, 'message': 'error_directory_values'};
        }
        if (response.body.contains('type')) {
          return {'success': false, 'message': 'invalid_field_type'};
        }
        if (response.body.contains('deal_custom_fields')) {
          return {'success': false, 'message': 'invalid_deal_custom_fields'};
        }
        return {'success': false, 'message': 'unknown_error'};
      } else if (response.statusCode == 500) {
        return {'success': false, 'message': 'error_server_text'};
      } else {
        return {'success': false, 'message': 'error_deal_create_successfully'};
      }
    } catch (e) {
      return {'success': false, 'message': 'error_deal_create_successfully'};
    }
  }

  Future<Map<String, dynamic>> updateDeal({
    required int dealId,
    required String name,
    required int dealStatusId,
    required int? managerId,
    required DateTime? startDate,
    required DateTime? endDate,
    required String sum,
    String? description,
    int? dealtypeId,
    required int? leadId,
    List<Map<String, dynamic>>? customFields,
    List<Map<String, int>>? directoryValues,
    List<String>? filePaths,
    List<DealFiles>? existingFiles,
  }) async {
    // Формируем путь с query-параметрами
    final updatedPath = await _appendQueryParams('/deal/$dealId');
    if (kDebugMode) {
      //print('ApiService: updateDeal - Generated path: $updatedPath');
    }
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl$updatedPath'));

    request.fields['name'] = name;
    request.fields['deal_status_id'] = dealStatusId.toString();
    if (managerId != null) request.fields['manager_id'] = managerId.toString();
    if (startDate != null)
      request.fields['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
    if (endDate != null)
      request.fields['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
    if (sum.isNotEmpty) request.fields['sum'] = sum;
    if (description != null) request.fields['description'] = description;
    if (dealtypeId != null)
      request.fields['deal_type_id'] = dealtypeId.toString();
    if (leadId != null) request.fields['lead_id'] = leadId.toString();

    final customFieldsList = customFields ?? [];
    if (customFieldsList.isNotEmpty) {
      for (int i = 0; i < customFieldsList.length; i++) {
        var field = customFieldsList[i];
        request.fields['deal_custom_fields[$i][key]'] =
            field['key']!.toString();
        request.fields['deal_custom_fields[$i][value]'] =
            field['value']!.toString();
        request.fields['deal_custom_fields[$i][type]'] =
            field['type']?.toString() ?? 'string';
      }
    }

    final directoryValuesList = directoryValues ?? [];
    if (directoryValuesList.isNotEmpty) {
      for (int i = 0; i < directoryValuesList.length; i++) {
        var value = directoryValuesList[i];
        request.fields['directory_values[$i][directory_id]'] =
            value['directory_id'].toString();
        request.fields['directory_values[$i][entry_id]'] =
            value['entry_id'].toString();
      }
    }

    if (existingFiles != null && existingFiles.isNotEmpty) {
      final existingFileIds = existingFiles.map((file) => file.id).toList();
      request.fields['existing_files'] = jsonEncode(existingFileIds);
    }

    if (filePaths != null && filePaths.isNotEmpty) {
      for (var filePath in filePaths) {
        final file = await http.MultipartFile.fromPath('files[]', filePath);
        request.files.add(file);
      }
    }

    final response = await _multipartPostRequest('/deal/$dealId', request);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'deal_updated_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('"name"')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('sum')) {
        return {'success': false, 'message': 'invalid_sum_format'};
      }
      if (response.body.contains('type')) {
        return {'success': false, 'message': 'invalid_field_type'};
      }
      if (response.body.contains('deal_custom_fields')) {
        return {'success': false, 'message': 'invalid_custom_fields'};
      }
      return {'success': false, 'message': 'unknown_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'error_deal_update'};
    }
  }

// Метод для Удаления Статуса Сделки
  Future<Map<String, dynamic>> deleteDealStatuses(int dealStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/deal/statuses/$dealStatusId');
    if (kDebugMode) {
      //print('ApiService: deleteDealStatuses - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete dealStatus!');
    }
  }

// Метод для Удаления Сделки
  Future<Map<String, dynamic>> deleteDeal(int dealId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/deal/$dealId');
    if (kDebugMode) {
      //print('ApiService: deleteDeal - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete deal!');
    }
  }

// Метод для получения кастомных полей Сделки
  Future<Map<String, dynamic>> getCustomFieldsdeal() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/deal/get/custom-fields');
    if (kDebugMode) {
      //print('ApiService: getCustomFieldsdeal - Generated path: $path');
    }

    // Выполняем запрос
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return data; // Возвращаем данные, если они есть
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

// Метод для изменения статуса Сделки в ApiService
  Future<Map<String, dynamic>> updateDealStatusEdit(
    int dealStatusId,
    String title,
    int day,
    bool isSuccess,
    bool isFailure,
    String notificationMessage,
    bool showOnMainPage,
  ) async {
    final path = await _appendQueryParams('/deal/statuses/$dealStatusId');
    if (kDebugMode) {
      //print('ApiService: updateDealStatusEdit - Generated path: $path');
    }

    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel(); // Добавляем вручную

    final payload = {
      "title": title,
      "day": day,
      "color": "#000",
      "is_success": isSuccess ? 1 : 0,
      "is_failure": isFailure ? 1 : 0,
      "notification_message": notificationMessage,
      "show_on_main_page": showOnMainPage ? 1 : 0,
      "organization_id": organizationId?.toString() ?? '', // Уже есть
      if (salesFunnelId != null)
        "sales_funnel_id":
            salesFunnelId.toString(), // Добавляем в body, если не null
    };

    final response = await _patchRequest(
      path,
      payload,
    );

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update dealStatus!');
    }
  }

  Future<DealStatus> getDealStatus(int dealStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/deal/statuses/$dealStatusId');
    if (kDebugMode) {
      //print('ApiService: getDealStatus - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return DealStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

//_________________________________ END_____API_SCREEN__DEAL____________________________________________//
//_________________________________ START___API__SCREEN__TASK____________________________________________//

// Метод для получения Задачи через его ID
  Future<TaskById> getTaskById(int taskId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task/$taskId');
      if (kDebugMode) {
        //print('ApiService: getTaskById - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonTask = decodedJson['result'];

        if (jsonTask == null || jsonTask['taskStatus'] == null) {
          throw Exception('Некорректные данные от API');
        }

        // Используем правильное имя ключа 'taskStatus' для получения статуса задачи
        return TaskById.fromJson(jsonTask, jsonTask['taskStatus']['id'] ?? 0);
      } else if (response.statusCode == 404) {
        throw Exception('Ресурс с задачи $taskId не найден');
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера. Попробуйте позже');
      } else {
        throw Exception('Ошибка загрузки task ID!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки task ID');
    }
  }

// API Service
  Future<List<Task>> getTasks(
    int? taskStatusId, {
    int page = 1,
    int perPage = 20,
    String? search,
    List<int>? users,
    int? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    bool? overdue,
    bool? hasFile,
    bool? hasDeal,
    bool? urgent,
    DateTime? deadlinefromDate,
    DateTime? deadlinetoDate,
    String? project,
    List<String>? authors,
    String? department,
    List<Map<String, dynamic>>? directoryValues, // Добавляем directoryValues
  }) async {
    // Формируем базовый путь
    String path = '/task?page=$page&per_page=$perPage';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //print('ApiService: getTasks - Generated path: $path');
    }

    bool hasFilters = (search != null && search.isNotEmpty) ||
        (users != null && users.isNotEmpty) ||
        (fromDate != null) ||
        (toDate != null) ||
        (statuses != null) ||
        overdue == true ||
        hasFile == true ||
        hasDeal == true ||
        urgent == true ||
        (deadlinefromDate != null) ||
        (deadlinetoDate != null) ||
        (project != null && project.isNotEmpty) ||
        (authors != null && authors.isNotEmpty) ||
        (department != null && department.isNotEmpty) ||
        (directoryValues != null &&
            directoryValues.isNotEmpty); // Проверяем directoryValues

    if (taskStatusId != null && !hasFilters) {
      path += '&task_status_id=$taskStatusId';
    }
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }
    if (users != null && users.isNotEmpty) {
      for (int i = 0; i < users.length; i++) {
        path += '&users[$i]=${users[i]}';
      }
    }
    if (statuses != null) {
      path += '&task_status_id=$statuses';
    }
    if (fromDate != null && toDate != null) {
      final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
      path += '&from=$formattedFromDate&to=$formattedToDate';
    }
    if (overdue == true) {
      path += '&overdue=1';
    }
    if (hasFile == true) {
      path += '&hasFile=1';
    }
    if (hasDeal == true) {
      path += '&hasDeal=1';
    }
    if (urgent == true) {
      path += '&urgent=1';
    }
    if (deadlinefromDate != null && deadlinetoDate != null) {
      final formattedFromDate =
          DateFormat('yyyy-MM-dd').format(deadlinefromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(deadlinetoDate);
      path += '&deadline_from=$formattedFromDate&deadline_to=$formattedToDate';
    }
    if (project != null && project.isNotEmpty) {
      path += '&project=$project';
    }
    if (authors != null && authors.isNotEmpty) {
      for (int i = 0; i < authors.length; i++) {
        path += '&authors[$i]=${authors[i]}';
      }
    }
    if (department != null && department.isNotEmpty) {
      path += '&department_id=$department';
    }
    if (directoryValues != null && directoryValues.isNotEmpty) {
      for (int i = 0; i < directoryValues.length; i++) {
        path +=
            '&directory_values[$i][directory_id]=${directoryValues[i]['directory_id']}';
        path +=
            '&directory_values[$i][entry_id]=${directoryValues[i]['entry_id']}';
      }
    }

    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => Task.fromJson(json, taskStatusId ?? -1))
            .toList();
      } else {
        throw Exception('Нет данных о задачах в ответе');
      }
    } else {
      ////print('Error response! - ${response.body}');
      throw Exception('Ошибка загрузки задач!');
    }
  }

// Метод для получения статусов задач
  Future<List<TaskStatus>> getTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task-status');
      if (kDebugMode) {
        //print('ApiService: getTaskStatuses - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          // Принт старых кэшированных данных (если они есть)
          final cachedStatuses =
              prefs.getString('cachedTaskStatuses_$organizationId');
          if (cachedStatuses != null) {
            final decodedData = json.decode(cachedStatuses);
            // ////print(
            //     '------------------------------ Старые данные в кэше ------------------------------');
            // ////print(decodedData); // Старые данные
          }

          // Обновляем кэш новыми данными
          await prefs.setString('cachedTaskStatuses_$organizationId',
              json.encode(data['result']));
          // ////print(
          //     '------------------------------------ Новые данные, которые сохраняются в кэш ---------------------------------');
          // ////print(data['result']); // Новые данные, которые будут сохранены в кэш

          return (data['result'] as List)
              .map((status) => TaskStatus.fromJson(status))
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      ////print('Ошибка загрузки статусов задач. Используем кэшированные данные.');
      // Если запрос не удался, пытаемся загрузить данные из кэша
      final cachedStatuses =
          prefs.getString('cachedTaskStatuses_$organizationId');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => TaskStatus.fromJson(status))
            .toList();
        return cachedList;
      } else {
        throw Exception(
            'Ошибка загрузки статусов задач и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasTasks(int taskStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<Task> tasks =
          await getTasks(taskStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return tasks.isNotEmpty;
    } catch (e) {
      ////print('Error while checking if status has deals!');
      return false;
    }
  }

// Обновление статуса карточки Задачи в колонке
  Future<void> updateTaskStatus(int taskId, int position, int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/changeStatus/$taskId');
    if (kDebugMode) {
      //print('ApiService: updateTaskStatus - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'position': 1,
      'status_id': statusId,
    });

    if (response.statusCode == 200) {
      ////print('Статус задачи успешно обновлен');
    } else if (response.statusCode == 422) {
      throw TaskStatusUpdateException(
          422, 'Вы не можете переместить задачу на этот статус');
    } else {
      throw Exception('Ошибка обновления задач сделки!');
    }
  }

  Map<String, dynamic> _handleTaskResponse(
      http.Response response, String operation) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      // Проверяем наличие ошибок в ответе
      if (data['errors'] != null) {
        return {
          'success': false,
          'message': 'Ошибка ${operation} задачи: ${data['errors']}',
        };
      }

      return {
        'success': true,
        'message':
            'Задача ${operation == 'создания' ? 'создана' : 'обновлена'} успешно.',
        'data': data['result'],
      };
    }

    if (response.statusCode == 422) {
      final data = json.decode(response.body);
      final validationErrors = {
        'name': 'Название задачи должно содержать минимум 3 символа.',
        'from': 'Неверный формат даты начала.',
        'to': 'Неверный формат даты окончания.',
        'project_id': 'Указанный проект не существует.',
        'user_id': 'Указанный пользователь не существует.',
        // Убрана валидация файла
      };

      // Игнорируем ошибки валидации файла
      if (data['errors']?['file'] != null) {
        data['errors'].remove('file');
      }

      // Проверяем каждое поле на наличие ошибки, кроме файла
      for (var entry in validationErrors.entries) {
        if (data['errors']?[entry.key] != null) {
          return {'success': false, 'message': entry.value};
        }
      }

      // Если остались только ошибки файла, считаем что валидация прошла успешно
      if (data['errors']?.isEmpty ?? true) {
        return {
          'success': true,
          'message':
              'Задача ${operation == 'создания' ? 'создана' : 'обновлена'} успешно.',
        };
      }

      return {
        'success': false,
        'message': 'Ошибка валидации: ${data['errors'] ?? response.body}',
      };
    }

    return {
      'success': false,
      'message': 'Ошибка ${operation} задачи!',
    };
  }

  // Общий метод обработки ошибок
  Exception _handleErrorResponse(http.Response response, String operation) {
    try {
      final data = json.decode(response.body);
      final errorMessage = data['errors'] ?? data['message'] ?? response.body;
      return Exception('Ошибка ${operation}! - $errorMessage');
    } catch (e) {
      return Exception('Ошибка ${operation}! - ${response.body}');
    }
  }

// Создает новый статус задачи
  Future<Map<String, dynamic>> CreateTaskStatusAdd({
    required int taskStatusNameId,
    required int projectId,
    required bool needsPermission,
    List<int>? roleIds,
    bool? finalStep,
  }) async {
    try {
      // Формируем данные для запроса
      final Map<String, dynamic> data = {
        'task_status_name_id': taskStatusNameId,
        'project_id': projectId,
        'needs_permission': needsPermission ? 1 : 0,
      };

      // Добавляем final_step, если оно не null
      if (finalStep != null) {
        data['final_step'] = finalStep;
      }

      // Обрабатываем список ролей, если он существует
      if (roleIds != null && roleIds.isNotEmpty) {
        data['roles'] = roleIds.map((roleId) => {'role_id': roleId}).toList();
      }

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task-status');
      if (kDebugMode) {
        //print('ApiService: CreateTaskStatusAdd - Generated path: $path');
      }

      // Выполняем запрос
      final response = await _postRequest(path, data);

      // Проверяем статус ответа
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Статус задачи успешно создан',
          'data': responseData,
        };
      }

      // Обрабатываем различные коды ошибок
      String errorMessage;
      switch (response.statusCode) {
        case 400:
          errorMessage = 'Неверные данные запроса';
          break;
        case 401:
          errorMessage = 'Необходима авторизация';
          break;
        case 403:
          errorMessage = 'Недостаточно прав для создания статуса';
          break;
        case 404:
          errorMessage = 'Ресурс не найден';
          break;
        case 409:
          errorMessage = 'Конфликт при создании статуса';
          break;
        case 500:
          errorMessage = 'Внутренняя ошибка сервера';
          break;
        default:
          errorMessage = 'Произошла ошибка при создании статуса';
      }

      return {
        'success': false,
        'message': '$errorMessage!',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при выполнении запроса!',
        'error': e.toString(),
      };
    }
  }

// Метод для создания задачи из сделки
  Future<Map<String, dynamic>> createTaskFromDeal({
    required int dealId,
    required String name,
    required int? statusId,
    required int? taskStatusId,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? projectId,
    List<int>? userId,
    String? description,
    List<Map<String, dynamic>>? customFields,
    List<String>? filePaths,
    List<Map<String, int>>? directoryValues,
    int position = 1,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task/createFromDeal/$dealId');
      if (kDebugMode) {
        //print('ApiService: createTaskFromDeal - Generated path: $path');
      }
      var uri = Uri.parse('$baseUrl$path');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['position'] = position.toString();

      if (priority != null) {
        request.fields['priority_level'] = priority.toString();
      }
      if (startDate != null) {
        request.fields['from'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        request.fields['to'] = DateFormat('yyyy-MM-dd').format(endDate);
      }
      if (projectId != null) {
        request.fields['project_id'] = projectId.toString();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      if (userId != null && userId.isNotEmpty) {
        for (int i = 0; i < userId.length; i++) {
          request.fields['users[$i][user_id]'] = userId[i].toString();
        }
      }

      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['task_custom_fields[$i][key]'] = field['key'] ?? '';
          request.fields['task_custom_fields[$i][value]'] =
              field['value'] ?? '';
          request.fields['task_custom_fields[$i][type]'] =
              field['type'] ?? 'string';
        }
      }

      if (directoryValues != null && directoryValues.isNotEmpty) {
        for (int i = 0; i < directoryValues.length; i++) {
          var directoryValue = directoryValues[i];
          request.fields['directory_values[$i][entry_id]'] =
              directoryValue['entry_id'].toString();
          request.fields['directory_values[$i][directory_id]'] =
              directoryValue['directory_id'].toString();
        }
      }

      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'task_deal_create_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'error_start_date_task',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'error_end_date_task',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'error_priority_level',
          };
        }
        if (response.body.contains('directory_values')) {
          return {
            'success': false,
            'message': 'error_directory_values',
          };
        }
        if (response.body.contains('type')) {
          return {
            'success': false,
            'message': 'invalid_field_type',
          };
        }
        if (response.body.contains('task_custom_fields')) {
          return {
            'success': false,
            'message': 'invalid_task_custom_fields',
          };
        }
        return {
          'success': false,
          'message': 'unknown_error',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        return {
          'success': false,
          'message': 'error_create_task',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_create_task',
      };
    }
  }

// Метод для создания задачи
  Future<Map<String, dynamic>> createTask({
    required String name,
    required int? statusId,
    required int? taskStatusId,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? projectId,
    List<int>? userId,
    String? description,
    List<Map<String, dynamic>>? customFields,
    List<String>? filePaths,
    List<Map<String, int>>? directoryValues,
    int position = 1,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task');
      if (kDebugMode) {
        //print('ApiService: createTask - Generated path: $path');
      }
      var uri = Uri.parse('$baseUrl$path');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;
      request.fields['status_id'] = statusId.toString();
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['position'] = position.toString();
      request.fields['organization_id'] =
          (await getSelectedOrganization()).toString();

      if (priority != null) {
        request.fields['priority_level'] = priority.toString();
      }
      if (startDate != null) {
        request.fields['from'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        request.fields['to'] = DateFormat('yyyy-MM-dd').format(endDate);
      }
      if (projectId != null) {
        request.fields['project_id'] = projectId.toString();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      if (userId != null && userId.isNotEmpty) {
        for (int i = 0; i < userId.length; i++) {
          request.fields['users[$i][user_id]'] = userId[i].toString();
        }
      }

      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['task_custom_fields[$i][key]'] = field['key'] ?? '';
          request.fields['task_custom_fields[$i][value]'] =
              field['value'] ?? '';
          request.fields['task_custom_fields[$i][type]'] =
              field['type'] ?? 'string';
        }
      }

      if (directoryValues != null && directoryValues.isNotEmpty) {
        for (int i = 0; i < directoryValues.length; i++) {
          var directoryValue = directoryValues[i];
          request.fields['directory_values[$i][entry_id]'] =
              directoryValue['entry_id'].toString();
          request.fields['directory_values[$i][directory_id]'] =
              directoryValue['directory_id'].toString();
        }
      }

      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'task_create_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'error_start_date_task',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'error_end_date_task',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'error_priority_level',
          };
        }
        if (response.body.contains('directory_values')) {
          return {
            'success': false,
            'message': 'error_directory_values',
          };
        }
        if (response.body.contains('type')) {
          return {
            'success': false,
            'message': 'invalid_field_type',
          };
        }
        if (response.body.contains('task_custom_fields')) {
          return {
            'success': false,
            'message': 'invalid_task_custom_fields',
          };
        }
        return {
          'success': false,
          'message': 'unknown_error',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        return {
          'success': false,
          'message': 'error_create_task',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_create_task',
      };
    }
  }

// Метод для обновления задачи
  Future<Map<String, dynamic>> updateTask({
    required int taskId,
    required String name,
    required int taskStatusId,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? projectId,
    List<int>? userId,
    String? description,
    List<String>? filePaths,
    List<Map<String, dynamic>>? customFields,
    List<TaskFiles>? existingFiles,
    List<Map<String, int>>? directoryValues,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task/$taskId');
      if (kDebugMode) {
        //print('ApiService: updateTask - Generated path: $path');
      }
      var uri = Uri.parse('$baseUrl$path');

      // Создаем multipart request
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем все поля в формате form-data
      request.fields['name'] = name;
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['_method'] = 'POST'; // Для эмуляции PUT запроса

      if (priority != null) {
        request.fields['priority_level'] = priority;
      }
      if (startDate != null) {
        request.fields['from'] = startDate.toString().split(' ')[0];
      }
      if (endDate != null) {
        request.fields['to'] = endDate.toString().split(' ')[0];
      }

      if (projectId != null) {
        request.fields['project_id'] = projectId.toString();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      // Добавляем пользователей
      if (userId != null && userId.isNotEmpty) {
        for (int i = 0; i < userId.length; i++) {
          request.fields['users[$i][user_id]'] = userId[i].toString();
        }
      }

      // Добавляем кастомные поля
      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['task_custom_fields[$i][key]'] =
              field['key']!.toString();
          request.fields['task_custom_fields[$i][value]'] =
              field['value']!.toString();
          request.fields['task_custom_fields[$i][type]'] =
              field['type']?.toString() ?? 'string';
        }
      }

      // Добавляем ID существующих файлов
      if (existingFiles != null && existingFiles.isNotEmpty) {
        for (int i = 0; i < existingFiles.length; i++) {
          request.fields['existing_files[$i]'] = existingFiles[i].id.toString();
        }
      }
      if (directoryValues != null && directoryValues.isNotEmpty) {
        directoryValues.asMap().forEach((i, value) {
          request.fields['directory_values[$i][entry_id]'] =
              value['entry_id'].toString();
          request.fields['directory_values[$i][directory_id]'] =
              value['directory_id'].toString();
        });
      }
      // Добавляем новые файлы
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }
      // Отправляем запрос
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'task_update_successfully',
        };
      } else if (response.statusCode == 422) {
        ////print('Server Response: ${response.body}'); // Добавим для отладки

        // Обработка ошибок валидации
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'error_start_date_task',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'error_end_date_task',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'error_priority_level',
          };
        }
        return {
          'success': false,
          'message': 'unknown_error',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        ////print('Server Response: ${response.body}'); // Добавим для отладки

        return {
          'success': false,
          'message': 'error_task_update_successfully',
        };
      }
    } catch (e) {
      ////print('Update Task Error: $e'); // Добавим для отладки

      return {
        'success': false,
        'message': 'error_task_update_successfully',
      };
    }
  }

// Метод для получения Истории Задачи
  Future<List<TaskHistory>> getTaskHistory(int taskId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task/history/$taskId');
      if (kDebugMode) {
        //print('ApiService: getTaskHistory - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => TaskHistory.fromJson(json)).toList();
      } else {
        ////print('Failed to load task history!');
        throw Exception('Ошибка загрузки истории задач!');
      }
    } catch (e) {
      ////print('Error occurred!');
      throw Exception('Ошибка загрузки истории задач!');
    }
  }

// Метод для получения Проекта
  Future<ProjectsDataResponse> getAllProject() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/project');
    if (kDebugMode) {
      //print('ApiService: getAllProject - Generated path: $path');
    }

    final response = await _getRequest(path);

    late ProjectsDataResponse dataProject;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataProject = ProjectsDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {}

    return dataProject;
  }

// Метод для получения Проекта
  Future<ProjectTaskDataResponse> getTaskProject() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/get/projects');
    if (kDebugMode) {
      //print('ApiService: getTaskProject - Generated path: $path');
    }

    final response = await _getRequest(path);

    late ProjectTaskDataResponse dataProject;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataProject = ProjectTaskDataResponse.fromJson(data);
      } else {
        throw ('Результат отсутствует в ответе');
      }
    } else if (response.statusCode == 404) {
      throw ('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw ('Внутренняя ошибка сервера');
    } else {
      throw ('Ошибка при получении данных!');
    }

    if (kDebugMode) {
      // ////print('getAll project!');
    }

    return dataProject;
  }

// Метод для получения Пользователя
  Future<List<UserTask>> getUserTask() async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/user');
      if (kDebugMode) {
        //print('ApiService: getUserTask - Generated path: $path');
      }

      ////print('Отправка запроса на /user');
      final response = await _getRequest(path);
      // ////print('Статус ответа!');
      // ////print('Тело ответа!');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Убедитесь, что данные соответствуют ожидаемой структуре
        if (data['result'] != null && data['result'] is List) {
          final usersList = (data['result'] as List)
              .map((user) => UserTask.fromJson(user))
              .toList();

          return usersList;
        } else {
          throw Exception('Неверная структура данных пользователей');
        }
      } else {
        throw Exception('Ошибка сервера!');
      }
    } catch (e) {
      rethrow;
    }
  }

// Метод для получения Роли
  Future<List<Role>> getRoles() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/role');
    if (kDebugMode) {
      //print('ApiService: getRoles - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((role) => Role.fromJson(role))
            .toList();
      } else {
        throw Exception('Роли не найдены');
      }
    } else {
      throw Exception('Ошибка при получении ролей!');
    }
  }

// Метод для получения Статуса задачи
  Future<List<StatusName>> getStatusName() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/taskStatusName');
    if (kDebugMode) {
      //print('ApiService: getStatusName - Generated path: $path');
    }

    ////print('Начало запроса статусов задач'); // Отладочный вывод
    final response = await _getRequest(path);
    ////print('Статус код ответа!'); // Отладочный вывод

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////print('Полученные данные: $data'); // Отладочный вывод

      if (data['result'] != null) {
        final statusList = (data['result'] as List)
            .map((name) => StatusName.fromJson(name))
            .toList();
        ////print(
        // 'Преобразованный список статусов: $statusList'); // Отладочный вывод
        return statusList;
      } else {
        throw Exception('Статусы задач не найдены');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

// Метод для Удаления Задачи
  Future<Map<String, dynamic>> deleteTask(int taskId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/$taskId');
    if (kDebugMode) {
      //print('ApiService: deleteTask - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete task!');
    }
  }

// Метод для Удаления Статуса Задачи
  Future<Map<String, dynamic>> deleteTaskStatuses(int taskStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task-status/$taskStatusId');
    if (kDebugMode) {
      //print('ApiService: deleteTaskStatuses - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete taskStatus!');
    }
  }

// Метод для завершения задачи
  Future<Map<String, dynamic>> finishTask(int taskId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/finish');
    if (kDebugMode) {
      //print('ApiService: finishTask - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'task_id': taskId,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Задача успешно завершена'};
    } else if (response.statusCode == 422) {
      try {
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ??
            'Неизвестная ошибка при завершении задачи';
        return {
          'success': false,
          'message': errorMessage,
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Ошибка обработки ответа сервера',
        };
      }
    } else {
      return {'success': false, 'message': 'Ошибка завершения задачи!'};
    }
  }

// Метод для получения кастомных полей Задачи
  Future<Map<String, dynamic>> getCustomFields() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/get/custom-fields');
    if (kDebugMode) {
      //print('ApiService: getCustomFields - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return data; // Возвращаем данные, если они есть
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<TaskStatus> getTaskStatus(int taskStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task-status/$taskStatusId');
    if (kDebugMode) {
      //print('ApiService: getTaskStatus - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return TaskStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

// Метод для изменения статуса задачи в ApiService
  Future<Map<String, dynamic>> updateTaskStatusEdit({
    required int taskStatusId,
    required String name,
    required bool needsPermission,
    required bool finalStep,
    required bool checkingStep,
    required List<int> roleIds,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task-status/$taskStatusId');
    if (kDebugMode) {
      //print('ApiService: updateTaskStatusEdit - Generated path: $path');
    }

    final roles = roleIds.map((roleId) => {"role_id": roleId}).toList();

    final payload = {
      "task_status_name_id": taskStatusId,
      "needs_permission": needsPermission ? 1 : 0,
      "final_step": finalStep ? 1 : 0,
      "checking_step": checkingStep ? 1 : 0,
      "roles": roles,
      "organization_id": await getSelectedOrganization(),
    };

    final response = await _patchRequest(
      path,
      payload,
    );

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update task status!');
    }
  }

  Future<Map<String, dynamic>> deleteTaskFile(int fileId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/deleteFile/$fileId');
    if (kDebugMode) {
      //print('ApiService: deleteTaskFile - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete task file!');
    }
  }

  Future<List<Department>> getDepartments() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/department');
    if (kDebugMode) {
      //print('ApiService: getDepartments - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result']; // Извлекаем массив из ключа "result"
      ////print('Полученные данные отделов: $result');
      return (result as List)
          .map((department) => Department.fromJson(department))
          .toList();
    } else {
      throw Exception('Ошибка загрузки отделов');
    }
  }

  Future<DirectoryDataResponse> getDirectory() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/directory');
    if (kDebugMode) {
      //print('ApiService: getDirectory - Generated path: $path');
    }

    final response = await _getRequest(path);

    late DirectoryDataResponse dataDirectory;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataDirectory = DirectoryDataResponse.fromJson(data);
      } else {
        throw ('Результат отсутствует в ответе');
      }
    } else if (response.statusCode == 404) {
      throw ('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw ('Внутренняя ошибка сервера');
    } else {
      throw ('Ошибка при получении данных!');
    }

    if (kDebugMode) {
      ////print('getAll directory!');
    }

    return dataDirectory;
  }

  Future<MainFieldResponse> getMainFields(int directoryId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/directory/getMainFields/$directoryId');
    if (kDebugMode) {
      //print('ApiService: getMainFields - Generated path: $path');
    }

    ////print('Вызов getMainFields для directoryId: $directoryId');
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////print('Ответ getMainFields для directoryId $directoryId: $data');
      if (data['result'] != null) {
        return MainFieldResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw Exception('Внутренняя ошибка сервера');
    } else {
      throw Exception('Ошибка при получении данных справочника!');
    }
  }

  Future<void> linkDirectory({
    required int directoryId,
    required String modelType,
    required String organizationId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/directoryLink');
    if (kDebugMode) {
      //print('ApiService: linkDirectory - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        'directory_id': directoryId,
        'model_type': modelType,
        'organization_id': organizationId,
      },
    );

    if (response.statusCode != 200) {
      throw ('Ошибка при связывании справочника: ${response.statusCode}');
    }

    if (kDebugMode) {
      ////print('Directory linked successfully!');
    }
  }

  Future<DirectoryLinkResponse> getTaskDirectoryLinks() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/directoryLink/task');
    if (kDebugMode) {
      //print('ApiService: getTaskDirectoryLinks - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        return DirectoryLinkResponse.fromJson(data);
      } else {
        throw Exception('Данные отсутствуют в ответе');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw Exception('Внутренняя ошибка сервера');
    } else {
      throw Exception('Ошибка при получении связанных справочников!');
    }
  }

// Для лидов
  Future<DirectoryLinkResponse> getLeadDirectoryLinks() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/directoryLink/lead');
    if (kDebugMode) {
      //print('ApiService: getLeadDirectoryLinks - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        return DirectoryLinkResponse.fromJson(data);
      } else {
        throw Exception('Данные отсутствуют в ответе');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw Exception('Внутренняя ошибка сервера');
    } else {
      throw Exception('Ошибка при получении связанных справочников!');
    }
  }

// Для сделок
  Future<DirectoryLinkResponse> getDealDirectoryLinks() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/directoryLink/deal');
    if (kDebugMode) {
      //print('ApiService: getDealDirectoryLinks - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        return DirectoryLinkResponse.fromJson(data);
      } else {
        throw Exception('Данные отсутствуют в ответе');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw Exception('Внутренняя ошибка сервера');
    } else {
      throw Exception('Ошибка при получении связанных справочников!');
    }
  }

//_________________________________ START_____API_SCREEN__DASHBOARD____________________________________________//

  /// Получение данных графика для дашборда
  Future<List<ChartData>> getLeadChart() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/lead-chart');
    if (kDebugMode) {
      //print('ApiService: getLeadChart - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data.map((json) => ChartData.fromJson(json)).toList();
      } else {
        throw ('Нет данных графика в ответе "Клиенты"');
      }
    } else {
      throw ('Ошибка загрузки данных график клиента!');
    }
  }

  Future<LeadConversion> getLeadConversionData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/leadConversion-chart');
    if (kDebugMode) {
      //print('ApiService: getLeadConversionData - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final conversion = LeadConversion.fromJson(data);
        return conversion;
      } else {
        throw ('Нет данных графика в ответе "Конверсия лидов');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('');
    }
  }

// Метод для получения графика Сделки
  Future<DealStatsResponse> getDealStatsData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/dealStats');
    if (kDebugMode) {
      //print('ApiService: getDealStatsData - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DealStatsResponse.fromJson(jsonData);
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера!');
      } else {
        throw Exception('Ошибка загрузки данных!');
      }
    } catch (e) {
      ////print('Ошибка запроса!');
      throw ('');
    }
  }

// Метод для получения графика Задачи
  Future<TaskChart> getTaskChartData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/task-chart');
    if (kDebugMode) {
      //print('ApiService: getTaskChartData - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['result'] != null && jsonMap['result']['data'] != null) {
          final taskChart = TaskChart.fromJson(jsonMap);
          return taskChart;
        } else {
          throw ('Нет данных графика в ответе "Задачи');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера!');
      } else {
        throw ('Ошибка загрузки данных графика!');
      }
    } catch (e) {
      throw ('Ошибка получения данных!');
    }
  }

// Метод для получения графика Скорость обработки
  Future<ProcessSpeed> getProcessSpeedData() async {
    final enteredDomainMap = await ApiService().getEnteredDomain();
    // Извлекаем значения из Map
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/lead-process-speed');
    if (kDebugMode) {
      //print('ApiService: getProcessSpeedData - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final speed = ProcessSpeed.fromJson(data);
        return speed;
      } else {
        throw ('Нет данных графика в ответе "Скорость обработки"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Ошибка загрузки данных графика Скорость обработки');
    }
  }

  Future<List<UserTaskCompletion>> getUsersChartData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/users-chart');
    if (kDebugMode) {
      //print('ApiService: getUsersChartData - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['result'] != null) {
        final List<dynamic> resultList = data['result'];
        return resultList
            .map((item) => UserTaskCompletion.fromJson(item))
            .toList();
      } else {
        throw ('Нет данных графика в ответе "Выполнение целей"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Ошибка загрузки данных графика Выполнение целей!');
    }
  }

//_________________________________ END_____API_SCREEN__DASHBOARD____________________________________________//

//_________________________________ START_____API_SCREEN__DASHBOARD_Manager____________________________________________//

// Метод для получения графика Сделки
  Future<DealStatsResponseManager> getDealStatsManagerData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/dealStats/for-manager');
    if (kDebugMode) {
      //print('ApiService: getDealStatsManagerData - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DealStatsResponseManager.fromJson(jsonData);
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера!');
      } else {
        throw Exception('Ошибка загрузки данных!');
      }
    } catch (e) {
      ////print('Ошибка запроса!');
      throw ('');
    }
  }

  /// Получение данных графика для дашборда
  Future<List<ChartDataManager>> getLeadChartManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/lead-chart/for-manager');
    if (kDebugMode) {
      //print('ApiService: getLeadChartManager - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data.map((json) => ChartDataManager.fromJson(json)).toList();
      } else {
        throw ('Нет данных графика в ответе "Клиенты"');
      }
    } else {
      throw ('Ошибка загрузки данных график клиента!');
    }
  }

  Future<LeadConversionManager> getLeadConversionDataManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/dashboard/leadConversion-chart/for-manager');
    if (kDebugMode) {
      //print('ApiService: getLeadConversionDataManager - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final conversion = LeadConversionManager.fromJson(data);
        return conversion;
      } else {
        throw ('Нет данных графика в ответе "Конверсия лидов');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('');
    }
  }

  Future<ProcessSpeedManager> getProcessSpeedDataManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/dashboard/lead-process-speed/for/manager');
    if (kDebugMode) {
      //print('ApiService: getProcessSpeedDataManager - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final speed = ProcessSpeedManager.fromJson(data);
        return speed;
      } else {
        throw ('Нет данных графика в ответе "Скорость обработки"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Ошибка загрузки данных графика Скорость обработки');
    }
  }

// Метод для получения графика Задачи
  Future<TaskChartManager> getTaskChartDataManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/task-chart/for-manager');
    if (kDebugMode) {
      //print('ApiService: getTaskChartDataManager - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['result'] != null && jsonMap['result']['data'] != null) {
          final taskChart = TaskChartManager.fromJson(jsonMap);
          return taskChart;
        } else {
          throw ('Нет данных графика в ответе "Задачи');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера!');
      } else {
        throw ('Ошибка загрузки данных графика!');
      }
    } catch (e) {
      throw ('Ошибка получения данных!');
    }
  }

// API Service
  Future<UserTaskCompletionManager> getUserStatsManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/completed-task-chart');
    if (kDebugMode) {
      //print('ApiService: getUserStatsManager - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['result'] != null) {
        return UserTaskCompletionManager.fromJson(data);
      } else {
        throw ('Нет данных графика в ответе');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Неизвестная ошибка');
    }
  }

//_________________________________ END_____API_SCREEN__DASHBOARD__Manager__________________________________________//

//_________________________________ START_____API_SCREEN__CHATS____________________________________________//

  Future<PaginationDTO<Chats>> getAllChats(
    String endPoint, [
    int page = 1,
    String? search,
    int? salesFunnelId,
    Map<String, dynamic>? filters,
  ]) async {
    final token = await getToken();
    String path = '/v2/chat/getMyChats/$endPoint?page=$page';

    //print('ApiService.getAllChats: Initial path: $path');
    //print('ApiService.getAllChats: Parameters - page: $page, search: $search, salesFunnelId: $salesFunnelId, filters: $filters');

    path = await _appendQueryParams(path);

    if (search != null && search.isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search)}';
      //print('ApiService.getAllChats: Added search: $search');
    }

    if (salesFunnelId != null && endPoint == 'lead') {
      path += '&funnel_id=$salesFunnelId';
      //print('ApiService.getAllChats: Added funnel_id: $salesFunnelId');
    }

    if (filters != null) {
      //print('ApiService.getAllChats: Processing filters: $filters');

      if (endPoint == 'lead') {
        // Менеджеры
        if (filters['managers'] != null &&
            (filters['managers'] as List).isNotEmpty) {
          List<int> managerIds =
              (filters['managers'] as List).map((m) => m.id as int).toList();
          for (int managerId in managerIds) {
            path += '&managers[]=$managerId';
          }
          //print('ApiService.getAllChats: Added managers: $managerIds');
        }

        // Регионы
        if (filters['regions'] != null &&
            (filters['regions'] as List).isNotEmpty) {
          List<int> regionIds =
              (filters['regions'] as List).map((r) => r.id as int).toList();
          for (int regionId in regionIds) {
            path += '&regions[]=$regionId';
          }
          //print('ApiService.getAllChats: Added regions: $regionIds');
        }

        // Источники
        if (filters['sources'] != null &&
            (filters['sources'] as List).isNotEmpty) {
          List<int> sourceIds =
              (filters['sources'] as List).map((s) => s.id as int).toList();
          for (int sourceId in sourceIds) {
            path += '&sources[]=$sourceId';
          }
          //print('ApiService.getAllChats: Added sources: $sourceIds');
        }

        // Статусы
        if (filters['statuses'] != null &&
            (filters['statuses'] as List).isNotEmpty) {
          List<String> statusIds = (filters['statuses'] as List).cast<String>();
          for (String statusId in statusIds) {
            path += '&leadStatus[]=$statusId';
          }
          //print('ApiService.getAllChats: Added statuses: $statusIds');
        }

        // Даты
        if (filters['fromDate'] != null) {
          path += '&from_date=${filters['fromDate'].toIso8601String()}';
          //print('ApiService.getAllChats: Added from_date: ${filters['fromDate']}');
        }
        if (filters['toDate'] != null) {
          path += '&to_date=${filters['toDate'].toIso8601String()}';
          //print('ApiService.getAllChats: Added to_date: ${filters['toDate']}');
        }

        // Флаги
        if (filters['hasSuccessDeals'] == true) {
          path += '&has_success_deals=1';
          //print('ApiService.getAllChats: Added has_success_deals=1');
        }
        if (filters['hasInProgressDeals'] == true) {
          path += '&has_in_progress_deals=1';
          //print('ApiService.getAllChats: Added has_in_progress_deals=1');
        }
        if (filters['hasFailureDeals'] == true) {
          path += '&has_failure_deals=1';
          //print('ApiService.getAllChats: Added has_failure_deals=1');
        }
        if (filters['hasNotices'] == true) {
          path += '&has_notices=1';
          //print('ApiService.getAllChats: Added has_notices=1');
        }
        if (filters['hasContact'] == true) {
          path += '&has_contact=1';
          //print('ApiService.getAllChats: Added has_contact=1');
        }
        if (filters['hasChat'] == true) {
          path += '&has_chat=1';
          //print('ApiService.getAllChats: Added has_chat=1');
        }
        if (filters['hasNoReplies'] == true) {
          path += '&has_no_replies=1';
          //print('ApiService.getAllChats: Added has_no_replies=1');
        }
        if (filters['hasUnreadMessages'] == true) {
          path += '&unread_only=1';
          //print('ApiService.getAllChats: Added has_unread_messages=1');
        }
        if (filters['hasDeal'] == true) {
          path += '&has_deal=1';
          //print('ApiService.getAllChats: Added has_deal=1');
        }
        if (filters['unreadOnly'] == true) {
          path += '&unread_only=1';
          //print('ApiService.getAllChats: Added unread_only=1');
        }
        if (filters['daysWithoutActivity'] != null &&
            filters['daysWithoutActivity'] > 0) {
          path += '&days_without_activity=${filters['daysWithoutActivity']}';
          //print('ApiService.getAllChats: Added days_without_activity: ${filters['daysWithoutActivity']}');
        }
        if (filters['directory_values'] != null &&
            (filters['directory_values'] as List).isNotEmpty) {
          List<Map<String, dynamic>> directoryValues =
              filters['directory_values'] as List<Map<String, dynamic>>;
          for (var value in directoryValues) {
            path +=
                '&directory_values[${value['directory_id']}]=${value['entry_id']}';
          }
          //print('ApiService.getAllChats: Added directory_values: $directoryValues');
        }
      } else if (endPoint == 'task') {
        // Обработка фильтров для task (без изменений)
        if (filters['task_number'] != null &&
            filters['task_number'].isNotEmpty) {
          path += '&task_number=${Uri.encodeComponent(filters['task_number'])}';
          //print('ApiService.getAllChats: Added task_number: ${filters['task_number']}');
        }
        if (filters['department_id'] != null) {
          path += '&department_id=${filters['department_id']}';
          //print('ApiService.getAllChats: Added department_id: ${filters['department_id']}');
        }
        if (filters['task_created_from'] != null) {
          path += '&task_created_from=${filters['task_created_from']}';
          //print('ApiService.getAllChats: Added task_created_from: ${filters['task_created_from']}');
        }
        if (filters['task_created_to'] != null) {
          path += '&task_created_to=${filters['task_created_to']}';
          //print('ApiService.getAllChats: Added task_created_to: ${filters['task_created_to']}');
        }
        if (filters['deadline_from'] != null) {
          path += '&deadline_from=${filters['deadline_from']}';
          //print('ApiService.getAllChats: Added deadline_from: ${filters['deadline_from']}');
        }
        if (filters['deadline_to'] != null) {
          path += '&deadline_to=${filters['deadline_to']}';
          //print('ApiService.getAllChats: Added deadline_to: ${filters['deadline_to']}');
        }
        if (filters['executor_ids'] != null &&
            (filters['executor_ids'] as List).isNotEmpty) {
          List<String> executorIds = (filters['executor_ids'] as List)
              .map((id) => id.toString())
              .toList();
          for (String executorId in executorIds) {
            path += '&executor_ids[]=$executorId';
          }
          //print('ApiService.getAllChats: Added executor_ids: $executorIds');
        }
        if (filters['author_ids'] != null &&
            (filters['author_ids'] as List).isNotEmpty) {
          List<int> authorIds = (filters['author_ids'] as List).cast<int>();
          for (int authorId in authorIds) {
            path += '&author_ids[]=$authorId';
          }
          //print('ApiService.getAllChats: Added author_ids: $authorIds');
        }
        if (filters['project_ids'] != null &&
            (filters['project_ids'] as List).isNotEmpty) {
          List<int> projectIds = (filters['project_ids'] as List).cast<int>();
          for (int projectId in projectIds) {
            path += '&project_ids[]=$projectId';
          }
          //print('ApiService.getAllChats: Added project_ids: $projectIds');
        }
        if (filters['task_status_ids'] != null &&
            (filters['task_status_ids'] as List).isNotEmpty) {
          List<int> taskStatusIds =
              (filters['task_status_ids'] as List).cast<int>();
          for (int statusId in taskStatusIds) {
            path += '&task_status_ids[]=$statusId';
          }
          //print('ApiService.getAllChats: Added task_status_ids: $taskStatusIds');
        }
        if (filters['unread_only'] == true) {
          path += '&unread_only=1';
          //print('ApiService.getAllChats: Added unread_only=1');
        }
      }
    }

    final fullUrl = '$baseUrl$path';
    //print('ApiService.getAllChats: Requesting URL: $fullUrl');

    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'FlutterApp/1.0',
          'Cache-Control': 'no-cache',
        },
      );

      //print('ApiService.getAllChats: Response status: ${response.statusCode}');
      //print('ApiService.getAllChats: Response headers: ${response.headers}');

      if (response.statusCode == 302) {
        //print('ApiService.getAllChats: Got 302 redirect to: ${response.headers['location']}');
        throw Exception('Получен редирект 302. Проверьте URL и авторизацию.');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          final pagination = PaginationDTO<Chats>.fromJson(data['result'], (e) {
            return Chats.fromJson(e);
          });
          //print('ApiService.getAllChats: Received ${pagination.data.length} chats for page $page');
          //print('ApiService.getAllChats: Chat IDs: ${pagination.data.map((chat) => chat.id).toList()}');
          return pagination;
        } else {
          //print('ApiService.getAllChats: No result found in response');
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        //print('ApiService.getAllChats: Error ${response.statusCode}: ${response.body}');
        throw Exception('Ошибка ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      //print('ApiService.getAllChats: Exception caught: $e');
      rethrow;
    }
  }
Future<String> getDynamicBaseUrlFixed() async {
  // Сначала проверяем кешированное значение
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? cachedBaseUrl = prefs.getString('cached_base_url');

  if (cachedBaseUrl != null && cachedBaseUrl.isNotEmpty && cachedBaseUrl != 'null') {
    if (kDebugMode) {
      print('ApiService: Using cached baseUrl: $cachedBaseUrl');
    }
    return cachedBaseUrl;
  }

  // Если кеша нет, используем старую логику
  return await getDynamicBaseUrl();
}
  Future<ChatsGetId> getChatById(int chatId) async {
    final token = await getToken();
    String path = '/v2/chat/$chatId';
    path = await _appendQueryParams(path);

    if (kDebugMode) {
      //print('ApiService.getChatById: Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'FlutterApp/1.0',
        'Cache-Control': 'no-cache',
      },
    );

    if (kDebugMode) {
      //print('ApiService.getChatById: Response status: ${response.statusCode}');
      //print('ApiService.getChatById: Response body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return ChatsGetId.fromJson(data['result']);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }

  Future<String> sendMessages(List<int> messageIds) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/chat/read');
    if (kDebugMode) {
      //print('ApiService: sendMessages - Generated path: $path');
    }

    // Prepare the body
    final body = json.encode({'message_ids': messageIds});

    // Make the POST request
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['message'] ?? 'Success';
    } else {
      throw Exception('Error ${response.statusCode}!');
    }
  }

// Метод для получения сообщений по chatId
Future<List<Message>> getMessages(
  int chatId, {
  String? search,
}) async {
  try {
    final token = await getToken();

    // Проверяем инициализацию baseUrl
    if (baseUrl == null || baseUrl!.isEmpty || baseUrl == 'null') {
      await initialize();
      if (baseUrl == null || baseUrl!.isEmpty || baseUrl == 'null') {
        throw Exception('Base URL не может быть инициализирован');
      }
    }

    String path = '/v2/chat/getMessages/$chatId';
    path = await _appendQueryParams(path);

    if (search != null && search.isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search)}';
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        final List<dynamic> messagesList = data['result'] as List<dynamic>;
        return messagesList.map((msgData) {
          try {
            return Message.fromJson(msgData as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Error parsing message: $e, data: $msgData');
            // Возвращаем пустое сообщение с базовыми полями
            return Message(
              id: msgData['id'] ?? -1,
              text: msgData['text']?.toString() ?? 'Ошибка загрузки сообщения',
              type: msgData['type']?.toString() ?? 'text',
              createMessateTime: msgData['created_at']?.toString() ?? DateTime.now().toIso8601String(),
              isMyMessage: false,
              senderName: msgData['sender']?['name']?.toString() ?? 'Неизвестный отправитель',
            );
          }
        }).toList();
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    debugPrint('ApiService.getMessages error: $e');
    rethrow;
  }
}

  Future<void> closeChatSocket(int chatId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/clearCache/$chatId');
    if (kDebugMode) {
      //print('ApiService: closeChatSocket - Generated path: $path');
    }

    final response = await _postRequest(path, {});

    if (response.statusCode != 200) {
      throw Exception('close sokcet!');
    }
  }

  Future<IntegrationForLead> getIntegrationForLead(int chatId) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/get-integration/$chatId');
    if (kDebugMode) {
      //print('ApiService: getIntegrationForLead - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // debug//print('API response: $data'); // Лог для отладки
      if (data['result'] != null) {
        return IntegrationForLead.fromJson(data['result']);
      } else {
        // debug//print('Integration not found in response: $data');
        throw Exception('Интеграция не найдена в ответе');
      }
    } else {
      // debug//print('API error: ${response.statusCode}, body: ${response.body}');
      throw Exception(
          'Ошибка ${response.statusCode}: Не удалось получить интеграцию');
    }
  }

// Метод для отправки текстового сообщения
  Future<void> sendMessage(int chatId, String message,
      {String? replyMessageId}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendMessage/$chatId');
    if (kDebugMode) {
      //print('ApiService: sendMessage - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'message': message,
      if (replyMessageId != null) 'forwarded_message_id': replyMessageId,
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки сообщения!');
    }
  }

  Future<void> pinMessage(String messageId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/pinMessage/$messageId');
    if (kDebugMode) {
      //print('ApiService: pinMessage - Generated path: $path');
    }

    final response = await _postRequest(path, {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка закрепления сообщения!');
    }
  }

  Future<void> unpinMessage(String messageId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/pinMessage/$messageId');
    if (kDebugMode) {
      //print('ApiService: unpinMessage - Generated path: $path');
    }

    final response = await _postRequest(path, {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка закрепления сообщения!');
    }
  }

  Future<void> editMessage(String messageId, String message) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/editMessage/$messageId');
    if (kDebugMode) {
      //print('ApiService: editMessage - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'message': message,
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка изменения сообщения!');
    }
  }

// Метод для отправки audio file
  Future<void> sendChatAudioFile(int chatId, File audio) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendVoice/$chatId');
    if (kDebugMode) {
      //print('ApiService: sendChatAudioFile - Generated path: $path');
    }

    String requestUrl = '$baseUrl$path';

    Dio dio = Dio();
    try {
      final voice = await MultipartFile.fromFile(audio.path,
          contentType: MediaType('audio', 'm4a'));
      FormData formData = FormData.fromMap({'voice': voice});

      var response = await dio.post(
        requestUrl,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );
      if (kDebugMode) {
        ////print('response.statusCode!');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          ////print('Audio message sent successfully!');
        }
      } else {
        if (kDebugMode) {
          ////print('Error sending audio message: ${response.data}');
        }
        throw Exception('Error sending audio message: ${response.data}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        ////print('Exception caught!');
      }
      if (kDebugMode) {
        ////print(e.response?.data);
      }
      throw Exception('Failed to send audio message due to an exception!');
    }
  }

// Метод для отправки audio file
  Future<void> sendChatFile(int chatId, String pathFile) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendFile/$chatId');
    if (kDebugMode) {
      //print('ApiService: sendChatFile - Generated path: $path');
    }

    String requestUrl = '$baseUrl$path';

    Dio dio = Dio();
    try {
      FormData formData =
          FormData.fromMap({'file': await MultipartFile.fromFile(pathFile)});

      var response = await dio.post(
        requestUrl,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            'Device': 'mobile'
          },
          contentType: 'multipart/form-data',
        ),
      );
      if (kDebugMode) {
        ////print('response.statusCode!');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          ////print('Audio message sent successfully!');
        }
      } else {
        if (kDebugMode) {
          ////print('Error sending audio message: ${response.data}');
        }
        throw Exception('Error sending audio message: ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        ////print('Exception caught!');
      }
      throw Exception('Failed to send audio message due to an exception!');
    }
  }

// Метод для отправки файла
  Future<void> sendFile(int chatId, String filePath) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendFile/$chatId');
    if (kDebugMode) {
      //print('ApiService: sendFile - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'file_path': filePath,
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки файла!');
    }
  }

// Метод для отправки голосового сообщения
  Future<void> sendVoice(int chatId, String voicePath) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendVoice/$chatId');
    if (kDebugMode) {
      //print('ApiService: sendVoice - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'voice_path': voicePath,
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки голосового сообщения!');
    }
  }

// //Метод для передачи всех iD-сообщениях чата в сервер
//   Future<void> readChatMessages(int chatId, List<int> messageIds) async {
//     final token = await getToken();
//     final organizationId = await getSelectedOrganization();

//     final url = Uri.parse('$baseUrl/chat/read');

//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode({
//           'chat_id': chatId,
//           'organization_id': organizationId,
//           'messages': messageIds,
//         }),
//       );

//       if (response.statusCode == 200) {
//         ////print('Messages marked as read');
//       } else {
//         ////print('Error marking messages as read!');
//       }
//     } catch (e) {
//       ////print('Exception when marking messages as read!');
//     }
//   }

  // Метод для удаления чата
  Future<Map<String, dynamic>> deleteChat(int chatId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/v2/chat/$chatId');
      if (kDebugMode) {
        //print('ApiService: deleteChat - Generated path: $path');
      }

      final response = await _deleteRequest(path);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return {
          'result': responseBody['result'],
          'errors': responseBody['errors'],
        };
      } else if (response.statusCode == 400) {
        // Ошибка запроса
        throw Exception('Ошибка запроса: Неверные данные');
      } else if (response.statusCode == 401) {
        // Ошибка авторизации
        throw Exception('Ошибка авторизации: Некорректные учетные данные');
      } else if (response.statusCode == 403) {
        // Ошибка доступа
        throw Exception('Ошибка доступа: Недостаточно прав');
      } else if (response.statusCode == 404) {
        // Чат не найден
        throw Exception('Ошибка: Чат не найден');
      } else if (response.statusCode >= 500 && response.statusCode < 600) {
        // Ошибка сервера
        throw Exception('Ошибка сервера: Попробуйте позже');
      } else {
        // Обработка других ошибок
        throw Exception('Неизвестная ошибка!');
      }
    } catch (e) {
      // Обработка ошибок сети или других непредвиденных исключений
      throw Exception('Не удалось выполнить запрос!');
    }
  }

// get all users
  Future<UsersDataResponse> getAllUser() async {
    final token = await getToken();
    final path = await _appendQueryParams('/department/get/users');
    if (kDebugMode) {
      //print('ApiService: getAllUser - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //print('ApiService: getAllUser - Response: $data');
      }
      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }

    return dataUser;
  }

  Future<UsersDataResponse> getAnotherUsers() async {
    final token = await getToken(); // Получаем токен перед запросом
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/user/getAnotherUsers/');
    if (kDebugMode) {
      //print('ApiService: getAnotherUsers - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // ////print('Статус ответа!');
    }
    if (kDebugMode) {
      // ////print('getAll user!');
    }

    return dataUser;
  }

// addUserToGroup
  Future<UsersDataResponse> getUsersNotInChat(String chatId) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/user/users-not-in-chat/$chatId');
    if (kDebugMode) {
      //print('ApiService: getUsersNotInChat - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // ////print('Статус ответа!');
    }
    if (kDebugMode) {
      // ////print('getUsersNotInChat!');
    }

    return dataUser;
  }

//Список юзеров Корпорт чата  для созд с польз
  Future<UsersDataResponse> getUsersWihtoutCorporateChat() async {
    final token = await getToken(); // Получаем токен перед запросом
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/chat/users/without-corporate-chat/');
    if (kDebugMode) {
      //print('ApiService: getUsersWihtoutCorporateChat - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    ////print(
    // '----------------------------------------------------------------------');
    ////print(
    // '-------------------------------getUsersWihtoutCorporateChat---------------------------------------');
    ////print(response);

    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // ////print('Статус ответа!');
    }
    if (kDebugMode) {
      // ////print('getAll user!');
    }

    return dataUser;
  }

// create new client
  Future<Map<String, dynamic>> createNewClient(String userID) async {
    try {
      // Инициализируем baseUrl, если он ещё не установлен
      if (baseUrl == null || baseUrl!.isEmpty) {
        await initialize();
        if (baseUrl == null || baseUrl!.isEmpty) {
          throw Exception(
              'baseUrl is not defined after initialization. Please ensure domain is set.');
        }
      }

      final token = await getToken();
      final path = await _appendQueryParams('/chat/createChat/$userID');

      // Проверка organization_id
      final organizationId = await getSelectedOrganization();
      if (organizationId == null) {
        if (kDebugMode) {
          print(
              'ApiService: createNewClient - Using fallback organization_id=1');
        }
      }

      if (kDebugMode) {
        print('ApiService: createNewClient - Base URL: $baseUrl');
        print('ApiService: createNewClient - Generated path: $path');
        print('ApiService: createNewClient - Token: $token');
        print('ApiService: createNewClient - Organization ID: $organizationId');
      }

      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'user_id': userID,
          'organization_id':
              organizationId, // Используем organizationId напрямую, так как есть fallback в getSelectedOrganization
        }),
      );

      if (kDebugMode) {
        print(
            'ApiService: createNewClient - Status code: ${response.statusCode}');
        print('ApiService: createNewClient - Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        var chatId = jsonResponse['result']['id'];
        return {'chatId': chatId};
      } else {
        throw Exception(
            'Failed to create chat: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiService: createNewClient - Error: $e');
      }
      throw Exception('Failed to create chat: $e');
    }
  }

// Метод для создания Групповго чата
  Future<Map<String, dynamic>> createGroupChat({
    required String name,
    List<int>? userId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'users': userId?.map((id) => {'id': id}).toList() ?? [],
      };

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/chat/createGroup');
      if (kDebugMode) {
        //print('ApiService: createGroupChat - Generated path: $path');
      }

      final response = await _postRequest(
        path,
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'group_chat_created_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        return {
          'success': false,
          'message': 'error_validation',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        return {
          'success': false,
          'message': 'error_create_group_chat',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_create_group_chat',
      };
    }
  }

// Метод для добавления пользователя в групповой чат
  Future<Map<String, dynamic>> addUserToGroup({
    required int chatId,
    int? userId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'chatId': chatId,
        'userId': userId,
      };

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path =
          await _appendQueryParams('/chat/addUserToGroup/$chatId/$userId');
      if (kDebugMode) {
        //print('ApiService: addUserToGroup - Generated path: $path');
      }

      final response = await _postRequest(
        path,
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Участник успешно добавлен.',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'Ошибка на сервере. Попробуйте позже.',
        };
      } else {
        return {
          'success': false,
          'message': 'Ошибка добавления участника!',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при добавление участника !',
      };
    }
  }

// Метод для удаления пользователя из группового чата
  Future<Map<String, dynamic>> deleteUserFromGroup({
    required int chatId,
    int? userId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'chatId': chatId,
        'userId': userId,
      };

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path =
          await _appendQueryParams('/chat/removeUserFromGroup/$chatId/$userId');
      if (kDebugMode) {
        //print('ApiService: deleteUserFromGroup - Generated path: $path');
      }

      final response = await _postRequest(
        path,
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Участник успешно добавлен.',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'Ошибка на сервере. Попробуйте позже.',
        };
      } else {
        return {
          'success': false,
          'message': 'Ошибка добавления участника!',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при добавление участника !',
      };
    }
  }

// Метод для удаления сообщения
  Future<void> DeleteMessage({int? messageId}) async {
    if (messageId == null) {
      throw Exception('MessageId не может быть null');
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/delete-message/$messageId');
    if (kDebugMode) {
      //print('ApiService: DeleteMessage - Generated path: $path');
    }

    ////print('Sending DELETE request to API with path: $path');

    // Используем _deleteRequest для отправки DELETE-запроса
    final response = await _deleteRequest(path);

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления уведомлений!');
    }

    final data = json.decode(response.body);
    if (data['result'] == 'deleted') {
      return;
    } else {
      throw Exception('Ошибка удаления уведомления');
    }
  }

  Future<TemplateResponse> getTemplates() async {
    final token = await getToken();
    final path = await _appendQueryParams('/v2/chat/templates');
    if (kDebugMode) {
      //print('ApiService: getTemplates - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return TemplateResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при загрузке шаблонов: ${response.statusCode}');
    }
  }

//_________________________________ END_____API_SCREEN__CHATS____________________________________________//

//_________________________________ START_____API_SCREEN__PROFILE_CHAT____________________________________________//

  Future<ChatProfile> getChatProfile(int chatId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/lead/getByChat/$chatId');
      if (kDebugMode) {
        //print('ApiService: getChatProfile - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        if (decodedJson['result'] != null) {
          return ChatProfile.fromJson(decodedJson['result']);
        } else {
          throw Exception('Данные профиля не найдены');
        }
      } else if (response.statusCode == 404) {
        throw ('Такого Лида не существует');
      } else {
        ////print('Ошибка загрузки профиля чата!');
        throw Exception('${response.statusCode}');
      }
    } catch (e) {
      ////print('Ошибка в getChatProfile!');
      throw ('Ошибка загрузки профиля чата!');
    }
  }

  Future<TaskProfile> getTaskProfile(int chatId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task/getByChat/$chatId');
      if (kDebugMode) {
        //print('ApiService: getTaskProfile - Generated path: $path');
      }

      ////print('Organization ID: $organizationId'); // Добавим логирование

      final response = await _getRequest(path);

      ////print('Response status code!'); // Логируем статус ответа
      ////print('Response body!'); // Логируем тело ответа

      if (response.statusCode == 200) {
        try {
          final dynamic decodedJson = json.decode(response.body);
          ////print(
          // 'Decoded JSON type: ${decodedJson.runtimeType}'); // Логируем тип декодированного JSON
          ////print('Decoded JSON: $decodedJson'); // Отладочный вывод

          if (decodedJson is Map<String, dynamic>) {
            if (decodedJson['result'] != null) {
              ////print(
              // 'Result type: ${decodedJson['result'].runtimeType}'); // Логируем тип результата
              return TaskProfile.fromJson(decodedJson['result']);
            } else {
              ////print('Result is null');
              throw Exception('Данные задачи не найдены');
            }
          } else {
            ////print('Decoded JSON is not a Map: ${decodedJson.runtimeType}');
            throw Exception('Неверный формат ответа');
          }
        } catch (parseError) {
          ////print('Ошибка парсинга JSON: $parseError');
          throw Exception('Ошибка парсинга ответа: $parseError');
        }
      } else {
        ////print('Ошибка загрузки задачи!');
        throw Exception('Ошибка загрузки задачи!');
      }
    } catch (e) {
      ////print('Полная ошибка в getTaskProfile!');
      ////print('Трассировка стека: ${StackTrace.current}');
      throw Exception('Ошибка загрузки задачи!');
    }
  } // Упрощённый метод для получения интеграции лида (теперь не нужен отдельный класс IntegrationForLead)

// Новый метод для получения чата по ID с интеграцией
 Future<ChatsGetId> getChatByIdWithIntegration(int chatId) async {
  try {
    final token = await getToken();

    if (baseUrl == null || baseUrl!.isEmpty || baseUrl == 'null') {
      await initialize();
    }

    String path = '/v2/chat/$chatId';
    path = await _appendQueryParams(path);

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'FlutterApp/1.0',
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return ChatsGetId.fromJson(data['result']);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    debugPrint('getChatByIdWithIntegration error: $e');
    rethrow;
  }
}

  Future<String> readMessages(int chatId, int messageId) async {
    final token = await getToken();
    final path = await _appendQueryParams('/v2/chat/readMessages/$chatId');
    // Лог для отладки пути и параметров
    if (kDebugMode) {
      //print('ApiService: readMessages - Путь: $path, messageId: $messageId, token: $token');
    }

    final body = json.encode({'up_to_message_id': messageId});

    try {
      // Добавлен таймаут в 10 секунд для запроса
      final response = await http
          .post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'FlutterApp/1.0',
          'Cache-Control': 'no-cache',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Запрос readMessages превысил время ожидания');
      });

      // Лог для ответа сервера
      if (kDebugMode) {
        //print('ApiService.readMessages: Код ответа: ${response.statusCode}');
        //print('ApiService.readMessages: Тело ответа: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] ?? 'Сообщения успешно помечены как прочитанные';
      } else {
        throw Exception('Ошибка ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Лог для всех ошибок, включая TimeoutException
      if (kDebugMode) {
        //print('ApiService.readMessages: Поймано исключение: $e');
      }
      rethrow;
    }
  }
//_________________________________ END_____API_SCREEN__PROFILE_CHAT____________________________________________//

//_________________________________ START_____API_SCREEN__PROFILE____________________________________________//

// Метод для получения Организации
  Future<List<Organization>> getOrganization() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/organization');
    if (kDebugMode) {
      //print('ApiService: getOrganization - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////print('Тело ответа: $data'); // Для отладки

      if (data['result'] != null && data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((organization) => Organization.fromJson(organization))
            .toList();
      } else {
        throw Exception('Организация не найдено');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

// Сохранение выбранной организации
// Исправленный метод для получения организации с fallback
Future<String?> getSelectedOrganization() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? organizationId = prefs.getString('selectedOrganization');

    debugPrint('ApiService: getSelectedOrganization - orgId: $organizationId');

    // Возвращаем null если организация не найдена или содержит 'null'
    if (organizationId == null || organizationId.isEmpty || organizationId == 'null') {
      debugPrint('ApiService: No valid organization found, using fallback');
      return '1'; // Дефолтная организация
    }

    return organizationId;
  } catch (e) {
    debugPrint('getSelectedOrganization error: $e');
    return '1'; // Fallback значение
  }
}

Future<void> saveSelectedOrganization(String organizationId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('selectedOrganization', organizationId);
  if (kDebugMode) {
    print('ApiService: saveSelectedOrganization - Saved: $organizationId');
  }
}

Future<void> _removeOrganizationId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('selectedOrganization');
}

  Future<void> logoutAccount() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/logout');
    if (kDebugMode) {
      //print('ApiService: logoutAccount - Generated path: $path');
    }

    final response = await _postRequest(path, {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка logout аккаунта!');
    }
  }

// Существующий метод для получения выбранной воронки
  Future<String?> getSelectedSalesFunnel() async {
    //print('ApiService: Getting selected sales funnel from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final funnelId = prefs.getString('selected_sales_funnel');
    //print('ApiService: Retrieved selected funnel ID: $funnelId');
    return funnelId;
  }

// Существующий метод для сохранения выбранной воронки
  Future<void> saveSelectedSalesFunnel(String funnelId) async {
    //print('ApiService: Saving selected sales funnel ID: $funnelId');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_sales_funnel', funnelId);
    //print('ApiService: Selected sales funnel ID saved');
  }

  Future<void> saveSelectedDealSalesFunnel(String funnelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deal_selected_sales_funnel', funnelId);
    //print('ApiService: Saved deal funnel ID $funnelId to SharedPreferences');
  }

  Future<String?> getSelectedDealSalesFunnel() async {
    final prefs = await SharedPreferences.getInstance();
    final funnelId = prefs.getString('deal_selected_sales_funnel');
    //print('ApiService: Retrieved deal funnel ID $funnelId from SharedPreferences');
    return funnelId;
  }

  Future<void> saveSelectedEventSalesFunnel(String funnelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('event_selected_sales_funnel', funnelId);
    //print('ApiService: Saved event funnel ID $funnelId to SharedPreferences');
  }

  Future<String?> getSelectedEventSalesFunnel() async {
    final prefs = await SharedPreferences.getInstance();
    final funnelId = prefs.getString('event_selected_sales_funnel');
    //print('ApiService: Retrieved event funnel ID $funnelId from SharedPreferences');
    return funnelId;
  }

  Future<void> saveSelectedChatSalesFunnel(String funnelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      //print('ApiService.saveSelectedChatSalesFunnel: Saving funnelId: $funnelId');
      final success =
          await prefs.setString('selected_chat_sales_funnel', funnelId);
      //print('ApiService.saveSelectedChatSalesFunnel: Save success: $success');

      // Проверяем, что значение сохранено
      final savedFunnelId = prefs.getString('selected_chat_sales_funnel');
      //print('ApiService.saveSelectedChatSalesFunnel: Verified saved funnelId: $savedFunnelId');
      if (savedFunnelId != funnelId) {
        //print('ApiService.saveSelectedChatSalesFunnel: Warning - saved funnelId ($savedFunnelId) does not match input ($funnelId)');
      }
    } catch (e) {
      //print('ApiService.saveSelectedChatSalesFunnel: Error saving funnelId: $e');
      rethrow;
    }
  }

  Future<String?> getSelectedChatSalesFunnel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedFunnel = prefs.getString('selected_chat_sales_funnel');
      //print('ApiService.getSelectedChatSalesFunnel: Retrieved funnelId: $selectedFunnel');
      return selectedFunnel;
    } catch (e) {
      //print('ApiService.getSelectedChatSalesFunnel: Error retrieving funnelId: $e');
      return null;
    }
  }

// Новый метод для сохранения списка воронок в кэш
  Future<void> cacheSalesFunnels(List<SalesFunnel> funnels) async {
    //print('ApiService: Caching sales funnels');
    final prefs = await SharedPreferences.getInstance();
    final funnelsJson = funnels.map((funnel) => funnel.toJson()).toList();
    await prefs.setString('cached_sales_funnels', json.encode(funnelsJson));
    //print('ApiService: Cached ${funnels.length} sales funnels');
  }

// Новый метод для получения списка воронок из кэша
  Future<List<SalesFunnel>> getCachedSalesFunnels() async {
    //print('ApiService: Retrieving cached sales funnels');
    final prefs = await SharedPreferences.getInstance();
    final funnelsJson = prefs.getString('cached_sales_funnels');
    if (funnelsJson != null) {
      final List<dynamic> decoded = json.decode(funnelsJson);
      final funnels =
          decoded.map((json) => SalesFunnel.fromJson(json)).toList();
      //print(
      // 'ApiService: Retrieved ${funnels.length} cached sales funnels: $funnels');
      return funnels;
    }
    //print('ApiService: No cached sales funnels found');
    return [];
  }

// Новый метод для очистки кэша воронок
  Future<void> clearCachedSalesFunnels() async {
    //print('ApiService: Clearing cached sales funnels');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_sales_funnels');
    //print('ApiService: Cached sales funnels cleared');
  }

// Предполагаемый существующий метод для загрузки воронок с сервера
  Future<List<SalesFunnel>> getSalesFunnels() async {
    //print('ApiService: Starting getSalesFunnels request');
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/sales-funnel');
    if (kDebugMode) {
      //print('ApiService: getSalesFunnels - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      //print(
      // 'ApiService: getSalesFunnels response status: ${response.statusCode}');
      //print('ApiService: getSalesFunnels response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        //print('ApiService: Decoded JSON data: $data');

        if (data['result'] != null && data['result'] is List) {
          List<SalesFunnel> funnels = (data['result'] as List)
              .map((funnel) => SalesFunnel.fromJson(funnel))
              .toList();
          //print('ApiService: Parsed ${funnels.length} sales funnels: $funnels');
          // Сохраняем воронки в кэш после успешной загрузки
          await cacheSalesFunnels(funnels);
          return funnels;
        } else {
          //print('ApiService: No funnels found in response');
          throw Exception('Воронки продаж не найдены');
        }
      } else {
        //print('ApiService: Failed with status code ${response.statusCode}');
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      //print('ApiService: Error in getSalesFunnels');
      rethrow;
    }
  }

// Список endpoint'ов, для которых не нужно добавлять sales_funnel_id
  static const List<String> _excludedEndpoints = [
    '/login',
    '/checkDomain',
    '/logout',
    '/forgotPin',
    '/add-fcm-token',
  ];

// Централизованный метод для добавления query-параметров
Future<String> _appendQueryParams(String path) async {
  try {
    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    // Проверяем, есть ли уже параметры в path
    bool hasParams = path.contains('?');
    String separator = hasParams ? '&' : '?';
    String result = path;

    if (organizationId != null && organizationId.isNotEmpty && organizationId != 'null') {
      result += '${separator}organization_id=$organizationId';
      separator = '&';
    }

    if (salesFunnelId != null && salesFunnelId.isNotEmpty && salesFunnelId != 'null') {
      result += '${separator}sales_funnel_id=$salesFunnelId';
    }

    return result;
  } catch (e) {
    debugPrint('_appendQueryParams error: $e');
    // Возвращаем исходный path если не удалось добавить параметры
    return path;
  }
}
  //_________________________________ END_____API_SCREEN__PROFILE____________________________________________//

  //_________________________________ START_____API_SCREEN__NOTIFICATIONS____________________________________________//

// Метод для получения списка Уведомлений
  Future<List<Notifications>> getAllNotifications(
      {int page = 1, int perPage = 20}) async {
    String path = await _appendQueryParams(
        '/notification/unread?page=$page&per_page=$perPage');
    if (kDebugMode) {
      //print('ApiService: getAllNotifications - Generated path: $path');
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
              //print('Ошибка десериализации уведомления: $e, JSON: $json');
              rethrow;
            }
          }).toList();
        } else {
          throw Exception('Нет данных о уведомлениях в ответе');
        }
      } catch (e) {
        //print('Ошибка декодирования ответа: $e');
        throw Exception('Ошибка обработки ответа сервера: $e');
      }
    } else {
      throw Exception('Ошибка загрузки уведомлений: ${response.statusCode}');
    }
  }

// Метод для прочтения всех Уведомлений
  Future<void> DeleteAllNotifications() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/notification/readAll');
    if (kDebugMode) {
      //print('ApiService: DeleteAllNotifications - Generated path: $path');
    }

    ////print('Sending POST request to API with path: $path');

    final response = await _postRequest(path, {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления уведомлений!');
    }
  }

// Метод для удаления Уведомлений
  Future<void> DeleteNotifications({int? notificationId}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path =
        await _appendQueryParams('/notification/read/$notificationId');
    if (kDebugMode) {
      //print('ApiService: DeleteNotifications - Generated path: $path');
    }

    Map<String, dynamic> body = {
      'notificationId': notificationId,
      'organization_id': await getSelectedOrganization(),
    };

    ////print('Sending POST request to API with path: $path');

    final response = await _postRequest(path, body);

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления уведомлений!');
    }
    final data = json.decode(response.body);
    if (data['result'] == 'Success') {
      return;
    } else {
      throw Exception('Ошибка удаления уведомления');
    }
  }

//_________________________________ END_____API_SCREEN__NOTIFICATIONS____________________________________________//

//_________________________________ START_____API_PROFILE_SCREEN____________________________________________//

//Метод для получения Пользователя через его ID
  Future<UserByIdProfile> getUserById(int userId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/user/$userId');
      if (kDebugMode) {
        //print('ApiService: getUserById - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonUser = decodedJson['result'];

        if (jsonUser == null) {
          throw Exception('Некорректные данные от API');
        }

        final userProfile = UserByIdProfile.fromJson(jsonUser);

        // Сохраняем unique_id в SharedPreferences
        if (userProfile.uniqueId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('unique_id', userProfile.uniqueId!);
          ////print('unique_id сохранён: ${userProfile.uniqueId}');
        } else {
          ////print('unique_id не получен от сервера');
        }

        return userProfile;
      } else {
        throw Exception('Ошибка загрузки User ID: ${response.statusCode}');
      }
    } catch (e) {
      ////print('Ошибка загрузки User ID: $e');
      throw Exception('Ошибка загрузки User ID');
    }
  }

// Метод для Редактирования профиля
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    required String sname,
    required String phone,
    String? email,
    String? filePath,
  }) async {
    try {
      final token = await getToken(); // Получаем токен
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/profile/$userId');
      if (kDebugMode) {
        //print('ApiService: updateProfile - Generated path: $path');
      }

      // Создаем URL для обновления профиля
      var uri = Uri.parse('$baseUrl$path');

      // Создаем multipart запрос
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем поля
      request.fields['name'] = name;
      request.fields['lastname'] = sname;
      request.fields['phone'] = phone;

      if (email != null) {
        request.fields['email'] = email;
      }

      // Добавляем файл, если указан путь
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          final fileStream = http.ByteStream(file.openRead());
          final length = await file.length();

          final multipartFile = http.MultipartFile(
            'image', // Название поля в API, куда передается файл
            fileStream,
            length,
            filename: fileName,
          );
          request.files.add(multipartFile);
        }
      }

      // Отправляем запрос
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'profile_updated_successfully'};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': 'error_validation_data'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      } else if (response.statusCode == 500) {
        return {'success': false, 'message': 'error_server_text'};
      } else {
        return {'success': false, 'message': 'error_update_profile'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_update_profile',
      };
    }
  }

//_________________________________ END_____API_PROFILE_SCREEN____________________________________________//

//_________________________________ START___API__SCREEN__MY-TASK____________________________________________//

  Future<MyTaskById> getMyTaskById(int taskId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task/$taskId');
      if (kDebugMode) {
        //print('ApiService: getMyTaskById - Generated path: $path');
      }

      final response = await _getRequest(path);

      ////print('Response status code: ${response.statusCode}');
      ////print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? result = decodedJson['result'];

        if (result == null) {
          throw ('Некорректные данные от API: result is null');
        }

        return MyTaskById.fromJson(result, 0);
      } else {
        throw ('HTTP Error');
      }
    } catch (e) {
      ////print('Error in getMyTaskById: $e');
      throw ('Ошибка загрузки task ID');
    }
  }

  Future<bool> checkOverdueTasks() async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task/check/overdue');
      if (kDebugMode) {
        //print('ApiService: checkOverdueTasks - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        return decodedJson['res'] ?? false;
      } else {
        throw Exception('Failed to check overdue tasks');
      }
    } catch (e) {
      throw Exception('Error checking overdue tasks');
    }
  }

  Future<List<MyTask>> getMyTasks(
    int? taskStatusId, {
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    // Формируем базовый путь
    String path = '/my-task?page=$page&per_page=$perPage';

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    } else if (taskStatusId != null) {
      // Условие: если нет userId
      path += '&task_status_id=$taskStatusId';
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //print('ApiService: getMyTasks - Generated path: $path');
    }

    // Логируем конечный URL запроса
    // ////print('Sending request to API with path: $path');
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => MyTask.fromJson(json, taskStatusId ?? -1))
            .toList();
      } else {
        throw Exception('Нет данных о задачах в ответе');
      }
    } else {
      // Логирование ошибки с ответом сервера
      ////print('Error response! - ${response.body}');
      throw Exception('Ошибка загрузки задач!');
    }
  }

// Метод для получения статусов задач
  Future<List<MyTaskStatus>> getMyTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task-status');
      if (kDebugMode) {
        //print('ApiService: getMyTaskStatuses - Generated path: $path');
      }

      // Отправляем запрос на сервер
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          // Принт старых кэшированных данных (если они есть)
          final cachedStatuses = prefs.getString(
              'cachedMyTaskStatuses_${await getSelectedOrganization()}');
          if (cachedStatuses != null) {
            final decodedData = json.decode(cachedStatuses);
          }

          // Обновляем кэш новыми данными
          await prefs.setString(
              'cachedMyTaskStatuses_${await getSelectedOrganization()}',
              json.encode(data['result']));
          // ////print(
          //     '------------------------------------ Новые данные, которые сохраняются в кэш ---------------------------------');
          // ////print(data['result']); // Новые данные, которые будут сохранены в кэш

          return (data['result'] as List)
              .map((status) => MyTaskStatus.fromJson(status))
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      ////print('Ошибка загрузки статусов задач. Используем кэшированные данные.');
      // Если запрос не удался, пытаемся загрузить данные из кэша
      final cachedStatuses = prefs
          .getString('cachedMyTaskStatuses_${await getSelectedOrganization()}');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => MyTaskStatus.fromJson(status))
            .toList();
        return cachedList;
      } else {
        throw Exception(
            'Ошибка загрузки статусов задач и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasMyTasks(int taskStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<MyTask> tasks =
          await getMyTasks(taskStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return tasks.isNotEmpty;
    } catch (e) {
      ////print('Error while checking if status has deals!');
      return false;
    }
  }

// Обновление статуса карточки Задачи в колонке
  Future<void> updateMyTaskStatus(
      int taskId, int position, int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task/change-status/$taskId');
    if (kDebugMode) {
      //print('ApiService: updateMyTaskStatus - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'position': 1,
      'status_id': statusId,
    });

    if (response.statusCode == 200) {
      ////print('Статус задачи успешно обновлен');
    } else if (response.statusCode == 422) {
      throw MyTaskStatusUpdateException(
          422, 'Вы не можете переместить задачу на этот статус');
    } else {
      throw Exception('Ошибка обновления задач сделки!');
    }
  }

  Map<String, dynamic> _handleMyTaskResponse(
      http.Response response, String operation) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      // Проверяем наличие ошибок в ответе
      if (data['errors'] != null) {
        return {
          'success': false,
          'message': 'Ошибка ${operation} задачи: ${data['errors']}',
        };
      }

      return {
        'success': true,
        'message':
            'Задача ${operation == 'создания' ? 'создана' : 'обновлена'} успешно.',
        'data': data['result'],
      };
    }

    if (response.statusCode == 422) {
      final data = json.decode(response.body);
      final validationErrors = {
        'name': 'Название задачи должно содержать минимум 3 символа.',
        'from': 'Неверный формат даты начала.',
        'to': 'Неверный формат даты окончания.',
        'project_id': 'Указанный проект не существует.',
        'user_id': 'Указанный пользователь не существует.',
        // Убрана валидация файла
      };

      // Игнорируем ошибки валидации файла
      if (data['errors']?['file'] != null) {
        data['errors'].remove('file');
      }

      // Проверяем каждое поле на наличие ошибки, кроме файла
      for (var entry in validationErrors.entries) {
        if (data['errors']?[entry.key] != null) {
          return {'success': false, 'message': entry.value};
        }
      }

      // Если остались только ошибки файла, считаем что валидация прошла успешно
      if (data['errors']?.isEmpty ?? true) {
        return {
          'success': true,
          'message':
              'Задача ${operation == 'создания' ? 'создана' : 'обновлена'} успешно.',
        };
      }

      return {
        'success': false,
        'message': 'Ошибка валидации: ${data['errors'] ?? response.body}',
      };
    }

    return {
      'success': false,
      'message': 'Ошибка ${operation} задачи!',
    };
  }

// Создает новый статус задачи
  Future<Map<String, dynamic>> CreateMyTaskStatusAdd({
    required String statusName,
    bool? finalStep,
  }) async {
    try {
      // Формируем данные для запроса
      final Map<String, dynamic> data = {
        'title': statusName,
        'color': "#000",
      };
      if (finalStep != null) {
        data['final_step'] = finalStep;
      }

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task-status');
      if (kDebugMode) {
        //print('ApiService: CreateMyTaskStatusAdd - Generated path: $path');
      }

      // Выполняем запрос
      final response = await _postRequest(path, data);

      // Проверяем успешность запроса
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Статус задачи успешно создан',
          'data': responseData,
        };
      }

      // Получаем текст ошибки в зависимости от кода ответа
      final errorMessage = _getErrorMessage(response.statusCode);

      return {
        'success': false,
        'message': errorMessage,
        'statusCode': response.statusCode,
        'details': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при создании статуса',
        'error': e.toString(),
      };
    }
  }

  /// Возвращает сообщение об ошибке по коду статуса
  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Неверные данные для создания статуса';
      case 401:
        return 'Необходима авторизация';
      case 403:
        return 'Недостаточно прав для создания статуса';
      case 404:
        return 'Ресурс не найден';
      case 409:
        return 'Статус с таким названием уже существует';
      case 500:
        return 'Внутренняя ошибка сервера';
      default:
        return 'Произошла ошибка при создании статуса (код: $statusCode)';
    }
  }

// Метод для создания задачи
  Future<Map<String, dynamic>> createMyTask({
    required String name,
    required int? statusId,
    required int? taskStatusId,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    List<String>? filePaths,
    int position = 1,
    required bool setPush,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task');
      if (kDebugMode) {
        //print('ApiService: createMyTask - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');

      // Создаем multipart request
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем все поля в формате form-data
      request.fields['name'] = name;
      request.fields['status_id'] = statusId.toString();
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['position'] = position.toString();
      request.fields['send_notification'] = setPush ? '1' : '0';

      if (startDate != null) {
        request.fields['from'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        request.fields['to'] = endDate.toIso8601String();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      // Добавляем файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath(
              'files[]', filePath); // Используем 'files[]'
          request.files.add(file);
        }
      }

      // Отправляем запрос
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Задача успешно создана',
          'data': responseData,
        };
      } else {
        // Обрабатываем различные коды ошибок
        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage = 'Неверные данные запроса';
            break;
          case 401:
            errorMessage = 'Необходима авторизация';
            break;
          case 403:
            errorMessage = 'Недостаточно прав для создания задачи';
            break;
          case 404:
            errorMessage = 'Ресурс не найден';
            break;
          case 409:
            errorMessage = 'Конфликт при создании задачи';
            break;
          case 500:
            errorMessage = 'Внутренняя ошибка сервера';
            break;
          default:
            errorMessage = 'Произошла ошибка при создании задачи';
        }
        return {
          'success': false,
          'message': '$errorMessage!',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      ////print('Detailed error: $e');
      return {
        'success': false,
        'message': 'Ошибка при выполнении запроса!',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateMyTask({
    required int taskId,
    required String name,
    required int? taskStatusId,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    List<String>? filePaths,
    required bool setPush,
    List<MyTaskFiles>? existingFiles,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task/$taskId');
      if (kDebugMode) {
        //print('ApiService: updateMyTask - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');

      // Создаем multipart request
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем все поля в формате form-data
      request.fields['name'] = name;
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['send_notification'] = setPush ? '1' : '0';

      if (endDate != null) {
        request.fields['to'] =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      // Добавляем новые файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }

      // Добавляем информацию о существующих файлах
      if (existingFiles != null && existingFiles.isNotEmpty) {
        List<Map<String, dynamic>> existingFilesList = existingFiles
            .map(
                (file) => {'id': file.id, 'name': file.name, 'path': file.path})
            .toList();

        request.fields['existing_files'] = json.encode(existingFilesList);
      }

      // Отправляем запрос
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Задача успешно обновлена',
          'data': responseData,
        };
      } else {
        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage = 'Неверные данные запроса';
            break;
          case 401:
            errorMessage = 'Необходима авторизация';
            break;
          case 403:
            errorMessage = 'Недостаточно прав для обновления задачи';
            break;
          case 404:
            errorMessage = 'Ресурс не найден';
            break;
          case 409:
            errorMessage = 'Конфликт при обновлении задачи';
            break;
          case 500:
            errorMessage = 'Внутренняя ошибка сервера';
            break;
          default:
            errorMessage = 'Произошла ошибка при обновлении задачи';
        }
        return {
          'success': false,
          'message': '$errorMessage!',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      ////print('Detailed error: $e');
      return {
        'success': false,
        'message': 'Ошибка при выполнении запроса!',
        'error': e.toString(),
      };
    }
  }

// Метод для получения Истории Задачи
  Future<List<MyTaskHistory>> getMyTaskHistory(int taskId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task/history/$taskId');
      if (kDebugMode) {
        //print('ApiService: getMyTaskHistory - Generated path: $path');
      }

      // Используем метод _getRequest вместо прямого выполнения запроса
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => MyTaskHistory.fromJson(json)).toList();
      } else {
        ////print('Failed to load task history!');
        throw Exception('Ошибка загрузки истории задач!');
      }
    } catch (e) {
      ////print('Error occurred!');
      throw Exception('Ошибка загрузки истории задач!');
    }
  }

// Метод для получения Статуса задачи
  Future<List<MyStatusName>> getMyStatusName() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-taskStatusName');
    if (kDebugMode) {
      //print('ApiService: getMyStatusName - Generated path: $path');
    }

    ////print('Начало запроса статусов задач'); // Отладочный вывод
    final response = await _getRequest(path);
    ////print('Статус код ответа!'); // Отладочный вывод

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////print('Полученные данные: $data'); // Отладочный вывод

      if (data['result'] != null) {
        final statusList = (data['result'] as List)
            .map((name) => MyStatusName.fromJson(name))
            .toList();
        ////print(
        // 'Преобразованный список статусов: $statusList'); // Отладочный вывод
        return statusList;
      } else {
        throw Exception('Статусы задач не найдены');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

// Метод для Удаления Задачи
  Future<Map<String, dynamic>> deleteMyTask(int taskId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task/$taskId');
    if (kDebugMode) {
      //print('ApiService: deleteMyTask - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete task!');
    }
  }

// Метод для Удаления Статуса Задачи
  Future<Map<String, dynamic>> deleteMyTaskStatuses(int taskStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task-status/$taskStatusId');
    if (kDebugMode) {
      //print('ApiService: deleteMyTaskStatuses - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete taskStatus!');
    }
  }

// Метод для завершения задачи
  Future<Map<String, dynamic>> finishMyTask(int taskId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task/finish');
    if (kDebugMode) {
      //print('ApiService: finishMyTask - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'task_id': taskId,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Задача успешно завершена'};
    } else if (response.statusCode == 422) {
      try {
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ??
            'Неизвестная ошибка при завершении задачи';
        return {
          'success': false,
          'message': errorMessage,
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Ошибка обработки ответа сервера',
        };
      }
    } else {
      return {'success': false, 'message': 'Ошибка завершения задачи!'};
    }
  }

//Метод для получения кастомных полей Задачи
  Future<Map<String, dynamic>> getMyCustomFields() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task/get/custom-fields');
    if (kDebugMode) {
      //print('ApiService: getMyCustomFields - Generated path: $path');
    }

    // Выполняем запрос
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return data; // Возвращаем данные, если они есть
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<MyTaskStatus> getMyTaskStatus(int myTaskStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task-status/$myTaskStatusId');
    if (kDebugMode) {
      //print('ApiService: getMyTaskStatus - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return MyTaskStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

  Future<Map<String, dynamic>> updateMyTaskStatusEdit(int myTaskStatusId,
      String title, bool finalStep, AppLocalizations localizations) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task-status/$myTaskStatusId');
    if (kDebugMode) {
      //print('ApiService: updateMyTaskStatusEdit - Generated path: $path');
    }

    final payload = {
      "title": title,
      "organization_id": await getSelectedOrganization(),
      "color": "#000",
      "final_step": finalStep ? 1 : 0, // Конвертируем bool в 1/0
    };
    final response = await _patchRequest(path, payload);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update leadStatus!');
    }
  }

//_________________________________ START_____API_SCREEN__EVENT____________________________________________//

  Future<List<NoticeEvent>> getEvents({
    int page = 1,
    int perPage = 20,
    String? search,
    List<int>? managers,
    int? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? noticefromDate,
    DateTime? noticetoDate,
    int? salesFunnelId, // Новый параметр
  }) async {
    try {
      // Формируем базовый путь
      String path = '/notices?page=$page&per_page=$perPage';

      if (search != null && search.isNotEmpty) {
        path += '&search=$search';
      }

      if (managers != null && managers.isNotEmpty) {
        for (int i = 0; i < managers.length; i++) {
          path += '&managers[$i]=${managers[i]}';
        }
      }

      if (statuses != null) {
        path += '&event_status_id=$statuses';
        bool isFinished = statuses == 2;
        path +=
            '&isFinished=${isFinished ? '1' : '0'}'; // Передаем 1 или 0 вместо true/false
      }
      if (salesFunnelId != null) {
        path += '&sales_funnel_id=$salesFunnelId';
      }
      if (fromDate != null && toDate != null) {
        final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
        final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
        path += '&created_from=$formattedFromDate&created_to=$formattedToDate';
      }

      if (noticefromDate != null && noticetoDate != null) {
        final formattedFromDate =
            DateFormat('yyyy-MM-dd').format(noticefromDate);
        final formattedToDate = DateFormat('yyyy-MM-dd').format(noticetoDate);
        path += '&push_from=$formattedFromDate&push_to=$formattedToDate';
      }

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      path = await _appendQueryParams(path);
      if (kDebugMode) {
        //print('ApiService: getEvents - Generated path: $path');
      }

      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null && data['result']['data'] != null) {
          return (data['result']['data'] as List)
              .map((json) => NoticeEvent.fromJson(json))
              .toList();
        } else {
          throw ('Нет данных о событиях в ответе');
        }
      } else {
        throw ('Ошибка загрузки событий!');
      }
    } catch (e) {
      throw ('Ошибка загрузки событий');
    }
  }

  Future<Notice> getNoticeById(int noticeId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/notices/show/$noticeId');
      if (kDebugMode) {
        //print('ApiService: getNoticeById - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonNotice = decodedJson['result'];

        if (jsonNotice == null) {
          throw ('Некорректные данные от API');
        }

        return Notice.fromJson(jsonNotice);
      } else {
        throw ('Ошибка загрузки notice ID!');
      }
    } catch (e) {
      throw ('Ошибка загрузки notice ID!');
    }
  }

  Future<Map<String, dynamic>> createNotice({
    String? title,
    required String body,
    required int leadId,
    DateTime? date,
    required int sendNotification,
    required List<int> users,
    List<String>? filePaths,
  }) async {
    try {
      // Формируем путь с query-параметрами
      final path = await _appendQueryParams('/notices');
      if (kDebugMode) {
        //print('ApiService: createNotice - Generated path: $path');
      }

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));

      // Добавляем поля в запрос
      if (title != null && title.isNotEmpty) {
        request.fields['title'] = title;
      }
      request.fields['body'] = body;
      request.fields['lead_id'] = leadId.toString();
      if (date != null) {
        request.fields['date'] = DateFormat('yyyy-MM-dd HH:mm').format(date);
      }
      request.fields['send_notification'] = sendNotification.toString();

      // Добавляем массив users
      for (int i = 0; i < users.length; i++) {
        request.fields['users[$i]'] = users[i].toString();
      }

      // Добавляем файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }

      final response = await _multipartPostRequest(path, request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'notice_create_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('title')) {
          return {'success': false, 'message': 'invalid_title_length'};
        }
        if (response.body.contains('users')) {
          return {'success': false, 'message': 'error_users'};
        }
        return {'success': false, 'message': 'validation_error'};
      } else if (response.statusCode == 500) {
        return {'success': false, 'message': 'error_server_text'};
      } else {
        return {'success': false, 'message': 'error_notice_create'};
      }
    } catch (e) {
      return {'success': false, 'message': 'error_notice_create'};
    }
  }

  Future<Map<String, dynamic>> updateNotice({
    required int noticeId,
    String? title,
    required String body,
    required int leadId,
    DateTime? date,
    required int sendNotification,
    required List<int> users,
    List<String>? filePaths,
    List<NoticeFiles>? existingFiles,
  }) async {
    // Формируем путь с query-параметрами
    final path = await _appendQueryParams('/notices/$noticeId');
    if (kDebugMode) {
      //print('ApiService: updateNotice - Generated path: $path');
    }

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));

    // Добавляем поля явно
    if (title != null) request.fields['title'] = title;
    request.fields['body'] = body;
    request.fields['lead_id'] = leadId.toString();
    if (date != null)
      request.fields['date'] = DateFormat('yyyy-MM-dd HH:mm').format(date);
    request.fields['send_notification'] = sendNotification.toString();

    // Добавляем пользователей
    if (users.isNotEmpty) {
      for (int i = 0; i < users.length; i++) {
        request.fields['users[$i]'] = users[i].toString();
      }
    }

    // Добавляем ID существующих файлов
    if (existingFiles != null && existingFiles.isNotEmpty) {
      final existingFileIds = existingFiles.map((file) => file.id).toList();
      for (int i = 0; i < existingFileIds.length; i++) {
        request.fields['existing_file_ids[$i]'] = existingFileIds[i].toString();
      }
    }

    // Добавляем новые файлы, если они есть
    if (filePaths != null && filePaths.isNotEmpty) {
      for (var filePath in filePaths) {
        final file = await http.MultipartFile.fromPath('files[]', filePath);
        request.files.add(file);
      }
    }

    final response = await _multipartPostRequest(path, request);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'notice_updated_successfully'};
    } else if (response.statusCode == 422) {
      return {'success': false, 'message': 'validation_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'error_notice_update'};
    }
  }

  Future<Map<String, dynamic>> deleteNotice(int noticeId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/notices/$noticeId');
    if (kDebugMode) {
      //print('ApiService: deleteNotice - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw ('Failed to delete notice!');
    }
  }

  Future<Map<String, dynamic>> finishNotice(
      int noticeId, String conclusion) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/notices/finish/$noticeId');
    if (kDebugMode) {
      //print('ApiService: finishNotice - Generated path: $path');
    }

    final response = await _patchRequest(path, {
      "conclusion": conclusion,
      "organization_id": await getSelectedOrganization()
    });

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw ('Failed to finish notice!');
    }
  }

  Future<SubjectDataResponse> getAllSubjects() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/noteSubject/by-sales-funnel-id');
    if (kDebugMode) {
      //print('ApiService: getAllSubjects - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SubjectDataResponse.fromJson(data);
    } else {
      throw ('Failed to load subjects');
    }
  }

// get all authors
  Future<AuthorsDataResponse> getAllAuthor() async {
    final token = await getToken(); // Получаем токен перед запросом
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/user');
    if (kDebugMode) {
      //print('ApiService: getAllAuthor - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    late AuthorsDataResponse dataAuthor;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataAuthor = AuthorsDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // ////print('Статус ответа!');
    }
    if (kDebugMode) {
      // ////print('getAll author!');
    }

    return dataAuthor;
  }

  String getRecordingUrl(String recordPath) {
    if (recordPath.isEmpty) return '';

    // Если путь уже содержит полный URL, возвращаем его
    if (recordPath.startsWith('') || recordPath.startsWith('')) {
      return recordPath;
    }

    // Убираем '/api' из baseUrl и добавляем путь к записи
    String cleanBaseUrl = baseUrl?.replaceAll('', '') ?? '';
    return recordPath.startsWith('/call-recordings/')
        ? '$cleanBaseUrl$recordPath'
        : '$cleanBaseUrl/storage/$recordPath';
  }

//_________________________________ END_____API_SCREEN__EVENT____________________________________________//

//_________________________________ START_____API_SCREEN__TUTORIAL____________________________________________//

  Future<Map<String, dynamic>> getTutorialProgress() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/tutorials/getProgress');
    if (kDebugMode) {
      //print('ApiService: getTutorialProgress - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception(
          'Failed to get tutorial progress: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getSettings(String? organizationId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/setting');
    if (kDebugMode) {
      //print('ApiService: getSettings - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to get settings: ${response.statusCode}');
    }
  }

// api/service/api_service.dart
  Future<List<MiniAppSettings>> getMiniAppSettings(
      String? organizationId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/mini-app/setting');
    if (kDebugMode) {
      //print('ApiService: getMiniAppSettings - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null && data['result'] is List) {
        return (data['result'] as List)
            .map((item) => MiniAppSettings.fromJson(item))
            .toList();
      } else {
        throw Exception(
            'Invalid response format: result is missing or not a list');
      }
    } else {
      throw Exception(
          'Failed to get mini-app settings: ${response.statusCode}');
    }
  }

  Future<void> markPageCompleted(String section, String pageType) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/tutorials/markPageCompleted');
    if (kDebugMode) {
      //print('ApiService: markPageCompleted - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        "section": section,
        "page_type": pageType,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark page completed: ${response.statusCode}');
    }
  }

//_________________________________ END_____API_SCREEN__TUTORIAL____________________________________________//

//_________________________________ START_____API_SCREEN__CATEGORY____________________________________________//

  Future<CharacteristicListDataResponse> getAllCharacteristics() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/attribute');
    if (kDebugMode) {
      //print('ApiService: getAllCharacteristics - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CharacteristicListDataResponse.fromJson(data);
    } else {
      throw ('Ошибка загрузки списка характеритсикии');
    }
  }

  Future<List<CategoryData>> getCategory({String? search}) async {
    String path = '/category';
    if (search != null && search.isNotEmpty) {
      path += '?search=$search';
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //print('ApiService: getCategory - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.containsKey('result') && data['result'] is List) {
        return (data['result'] as List)
            .map((category) =>
                CategoryData.fromJson(category as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception('Ошибка загрузки категории: ${response.statusCode}');
    }
  }

  Future<SubCategoryResponseASD> getSubCategoryById(int categoryId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path =
          await _appendQueryParams('/category/get-by-parent-id/$categoryId');
      if (kDebugMode) {
        //print('ApiService: getSubCategoryById - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        ////print(decodedJson);
        return SubCategoryResponseASD.fromJson(decodedJson);
      } else {
        throw Exception(
            'Failed to load subcategories. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load subcategories: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createCategory({
    required String name,
    required int parentId,
    required List<Map<String, dynamic>> attributes,
    File? image,
    required String displayType,
    required bool hasPriceCharacteristics,
    required bool isParent, // Добавляем новый параметр
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/category');
      if (kDebugMode) {
        //print('ApiService: createCategory - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;
      if (parentId != 0) {
        request.fields['parent_id'] = parentId.toString();
      }
      request.fields['display_type'] = displayType;
      request.fields['has_price_characteristics'] =
          hasPriceCharacteristics ? '1' : '0';
      request.fields['is_parent'] =
          isParent ? '1' : '0'; // Добавляем поле is_parent

      for (int i = 0; i < attributes.length; i++) {
        request.fields['attributes[$i][attribute]'] = attributes[i]['name'];
        request.fields['attributes[$i][is_individual]'] =
            attributes[i]['is_individual'] ? '1' : '0';
      }

      if (image != null) {
        final imageFile =
            await http.MultipartFile.fromPath('image', image.path);
        request.files.add(imageFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'category_created_successfully',
          'data': CategoryData.fromJson(responseBody),
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to create category',
          'error': responseBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ',
      };
    }
  }

  Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
    required String name,
    File? image,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/category/update/$categoryId');
      if (kDebugMode) {
        //print('ApiService: updateCategory - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;

      if (image != null) {
        final imageFile =
            await http.MultipartFile.fromPath('image', image.path);
        request.files.add(imageFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Категория успешно обновлена',
          'data': responseBody,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to update category',
          'error': responseBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ',
      };
    }
  }

  Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/category/$categoryId');
    if (kDebugMode) {
      //print('ApiService: deleteCategory - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete category!');
    }
  }

  Future<Map<String, dynamic>> updateSubCategory({
    required int subCategoryId,
    required String name,
    File? image,
    required List<Map<String, dynamic>> attributes,
    required String displayType,
    required bool hasPriceCharacteristics,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/category/update/$subCategoryId');
      if (kDebugMode) {
        //print('ApiService: updateSubCategory - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;
      request.fields['display_type'] = displayType;
      request.fields['has_price_characteristics'] =
          hasPriceCharacteristics ? '1' : '0';

      for (int i = 0; i < attributes.length; i++) {
        request.fields['attributes[$i][attribute]'] = attributes[i]['name'];
        request.fields['attributes[$i][is_individual]'] =
            attributes[i]['is_individual'] ? '1' : '0';
      }

      if (image != null) {
        final imageFile =
            await http.MultipartFile.fromPath('image', image.path);
        request.files.add(imageFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'subcategory_updated_successfully',
          'data': responseBody,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'failed_to_update_subcategory',
          'error': responseBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_occurred: ',
      };
    }
  }

//_________________________________ END_____API_SCREEN__CATEGORY____________________________________________//

//_________________________________ START_____API_SCREEN__GOODS____________________________________________//

  Future<List<Goods>> getGoods({
    int page = 1,
    int perPage = 20,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/good?page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    if (filters != null) {
      if (filters.containsKey('category_id') &&
          filters['category_id'] is List &&
          (filters['category_id'] as List).isNotEmpty) {
        final categoryIds = filters['category_id'] as List;
        for (int i = 0; i < categoryIds.length; i++) {
          path += '&category_id[]=${categoryIds[i]}';
        }
      }

      if (filters.containsKey('discount_percent')) {
        path += '&discount=${filters['discount_percent']}';
      }

      if (filters.containsKey('label_id') &&
          filters['label_id'] is List &&
          (filters['label_id'] as List).isNotEmpty) {
        final labelIds = filters['label_id'] as List<String>;
        for (var labelId in labelIds) {
          path += '&label_id[]=$labelId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены label_id: $labelIds');
        }
      }

      if (filters.containsKey('is_active')) {
        path += '&is_active=${filters['is_active'] ? 1 : 0}';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр is_active: ${filters['is_active']}');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //print('ApiService: getGoods - Generated path: $path');
    }

    final response = await _getRequest(path);
    if (kDebugMode) {
      //print(
      // 'ApiService: Ответ сервера: statusCode=${response.statusCode}, body=${response.body}');
    }
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result') && data['result']['data'] is List) {
        final goods = (data['result']['data'] as List)
            .map((item) => Goods.fromJson(item as Map<String, dynamic>))
            .toList();
        final total = data['result']['total'] ?? goods.length;
        final totalPages = data['result']['total_pages'] ??
            (goods.length < perPage ? page : page + 1);
        if (kDebugMode) {
          //print(
          // 'ApiService: Успешно получено ${goods.length} товаров, всего: $total, страниц: $totalPages');
        }
        return goods;
      } else {
        if (kDebugMode) {
          //print('ApiService: Ошибка формата данных: $data');
        }
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      if (kDebugMode) {
        //print('ApiService: Ошибка загрузки товаров: ${response.statusCode}');
      }
      throw Exception('Ошибка загрузки товаров: ${response.statusCode}');
    }
  }

  Future<List<Variant>> getVariants({
    int page = 1,
    int perPage = 15,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/good/get/variant?page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    if (filters != null) {
      if (filters.containsKey('category_id') &&
          filters['category_id'] is List &&
          (filters['category_id'] as List).isNotEmpty) {
        final categoryIds = filters['category_id'] as List;
        for (int i = 0; i < categoryIds.length; i++) {
          path += '&category_id[]=${categoryIds[i]}';
        }
      }
      if (filters.containsKey('is_active')) {
        path += '&is_active=${filters['is_active'] ? 1 : 0}';
        if (kDebugMode) {
          ////print('ApiService: Добавлен параметр is_active: ${filters['is_active']}');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //print('ApiService: getVariants - Generated path: $path');
    }

    final response = await _getRequest(path);
    if (kDebugMode) {
      ////print('ApiService: Ответ сервера: statusCode=${response.statusCode}, body=${response.body}');
    }
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result') && data['result']['data'] is List) {
        final variants = (data['result']['data'] as List)
            .map((item) => Variant.fromJson(item as Map<String, dynamic>))
            .toList();
        final paginationData = data['result']['pagination'] ?? {};
        final total = paginationData['total'] ?? variants.length;
        final totalPages = paginationData['total_pages'] ??
            (variants.length < perPage ? page : page + 1);
        if (kDebugMode) {
          ////print('ApiService: Успешно получено ${variants.length} вариантов, всего: $total, страниц: $totalPages');
        }
        return variants;
      } else {
        if (kDebugMode) {
          //print('ApiService: Ошибка формата данных: $data');
        }
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      if (kDebugMode) {
        //print('ApiService: Ошибка загрузки вариантов: ${response.statusCode}');
      }
      throw Exception('Ошибка загрузки вариантов: ${response.statusCode}');
    }
  }

  Future<List<Goods>> getGoodsById(int goodsId,
      {bool isFromOrder = false}) async {
    // Выбираем эндпоинт в зависимости от контекста
    final String path =
        isFromOrder ? '/good/variant-by-id/$goodsId' : '/good/$goodsId';

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final updatedPath = await _appendQueryParams(path);
    if (kDebugMode) {
      //print('ApiService: getGoodsById - Generated path: $updatedPath');
    }

    final response = await _getRequest(updatedPath);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        return [Goods.fromJson(data['result'] as Map<String, dynamic>)];
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception(
          'Ошибка загрузки просмотра товаров: ${response.statusCode}');
    }
  }

  Future<List<SubCategoryAttributesData>> getSubCategoryAttributes() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/category/get/subcategories');
    if (kDebugMode) {
      //print('ApiService: getSubCategoryAttributes - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      ////print('Response data: $data'); // Debug: //print the response
      if (data.containsKey('data')) {
        return (data['data'] as List).map((item) {
          ////print('Item: $item'); // Debug: //print each item
          return SubCategoryAttributesData.fromJson(
              item as Map<String, dynamic>);
        }).toList();
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception(
          'Ошибка загрузки просмотра товаров: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createGoods({
    required String name,
    required int parentId,
    required String description,
    required int quantity,
    required List<Map<String, dynamic>> attributes,
    required List<Map<String, dynamic>> variants,
    required List<File> images,
    required bool isActive,
    double? discountPrice,
    int? branch,
    double? price,
    int? mainImageIndex,
    int? labelId, // Parameter for label ID
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/good');
      if (kDebugMode) {
        //print('ApiService: createGoods - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile',
        'Content-Type': 'multipart/form-data; charset=utf-8',
      });

      request.fields['name'] = name;
      request.fields['category_id'] = parentId.toString();
      request.fields['description'] = description;
      request.fields['quantity'] = quantity.toString();
      request.fields['is_active'] = isActive ? '1' : '0';

      // Pass the actual labelId if it exists
      if (labelId != null) {
        request.fields['label_id'] = labelId.toString();
      }

      if (price != null) {
        request.fields['price'] = price.toString();
      }

      if (discountPrice != null) {
        request.fields['discount_price'] = discountPrice.toString();
      }

      if (branch != null) {
        request.fields['branches[0][branch_id]'] = branch.toString();
      }

      for (int i = 0; i < attributes.length; i++) {
        request.fields['attributes[$i][category_attribute_id]'] =
            attributes[i]['category_attribute_id'].toString();
        request.fields['attributes[$i][value]'] =
            attributes[i]['value'].toString();
      }

      for (int i = 0; i < variants.length; i++) {
        request.fields['variants[$i][is_active]'] =
            variants[i]['is_active'] ? '1' : '0';
        final variantPrice = variants[i]['price'] ?? 0.0;
        request.fields['variants[$i][price]'] = variantPrice.toString();

        List<dynamic> variantAttributes =
            variants[i]['variant_attributes'] ?? [];
        for (int j = 0; j < variantAttributes.length; j++) {
          request.fields[
                  'variants[$i][variant_attributes][$j][category_attribute_id]'] =
              variantAttributes[j]['category_attribute_id'].toString();
          request.fields['variants[$i][variant_attributes][$j][value]'] =
              variantAttributes[j]['value'].toString();
        }

        List<File> variantFiles = variants[i]['files'] ?? [];
        for (int j = 0; j < variantFiles.length; j++) {
          File file = variantFiles[j];
          if (await file.exists()) {
            final imageFile = await http.MultipartFile.fromPath(
                'variants[$i][files][$j]', file.path);
            request.files.add(imageFile);
          }
        }
      }

      for (int i = 0; i < images.length; i++) {
        File file = images[i];
        if (await file.exists()) {
          final imageFile =
              await http.MultipartFile.fromPath('files[$i][file]', file.path);
          request.files.add(imageFile);
          request.fields['files[$i][is_main]'] =
              (i == (mainImageIndex ?? 0)) ? '1' : '0';
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Товар успешно создан',
          'data': responseBody,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Не удалось создать товар',
          'error': responseBody,
        };
      }
    } catch (e, stackTrace) {
      // //print('ApiService: Error in createGoods: $e');
      // //print('ApiService: Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Произошла ошибка',
      };
    }
  }

  Future<Map<String, dynamic>> updateGoods({
    required int goodId,
    required String name,
    required int parentId,
    required String description,
    required int quantity,
    required List<Map<String, dynamic>> attributes,
    required List<Map<String, dynamic>> variants,
    required List<File> images,
    required bool isActive,
    double? discountPrice,
    int? branch,
    String? comments,
    int? mainImageIndex,
    int? labelId, // Добавляем параметр для ID метки
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/good/$goodId');
      if (kDebugMode) {
        //print('ApiService: updateGoods - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile',
        'Content-Type': 'multipart/form-data; charset=utf-8',
      });

      ////print('ApiService: Sending updateGoods request:');
      ////print('ApiService: goodId: $goodId, name: $name, parentId: $parentId, description: $description');
      ////print('ApiService: quantity: $quantity, isActive: $isActive, discountPrice: $discountPrice, branch: $branch, comments: $comments, mainImageIndex: $mainImageIndex');
      ////print('ApiService: attributes: $attributes');
      ////print('ApiService: variants: $variants');
      ////print('ApiService: images: ${images.map((file) => file.path).toList()}');

      request.fields['name'] = name;
      request.fields['category_id'] = parentId.toString();
      request.fields['description'] = description;
      request.fields['quantity'] = quantity.toString();
      request.fields['is_active'] = isActive ? '1' : '0';
      request.fields['label_id'] =
          labelId != null ? labelId.toString() : ''; // Add label fields

      if (branch != null) {
        request.fields['branches[0][branch_id]'] = branch.toString();
        ////print('ApiService: Added branch: $branch');
      }
      if (comments != null && comments.isNotEmpty) {
        request.fields['comments'] = comments;
        ////print('ApiService: Added comments: $comments');
      }
      if (discountPrice != null) {
        request.fields['price'] = discountPrice.toString();
        ////print('ApiService: Added discount_price: $discountPrice');
      }

      for (int i = 0; i < attributes.length; i++) {
        request.fields['attributes[$i][category_attribute_id]'] =
            attributes[i]['category_attribute_id'].toString();
        request.fields['attributes[$i][value]'] =
            attributes[i]['value'].toString();
        ////print('ApiService: Added attribute $i: ${request.fields['attributes[$i][category_attribute_id]']}, ${request.fields['attributes[$i][value]']}');
      }

      for (int i = 0; i < variants.length; i++) {
        if (variants[i].containsKey('id')) {
          request.fields['variants[$i][id]'] = variants[i]['id'].toString();
          ////print('ApiService: Added variant ID $i: ${variants[i]['id']}');
        }
        request.fields['variants[$i][is_active]'] =
            variants[i]['is_active'] ? '1' : '0';
        request.fields['variants[$i][price]'] =
            (variants[i]['price'] ?? 0.0).toString();
        ////print('ApiService: Added variant $i: is_active=${variants[i]['is_active']}, price=${variants[i]['price']}');

        List<dynamic> variantAttributes =
            variants[i]['variant_attributes'] ?? [];
        for (int j = 0; j < variantAttributes.length; j++) {
          if (variantAttributes[j].containsKey('id')) {
            request.fields['variants[$i][variant_attributes][$j][id]'] =
                variantAttributes[j]['id'].toString();
            ////print('ApiService: Added variant attribute ID $i-$j: ${variantAttributes[j]['id']}');
          }
          request.fields[
                  'variants[$i][variant_attributes][$j][category_attribute_id]'] =
              variantAttributes[j]['category_attribute_id'].toString();
          request.fields['variants[$i][variant_attributes][$j][value]'] =
              variantAttributes[j]['value'].toString();
          ////print('ApiService: Added variant attribute $i-$j: ${variantAttributes[j]}');
        }

        List<File> variantFiles = variants[i]['files'] ?? [];
        for (int j = 0; j < variantFiles.length; j++) {
          File file = variantFiles[j];
          if (await file.exists()) {
            final imageFile = await http.MultipartFile.fromPath(
                'variants[$i][files][$j]', file.path);
            request.files.add(imageFile);
            ////print('ApiService: Added variant file $i-$j: ${file.path}');
          } else {
            ////print('ApiService: Variant file not found, skipping: ${file.path}');
          }
        }
      }

      for (int i = 0; i < images.length; i++) {
        File file = images[i];
        if (await file.exists()) {
          final imageFile =
              await http.MultipartFile.fromPath('files[$i][file]', file.path);
          request.files.add(imageFile);
          request.fields['files[$i][is_main]'] =
              i == (mainImageIndex ?? 0) ? '1' : '0';
          ////print('ApiService: Added general image $i: ${file.path}, is_main: ${request.fields['files[$i][is_main]']}');
        } else {
          ////print('ApiService: General image not found, skipping: ${file.path}');
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = json.decode(response.body);

      ////print('ApiService: Response status: ${response.statusCode}');
      ////print('ApiService: Response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'goods_updated_successfully',
          'data': responseBody,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to update goods',
          'error': responseBody,
        };
      }
    } catch (e, stackTrace) {
      ////print('ApiService: Error in updateGoods: ');
      ////print('ApiService: Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'An error occurred: ',
      };
    }
  }

  Future<bool> deleteGoods(int goodId, {int? organizationId}) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/good/$goodId');
      if (kDebugMode) {
        //print('ApiService: deleteGoods - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Device': 'mobile',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
            jsonResponse['message'] ?? 'Ошибка при удалении товара');
      }
    } catch (e) {
      ////print('Ошибка удаления товара: ');
      return false;
    }
  }

  Future<List<Label>> getLabels() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/label');
    if (kDebugMode) {
      //print('ApiService: getLabels - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((label) => Label.fromJson(label))
            .toList();
      } else {
        throw Exception('Ошибка: поле "result" отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка загрузки меток');
    }
  }

  Future<List<Goods>> getGoodsByBarcode(String barcode) async {
    String path = '/good/getByBarcode?barcode=$barcode';
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      print('ApiService: Запрос товаров по штрихкоду: $path');
    }

    final response = await _getRequest(path);
    if (kDebugMode) {
      print(
          'ApiService: Ответ сервера: statusCode=${response.statusCode}, body=${response.body}');
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('errors') && data['errors'] != null) {
        if (kDebugMode) {
          print('ApiService: Ошибка сервера: ${data['errors']}');
        }
        throw Exception('Ошибка сервера: ${data['errors']}');
      }
      if (data.containsKey('result')) {
        final result = data['result'];
        if (result == null || result == 'Товар не найден') {
          if (kDebugMode) {
            print('ApiService: Товары по штрихкоду не найдены');
          }
          return [];
        }
        List<dynamic> goodsData;

        if (result is List) {
          goodsData = result;
        } else if (result is Map<String, dynamic>) {
          goodsData = [result];
        } else {
          if (kDebugMode) {
            print(
                'ApiService: Ошибка формата данных: result не является списком или объектом: $data');
          }
          throw Exception('Ошибка: Неверный формат данных');
        }

        final goods = goodsData
            .map((item) => Goods.fromJson(item as Map<String, dynamic>))
            .toList();
        if (kDebugMode) {
          print(
              'ApiService: Успешно получено ${goods.length} товаров по штрихкоду');
        }
        return goods;
      } else {
        if (kDebugMode) {
          print(
              'ApiService: Ошибка формата данных: отсутствует поле result в $data');
        }
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      if (kDebugMode) {
        print(
            'ApiService: Ошибка загрузки товаров по штрихкоду: ${response.statusCode}');
      }
      throw Exception('Ошибка загрузки товаров: ${response.statusCode}');
    }
  }

//_________________________________ END____API_SCREEN__GOODS____________________________________________//

//_________________________________ START_____API_SCREEN__ORDER____________________________________________//

  Future<List<OrderStatus>> getOrderStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order-status');
    if (kDebugMode) {
      //print('ApiService: getOrderStatuses - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          await prefs.setString(
              'cachedOrderStatuses_${await getSelectedOrganization()}',
              json.encode(data['result']));
          return (data['result'] as List)
              .map((status) => OrderStatus.fromJson(status))
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка сервера');
      }
    } catch (e) {
      ////print(
      // 'Ошибка загрузки статусов заказов. Используем кэшированные данные.');
      final cachedStatuses = prefs
          .getString('cachedOrderStatuses_${await getSelectedOrganization()}');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        return (decodedData as List)
            .map((status) => OrderStatus.fromJson(status))
            .toList();
      } else {
        throw Exception(
            'Ошибка загрузки статусов заказов и нет кэшированных данных!');
      }
    }
  }

  Future<OrderResponse> getOrders({
    int page = 1,
    int perPage = 20,
    int? statusId,
    String? query,
    List<String>? managerIds,
    List<String>? leadIds,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? paymentMethod,
  }) async {
    String url = '/order';
    url += '?page=$page&per_page=$perPage';
    if (statusId != null) {
      url += '&order_status_id=$statusId';
    }
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (managerIds != null && managerIds.isNotEmpty) {
      for (int i = 0; i < managerIds.length; i++) {
        url += '&managers[$i]=${managerIds[i]}';
      }
    }
    if (leadIds != null && leadIds.isNotEmpty) {
      for (int i = 0; i < leadIds.length; i++) {
        url += '&leads[$i]=${leadIds[i]}';
      }
    }
    if (fromDate != null) {
      url += '&from=${fromDate.toIso8601String()}';
    }
    if (toDate != null) {
      url += '&to=${toDate.toIso8601String()}';
    }
    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      url += '&payment_type=$paymentMethod';
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      //print('ApiService: getOrders - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        final data = rawData['result'];
        return OrderResponse.fromJson(data);
      } else {
        throw Exception('Ошибка сервера!');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<Order> getOrderDetails(int orderId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order/$orderId');
    if (kDebugMode) {
      //print('ApiService: getOrderDetails - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['result'];
        final order = Order.fromJson(data);
        await prefs.setString('cachedOrder_$orderId', json.encode(data));
        return order;
      } else {
        throw Exception('Ошибка сервера!');
      }
    } catch (e) {
      ////print(
      // 'Ошибка загрузки деталей заказа: . Используем кэшированные данные.');
      final cachedOrder = prefs.getString('cachedOrder_$orderId');
      if (cachedOrder != null) {
        final decodedData = json.decode(cachedOrder);
        return Order.fromJson(decodedData);
      } else {
        throw Exception(
            'Ошибка загрузки деталей заказа и нет кэшированных данных!');
      }
    }
  }

  Future<OrderResponse> getOrdersByLead({
    required int leadId,
    int page = 1,
    int perPage = 20,
  }) async {
    String url = '/lead/get-orders/$leadId?page=$page&per_page=$perPage';

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      //print('ApiService: getOrdersByLead - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (kDebugMode) {
        // //print('Request URL: $path');
        // //print('Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        return OrderResponse.fromJson(rawData);
      } else {
        throw Exception('Ошибка сервера при загрузке заказов!');
      }
    } catch (e) {
      if (kDebugMode) {
        // //print('Ошибка загрузки заказов по лиду: $e');
      }
      throw Exception('Ошибка загрузки заказов:');
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required String phone,
    required int leadId,
    required bool delivery,
    String? deliveryAddress,
    int? deliveryAddressId,
    required List<Map<String, dynamic>> goods,
    required int organizationId,
    required int statusId,
    int? branchId,
    String? commentToCourier,
    int? managerId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order');
      if (kDebugMode) {
        //print('ApiService: createOrder - Generated path: $path');
      }

      final uri = Uri.parse('$baseUrl$path');
      final body = {
        'phone': phone,
        'lead_id': leadId,
        'deliveryType': delivery ? 'delivery' : 'pickup',
        'goods': goods
            .map((item) => {
                  'variant_id': int.parse(item['variant_id'].toString()),
                  'quantity': item['quantity'],
                  'price': item['price'].toString(),
                })
            .toList(),
        'organization_id': organizationId,
        'status_id': statusId,
        'comment_to_courier': commentToCourier,
        'payment_type': 'cash',
        'manager_id': managerId,
      };

      if (delivery) {
        body['delivery_address_id'] = deliveryAddressId;
      } else {
        body['delivery_address_id'] = null;
        if (branchId != null) {
          body['branch_id'] = branchId;
        }
      }

      ////print('ApiService: Тело запроса для создания заказа: ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode(body),
      );

      ////print('ApiService: Код ответа сервера: ${response.statusCode}');
      ////print('ApiService: Тело ответа сервера: ${response.body}');

      if (<int>[200, 201, 202, 203, 204, 300, 301]
          .contains(response.statusCode)) {
        final jsonResponse = jsonDecode(response.body);
        // Проверяем, есть ли в ответе данные заказа
        if (jsonResponse['result'] == 'success') {
          return {
            'success': true,
            'statusId': statusId, // Используем входной statusId
            'order': null, // Данные заказа отсутствуют
          };
        } else if (jsonResponse['result'] is Map<String, dynamic>) {
          // Обработка случая, когда сервер возвращает полный объект
          final returnedStatusId = int.tryParse(
                  jsonResponse['result']['status_id']?.toString() ?? '') ??
              statusId;
          return {
            'success': true,
            'statusId': returnedStatusId,
            'order': jsonResponse['result'],
          };
        } else {
          throw ('Неожиданная структура ответа сервера:');
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw (jsonResponse['message'] ?? 'Ошибка при создании заказа');
      }
    } catch (e) {
      ////print('ApiService: Ошибка создания заказа: ');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateOrder({
    required int orderId,
    required String phone,
    required int leadId,
    required bool delivery,
    String? deliveryAddress,
    int? deliveryAddressId,
    required List<Map<String, dynamic>> goods,
    required int organizationId,
    int? branchId,
    String? commentToCourier,
    int? managerId, // Новое поле
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order/$orderId');
      if (kDebugMode) {
        //print('ApiService: updateOrder - Generated path: $path');
      }

      final uri = Uri.parse('$baseUrl$path');
      final body = {
        'phone': phone,
        'lead_id': leadId,
        'deliveryType': delivery
            ? 'delivery'
            : 'pickup', // Исправлено: delivery=true -> "delivery"
        'goods': goods
            .map((item) => {
                  'variant_id': int.parse(item['variant_id'].toString()),
                  'quantity': item['quantity'],
                  'price': item['price'].toString(),
                })
            .toList(),
        'organization_id': organizationId.toString(),
        'comment_to_courier': commentToCourier,
        'payment_type': 'cash',
        'manager_id': managerId?.toString(),
      };

      if (delivery) {
        body['delivery_address'] = deliveryAddress;
        body['delivery_address_id'] = deliveryAddressId?.toString();
      } else {
        body['delivery_address'] = null;
        body['delivery_address_id'] = null;
        if (branchId != null) {
          body['branch_id'] = branchId.toString();
        }
      }

      ////print('ApiService: Тело запроса для обновления заказа: ${jsonEncode(body)}');

      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode(body),
      );

      ////print('ApiService: Код ответа сервера: ${response.statusCode}');
      ////print('ApiService: Тело ответа сервера: ${response.body}');

      // Обрабатываем коды ответа 200, 201, 202, 203, 204, 300, 301 как успешные
      if (<int>[200, 201, 202, 203, 204, 300, 301]
          .contains(response.statusCode)) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['result'] == 'success') {
          return {
            'success': true,
            'order': null, // Данные заказа отсутствуют
          };
        } else if (jsonResponse['result'] is Map<String, dynamic>) {
          return {
            'success': true,
            'order': jsonResponse['result'],
          };
        } else {
          throw Exception(
              'Неожиданная структура ответа сервера: ${jsonResponse['result']}');
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
            jsonResponse['message'] ?? 'Ошибка при обновлении заказа');
      }
    } catch (e, stackTrace) {
      ////print('ApiService: Ошибка обновления заказа: ');
      ////print('ApiService: StackTrace: $stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<DeliveryAddressResponse> getDeliveryAddresses({
    required int leadId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path =
          await _appendQueryParams('/delivery-address?lead_id=$leadId');
      if (kDebugMode) {
        //print('ApiService: getDeliveryAddresses - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeliveryAddressResponse.fromJson(data);
      } else {
        throw Exception(
            'Ошибка при получении адресов доставки: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при получении адресов доставки: ');
    }
  }

  Future<http.Response> createOrderStatus({
    required String title,
    required String notificationMessage,
    required bool isSuccess,
    required bool isFailed,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order-status');
    if (kDebugMode) {
      //print('ApiService: createOrderStatus - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        'title': title,
        'notification_message': notificationMessage,
        'is_success': isSuccess,
        'is_failed': isFailed,
        'color': '#FFFFF', // Добавляем параметр color
      },
    );
    return response;
  }

  Future<http.Response> updateOrderStatus({
    required int statusId,
    required String title,
    required String notificationMessage,
    required bool isSuccess,
    required bool isFailed,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order-status/$statusId');
    if (kDebugMode) {
      //print('ApiService: updateOrderStatus - Generated path: $path');
    }

    final response = await _patchRequest(
      path,
      {
        'title': title,
        'notification_message': notificationMessage,
        'is_success': isSuccess,
        'is_failed': isFailed,
      },
    );
    return response;
  }

  Future<bool> deleteOrderStatus(int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order-status/$statusId');
    if (kDebugMode) {
      //print('ApiService: deleteOrderStatus - Generated path: $path');
    }

    final response = await _deleteRequest(path);
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> checkIfStatusHasOrders(int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/orders?status_id=$statusId');
    if (kDebugMode) {
      //print('ApiService: checkIfStatusHasOrders - Generated path: $path');
    }

    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] != null && data['data'].isNotEmpty;
    }
    return false;
  }

  Future<bool> deleteOrder({
    required int orderId,
    required int? organizationId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order/$orderId');
      if (kDebugMode) {
        //print('ApiService: deleteOrder - Generated path: $path');
      }

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
            jsonResponse['message'] ?? 'Ошибка при удалении заказа');
      }
    } catch (e) {
      ////print('Ошибка удаления заказа: ');
      return false;
    }
  }

  Future<bool> changeOrderStatus({
    required int orderId,
    required int statusId,
    required int? organizationId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order/changeStatus/$orderId');
      if (kDebugMode) {
        //print('ApiService: changeOrderStatus - Generated path: $path');
      }

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'status_id': statusId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
            jsonResponse['message'] ?? 'Ошибка при смене статуса заказа');
      }
    } catch (e) {
      ////print('Ошибка смены статуса заказа: ');
      return false;
    }
  }

  Future<List<Branch>> getBranches() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/branch');
    if (kDebugMode) {
      //print('ApiService: getBranches - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        List<Branch> branches = List<Branch>.from(
            data['result'].map((branch) => Branch.fromJson(branch)));
        return branches;
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных: ${response.statusCode}');
    }
  }

  Future<List<LeadOrderData>> getLeadOrders() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead');
    if (kDebugMode) {
      //print('ApiService: getLeadOrders - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result') && data['result']['data'] is List) {
        return (data['result']['data'] as List<dynamic>)
            .map((e) => LeadOrderData.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception('Ошибка загрузки LeadOrder: ${response.statusCode}');
    }
  }

  Future<List<CalendarEvent>> getCalendarEventsByMonth(
    int month, {
    String? search,
    List<String>? types,
    List<String>? userIds, // Added parameter for user IDs
  }) async {
    String url = '/calendar/getByMonth?month=$month';

    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }

    if (types != null && types.isNotEmpty) {
      url += types.map((type) => '&type[]=$type').join();
    }

    if (userIds != null && userIds.isNotEmpty) {
      url += userIds
          .map((userId) => '&user_id[]=$userId')
          .join(); // Append user IDs
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      //print('ApiService: getCalendarEventsByMonth - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null && data['result'] is List) {
        return (data['result'] as List)
            .map((item) => CalendarEvent.fromJson(item))
            .toList();
      }
      throw ('Ошибка формата загрузки календаря!');
    } else {
      throw ('Ошибка загрузки календаря!');
    }
  }

//_________________________________ END_____API_SCREEN__ORDER____________________________________________//

//________________________________  START_______API_SCREEN__CALLS____________________________________________//

  Future<Map<String, dynamic>> getAllCalls({
    required int page,
    required int perPage,
    String? searchQuery,
    int? salesFunnelId, // ИЗМЕНЕНО: Добавили параметр для воронки
    Map<String, dynamic>? filters,
  }) async {
    // Формируем базовый путь
    String path = '/calls?page=$page&per_page=$perPage';

    // ИЗМЕНЕНО: Если пользователь выбрал воронку, добавляем sales_funnel_id сразу,
    // чтобы _appendQueryParams не добавил текущую (из-за containsKey).
    if (salesFunnelId != null) {
      path += '&sales_funnel_id=$salesFunnelId';
    }

    // Добавляем search параметр
    if (searchQuery != null && searchQuery.isNotEmpty) {
      path += '&search=${Uri.encodeQueryComponent(searchQuery)}';
    }

    // Обрабатываем фильтры
    if (filters != null) {
      if (filters.containsKey('startDate') && filters['startDate'] != null) {
        path += '&from=${Uri.encodeQueryComponent(filters['startDate'])}';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр to: ${filters['endDate']}');
        }
      }
      if (filters.containsKey('leads') &&
          filters['leads'] is List &&
          (filters['leads'] as List).isNotEmpty) {
        final leadIds = filters['leads'] as List<int>;
        for (var leadId in leadIds) {
          path += '&lead_id[]=$leadId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены lead_id: $leadIds');
        }
      }
      if (filters.containsKey('operators') &&
          filters['operators'] is List &&
          (filters['operators'] as List).isNotEmpty) {
        final operatorIds = filters['operators'] as List<int>;
        for (var operatorId in operatorIds) {
          path += '&operator_id[]=$operatorId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены operator_id: $operatorIds');
        }
      }
      if (filters.containsKey('ratings') &&
          filters['ratings'] is List &&
          (filters['ratings'] as List).isNotEmpty) {
        final ratingIds = filters['ratings'] as List<int>;
        for (var ratingId in ratingIds) {
          path += '&rating[]=$ratingId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id (только если не добавлена выше)
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //print('ApiService: getAllCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //print('ApiService: Response for getAllCalls: $data');
      }
      if (data['result']['data'] != null) {
        final calls = (data['result']['data'] as List)
            .map((json) => CallLogEntry.fromJson(json))
            .toList();
        final pagination = data['result']['pagination'] as Map<String, dynamic>;
        return {
          'calls': calls,
          'pagination': pagination,
        };
      } else {
        throw ('Нет данных о звонках в ответе');
      }
    } else {
      if (kDebugMode) {
        //print('ApiService: Error response body: ${response.body}');
      }
      throw ('Ошибка загрузки звонков');
    }
  }

  Future<Map<String, dynamic>> getIncomingCalls({
    required int page,
    required int perPage,
    String? searchQuery,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/calls?incoming=1&missed=0&page=$page&per_page=$perPage';

    if (searchQuery != null && searchQuery.isNotEmpty) {
      path += '&search=${Uri.encodeQueryComponent(searchQuery)}';
    }

    if (filters != null) {
      if (filters.containsKey('startDate') && filters['startDate'] != null) {
        path += '&from=${Uri.encodeQueryComponent(filters['startDate'])}';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр to: ${filters['endDate']}');
        }
      }
      if (filters.containsKey('leads') &&
          filters['leads'] is List &&
          (filters['leads'] as List).isNotEmpty) {
        final leadIds = filters['leads'] as List<int>;
        for (var leadId in leadIds) {
          path += '&lead_id[]=$leadId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены lead_id: $leadIds');
        }
      }
      if (filters.containsKey('operators') &&
          filters['operators'] is List &&
          (filters['operators'] as List).isNotEmpty) {
        final operatorIds = filters['operators'] as List<int>;
        for (var operatorId in operatorIds) {
          path += '&operator_id[]=$operatorId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены operator_id: $operatorIds');
        }
      }
      if (filters.containsKey('ratings') &&
          filters['ratings'] is List &&
          (filters['ratings'] as List).isNotEmpty) {
        final ratingIds = filters['ratings'] as List<int>;
        for (var ratingId in ratingIds) {
          path += '&rating[]=$ratingId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //print('ApiService: getIncomingCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //print('ApiService: Response for getIncomingCalls: $data');
      }
      if (data['result']['data'] != null) {
        final calls = (data['result']['data'] as List)
            .map((json) => CallLogEntry.fromJson(json))
            .toList();
        final pagination = data['result']['pagination'] as Map<String, dynamic>;
        return {
          'calls': calls,
          'pagination': pagination,
        };
      } else {
        throw ('Нет данных о входящих звонках в ответе');
      }
    } else {
      if (kDebugMode) {
        //print('ApiService: Error response body: ${response.body}');
      }
      throw ('Ошибка загрузки входящих звонков');
    }
  }

  Future<Map<String, dynamic>> getOutgoingCalls({
    required int page,
    required int perPage,
    String? searchQuery,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/calls?incoming=0&missed=0&page=$page&per_page=$perPage';

    if (searchQuery != null && searchQuery.isNotEmpty) {
      path += '&search=${Uri.encodeQueryComponent(searchQuery)}';
    }

    if (filters != null) {
      if (filters.containsKey('startDate') && filters['startDate'] != null) {
        path += '&from=${Uri.encodeQueryComponent(filters['startDate'])}';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр to: ${filters['endDate']}');
        }
      }
      if (filters.containsKey('leads') &&
          filters['leads'] is List &&
          (filters['leads'] as List).isNotEmpty) {
        final leadIds = filters['leads'] as List<int>;
        for (var leadId in leadIds) {
          path += '&lead_id[]=$leadId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены lead_id: $leadIds');
        }
      }
      if (filters.containsKey('operators') &&
          filters['operators'] is List &&
          (filters['operators'] as List).isNotEmpty) {
        final operatorIds = filters['operators'] as List<int>;
        for (var operatorId in operatorIds) {
          path += '&operator_id[]=$operatorId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены operator_id: $operatorIds');
        }
      }
      if (filters.containsKey('ratings') &&
          filters['ratings'] is List &&
          (filters['ratings'] as List).isNotEmpty) {
        final ratingIds = filters['ratings'] as List<int>;
        for (var ratingId in ratingIds) {
          path += '&rating[]=$ratingId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //print('ApiService: getOutgoingCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //print('ApiService: Response for getOutgoingCalls: $data');
      }
      if (data['result']['data'] != null) {
        final calls = (data['result']['data'] as List)
            .map((json) => CallLogEntry.fromJson(json))
            .toList();
        final pagination = data['result']['pagination'] as Map<String, dynamic>;
        return {
          'calls': calls,
          'pagination': pagination,
        };
      } else {
        throw ('Нет данных об исходящих звонках в ответе');
      }
    } else {
      if (kDebugMode) {
        //print('ApiService: Error response body: ${response.body}');
      }
      throw ('Ошибка загрузки исходящих звонков');
    }
  }

  Future<Map<String, dynamic>> getMissedCalls({
    required int page,
    required int perPage,
    String? searchQuery,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/calls?missed=1&page=$page&per_page=$perPage';

    if (searchQuery != null && searchQuery.isNotEmpty) {
      path += '&search=${Uri.encodeQueryComponent(searchQuery)}';
    }

    if (filters != null) {
      if (filters.containsKey('startDate') && filters['startDate'] != null) {
        path += '&from=${Uri.encodeQueryComponent(filters['startDate'])}';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр to: ${filters['endDate']}');
        }
      }
      if (filters.containsKey('leads') &&
          filters['leads'] is List &&
          (filters['leads'] as List).isNotEmpty) {
        final leadIds = filters['leads'] as List<int>;
        for (var leadId in leadIds) {
          path += '&lead_id[]=$leadId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены lead_id: $leadIds');
        }
      }
      if (filters.containsKey('operators') &&
          filters['operators'] is List &&
          (filters['operators'] as List).isNotEmpty) {
        final operatorIds = filters['operators'] as List<int>;
        for (var operatorId in operatorIds) {
          path += '&operator_id[]=$operatorId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены operator_id: $operatorIds');
        }
      }
      if (filters.containsKey('ratings') &&
          filters['ratings'] is List &&
          (filters['ratings'] as List).isNotEmpty) {
        final ratingIds = filters['ratings'] as List<int>;
        for (var ratingId in ratingIds) {
          path += '&rating[]=$ratingId';
        }
        if (kDebugMode) {
          //print('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //print('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //print('ApiService: getMissedCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //print('ApiService: Response for getMissedCalls: $data');
      }
      if (data['result']['data'] != null) {
        final calls = (data['result']['data'] as List)
            .map((json) => CallLogEntry.fromJson(json))
            .toList();
        final pagination = data['result']['pagination'] as Map<String, dynamic>;
        return {
          'calls': calls,
          'pagination': pagination,
        };
      } else {
        throw ('Нет данных о пропущенных звонках в ответе');
      }
    } else {
      if (kDebugMode) {
        //print('ApiService: Error response body: ${response.body}');
      }
      throw ('Ошибка загрузки пропущенных звонков');
    }
  }

  Future<CallById> getCallById({
    required int callId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/calls/$callId');
    if (kDebugMode) {
      //print('ApiService: getCallById - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      //print("API response for getCallById: $data");
      if (data['result'] != null && data['result'] is Map<String, dynamic>) {
        return CallById.fromJson(data['result'] as Map<String, dynamic>);
      } else {
        throw ('Invalid or missing call data in response');
      }
    } else {
      throw ('Failed to load call data');
    }
  }

  Future<CallStatistics> getCallStatistics() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/calls/statistic/get-call-statistics');
    if (kDebugMode) {
      //print('ApiService: getCallStatistics - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['result'] != null && jsonData['result'].isNotEmpty) {
          return CallStatistics.fromJson(jsonData);
        } else {
          throw ('Нет данных статистики звонков в ответе');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера: 500');
      } else {
        throw ('Ошибка загрузки данных статистики звонков');
      }
    } catch (e) {
      throw ('Ошибка получения данных статистики звонков');
    }
  }

  Future<CallAnalytics> getCallAnalytics() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/calls/statistic/get-call-analytics');
    if (kDebugMode) {
      //print('ApiService: getCallAnalytics - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['result'] != null) {
          return CallAnalytics.fromJson(jsonData);
        } else {
          throw ('Нет данных статистики звонков в ответе');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера: 500');
      } else {
        throw ('Ошибка загрузки данных статистики звонков');
      }
    } catch (e) {
      throw ('Ошибка получения данных статистики звонков');
    }
  }

  Future<MonthlyCallStats> getMonthlyCallStats(int operatorId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(
        '/calls/statistic/monthly-stats?operator_id=$operatorId');
    if (kDebugMode) {
      //print('ApiService: getMonthlyCallStats - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['result'] != null && jsonData['result'].isNotEmpty) {
          return MonthlyCallStats.fromJson(jsonData);
        } else {
          throw ('Нет данных месячной статистики звонков в ответе');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера: 500');
      } else {
        throw ('Ошибка загрузки данных месячной статистики звонков');
      }
    } catch (e) {
      throw ('Ошибка получения данных месячной статистики звонков');
    }
  }

  Future<CallSummaryStats> getCallSummaryStats(int operatorId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams(
        '/calls/statistic/summary?operator_id=$operatorId');
    if (kDebugMode) {
      //print('ApiService: getCallSummaryStats - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['result'] != null) {
          return CallSummaryStats.fromJson(jsonData);
        } else {
          throw ('Нет данных сводной статистики звонков в ответе');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера: 500');
      } else {
        throw ('Ошибка загрузки данных сводной статистики звонков: ${response.statusCode}');
      }
    } catch (e) {
      throw ('Ошибка получения данных сводной статистики звонков');
    }
  }

  Future<void> setCallRating({
    required int callId,
    required int rating,
    required int organizationId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/calls/set-rating/$callId');
    if (kDebugMode) {
      //print('ApiService: setCallRating - Generated path: $path');
    }
    final body = {
      'rating': rating,
      'organization_id': organizationId,
    };

    if (kDebugMode) {
      //print("API Request: setCallRating (PUT) with path: $path, body: $body");
    }
    final response = await _putRequest(path, body); // заменили на PUT

    if (response.statusCode != 200) {
      throw ('Ошибка при установке рейтинга');
    }
  }

  Future<void> addCallReport({
    required int callId,
    required String report,
    required int organizationId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/calls/add-report/$callId');
    if (kDebugMode) {
      //print('ApiService: addCallReport - Generated path: $path');
    }
    final body = {
      'report': report,
      'organization_id': organizationId,
    };

    if (kDebugMode) {
      //print("API Request: addCallReport (PUT) with path: $path, body: $body");
    }
    final response = await _putRequest(path, body); // заменили на PUT

    if (response.statusCode != 200) {
      throw ('Ошибка при добавлении замечания');
    }
  }

  Future<OperatorList> getOperators() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/operators');
    if (kDebugMode) {
      //print('ApiService: getOperators - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['result'] != null) {
          return OperatorList.fromJson(jsonData);
        } else {
          throw ('Нет данных операторов в ответе');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера: 500');
      } else {
        throw ('Ошибка загрузки данных операторов');
      }
    } catch (e) {
      throw ('Ошибка получения данных операторов');
    }
  }

//________________________________  END_______API_SCREEN__CALLS____________________________________________//
//________________________________  START_______API_SCREEN__DOCUMENTS____________________________________________//




//______________________________start incoming documents____________________________//
  Future<IncomingResponse> getIncomingDocuments({
    int page = 1,
    int perPage = 20,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/income-documents?page=$page&per_page=$perPage';

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    debugPrint("Фильтры для прихода товаров: $filters");

    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        final dateFrom = filters['date_from'] as DateTime;
        path += '&date_from=${dateFrom.toIso8601String()}';
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        final dateTo = filters['date_to'] as DateTime;
        path += '&date_to=${dateTo.toIso8601String()}';
      }

      if (filters.containsKey('deleted') && filters['deleted'] != null) {
        path += '&deleted=${filters['deleted']}';
      }

      if (filters.containsKey('author_id') && filters['author_id'] != null) {
        path += '&author_id=${filters['author_id']}';
      }

      if (filters.containsKey('approved') && filters['approved'] != null) {
        path += '&approved=${filters['approved']}';
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      print('ApiService: getIncomingDocuments - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body)['result'];
        debugPrint("Полученные данные по приходу товаров: $rawData");
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных прихода товаров!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }



Future<IncomingDocument> getIncomingDocumentById(int documentId) async {
    String url = '/income-documents/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getIncomingDocumentById - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }
  Future<void> approveIncomingDocument(int documentId) async {
    const String url = '/income-documents/approve';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: approveIncomingDocument - Generated path: $path');
    }

    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print(
              'ApiService: approveIncomingDocument - Document $documentId approved successfully');
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при проведении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }



  Future<void> unApproveIncomingDocument(int documentId) async {
    const String url = '/income-documents/unApprove';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: unApproveIncomingDocument - Generated path: $path');
    }

    try {
      final token = await getToken();
      if (token == null) 'Токен не найден';

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print(
              'ApiService: unApproveIncomingDocument - Document $documentId unapproved successfully');
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при отмене проведения документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreIncomingDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final pathWithParams = await _appendQueryParams('/income-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      if (kDebugMode) {
        print('ApiService: restoreIncomingDocument - Request body: $body');
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('ApiService: restoreIncomingDocument - Document $documentId restored successfully');
        }
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при восстановлении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  // todo show 409 errors on every request with ApiException
  Future<IncomingDocumentHistoryResponse> getIncomingDocumentHistory(
      int documentId) async {
    String url = '/income-documents/history/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getIncomingDocumentHistory - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocumentHistoryResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<void> createIncomingDocument({
  required String date,
  required int storageId,
  required String comment,
  required int counterpartyId,
  required List<Map<String, dynamic>> documentGoods,
  required int organizationId,
  required int salesFunnelId,
  bool approve = false, // Новый параметр
}) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/income-documents');
      final uri = Uri.parse('$baseUrl$path');

      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        'approve': approve, // Добавляем новый параметр
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateIncomingDocument({
  required int documentId,
  required String date,
  required int storageId,
  required String comment,
  required int counterpartyId,
  required List<Map<String, dynamic>> documentGoods,
  required int organizationId,
  required int salesFunnelId,
}) async {
  final token = await getToken();
  if (token == null) throw 'Токен не найден';

  final path = await _appendQueryParams('/income-documents/$documentId');
  final uri = Uri.parse('$baseUrl$path');
  final body = jsonEncode({
    'date': date,
    'storage_id': storageId,
    'comment': comment,
    'counterparty_id': counterpartyId,
    'document_goods': documentGoods,
    'organization_id': organizationId,
    'sales_funnel_id': salesFunnelId,
  });

    try {
      final response = await http.put(
        // Используем PATCH для обновления
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
    }
  } catch (e) {
    rethrow;
  }
}
Future<Map<String, dynamic>> deleteIncomingDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
    final pathWithParams = await _appendQueryParams('/income-documents');
    final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      // Создаем чистый URI без параметров для DELETE запроса
    final cleanUri = Uri.parse('$baseUrl/income-documents');

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
      print('ApiService: deleteIncomingDocument - Request body: $body');
    }

      final response = await http.delete(
        cleanUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
      return {'result': 'Success'};
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(message ?? 'Ошибка при удалении документа', response.statusCode);
    }
  } catch (e) {
    rethrow;
  }
}

  Future<void> massApproveIncomingDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/income-documents/approve');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом проведении документов прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDisapproveIncomingDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/income-documents/unApprove');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом снятии проведения документов прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDeleteIncomingDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/income-documents/');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massRestoreIncomingDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/income-documents/restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом восстановлении документов прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

//______________________________end incoming documents____________________________//

//______________________________start client sales____________________________//
  Future<IncomingResponse> getClientSales({
    int page = 1,
    int perPage = 20,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
    int? approved, // Для будущего фильтра по статусу
  }) async {
    String url =
        '/expense-documents'; // Предполагаемый endpoint; подкорректируй если нужно
    url += '?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (fromDate != null) {
      url += '&from=${fromDate.toIso8601String()}';
    }
    if (toDate != null) {
      url += '&to=${toDate.toIso8601String()}';
    }
    if (approved != null) {
      url += '&approved=$approved';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getIncomingDocuments - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result']; // Как в JSON
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }



  Future<IncomingDocument> getClienSalesById(int documentId) async {
    String url = '/expense-documents/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getIncomingDocumentById - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }
//createClientSaleDocument
  Future<void> createClientSaleDocument({
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    required bool approve,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/expense-documents');
      final response = await _postRequest(path, {
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        'approve': approve,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Неизвестная ошибка при создании документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  //deleteClientSaleDocument
  Future<Map<String, dynamic>> deleteClientSaleDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams = await _appendQueryParams('/expense-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      // Создаем чистый URI без параметров для DELETE запроса
      final cleanUri = Uri.parse('$baseUrl/expense-documents');

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
        print('ApiService: deleteClientSaleDocument - Request body: $body');
      }

      final response = await http.delete(
        cleanUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при удалении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

Future<void> updateClientSaleDocument({
  required int documentId,
  required String date,
  required int storageId,
  required String comment,
  required int counterpartyId,
  required List<Map<String, dynamic>> documentGoods,
  required int organizationId,
  required int salesFunnelId,
}) async {
  try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final path = await _appendQueryParams('/expense-documents/$documentId');
      final uri = Uri.parse('$baseUrl$path');

      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
      });

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка обновления документа', response.statusCode);
      }
    } catch (e) {
    rethrow;
  }
  }

// Проведение документа реализации
Future<void> approveClientSaleDocument(int documentId) async {
  const String url = '/expense-documents/approve';
  final path = await _appendQueryParams(url);

  try {
    final token = await getToken();
    if (token == null) throw 'Токен не найден';

    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Device': 'mobile',
      },
      body: jsonEncode({
        'ids': [documentId]
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Успешно проведен
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка при проведении документа',
          response.statusCode
      );
    }
  } catch (e) {
    rethrow;
  }
}

// Отмена проведения документа реализации
Future<void> unApproveClientSaleDocument(int documentId) async {
  const String url = '/expense-documents/unApprove';
  final path = await _appendQueryParams(url);

  try {
    final token = await getToken();
    if (token == null) throw Exception('Токен не найден');

    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Device': 'mobile',
      },
      body: jsonEncode({
        'ids': [documentId]
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Успешно отменено
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(message ?? 'Ошибка при отмене проведения документа', response.statusCode);
    }
  } catch (e) {
    rethrow;
  }
}

// Восстановление документа реализации
Future<Map<String, dynamic>> restoreClientSaleDocument(int documentId) async {
  try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final pathWithParams = await _appendQueryParams('/expense-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при восстановлении документа', response.statusCode);
      }
    } catch (e) {
    rethrow;
  }
  }

  Future<void> massApproveClientSaleDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/expense-documents/approve');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом проведении документов реализации!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDisapproveClientSaleDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/expense-documents/unApprove');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом снятии проведения документов реализации!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDeleteClientSaleDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/expense-documents/');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов реализации!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massRestoreClientSaleDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/expense-documents/restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом восстановлении документов реализации!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }


//______________________________end client sales____________________________//

//----------------------------------------------STORAGE----------------------------------------

  //get storage
  Future<List<WareHouse>> getStorage() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/storage');
    if (kDebugMode) {
      //print('ApiService: getStorage - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////print('Полученные данные складов: $data');

      // Извлекаем массив из поля "result"
      final List<dynamic> resultList = data['result'] ?? [];

      return resultList.map((storage) => WareHouse.fromJson(storage)).toList();
    } else {
      throw Exception('Ошибка загрузки складов');
    }
  }

  //get storage
  Future<List<WareHouse>> getWareHouses() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/storage');
    if (kDebugMode) {
      //print('ApiService: getStorage - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////print('Полученные данные складов: $data');

      // Извлекаем массив из поля "result"
      final List<dynamic> resultList = data['result'] ?? [];

      return resultList.map((storage) => WareHouse.fromJson(storage)).toList();
    } else {
      throw Exception('Ошибка загрузки складов');
    }
  }

  //create storage
  Future<bool> createStorage(
    WareHouse unit,
    List<int> userIds,
  ) async {
    final path = await _appendQueryParams('/storage');
    if (kDebugMode) {
      //print('ApiService: createSupplier - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': unit.name,
      "users": userIds,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _postRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Ошибка создания поставщика: ${response.body}');
    }
  }

  //updateStorage
  Future<PriceTypeModel> updateStorage(
      {required WareHouse storage,
      required int id,
      required List<int> ids}) async {
    final path = await _appendQueryParams('/storage/$id');
    if (kDebugMode) {
      //print('ApiService: updateSupplier - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': storage.name,
      'ids': ids,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _patchRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return PriceTypeModel.fromJson(json.decode(response.body)['result']);
      } else {
        throw Exception('Ошибка обновления поставщика: ${response.body}');
      }
    } else {
      throw Exception('Ошибка обновления поставщика: ${response.body}');
    }
  }

  //delete storage
  Future<void> deleteStorage(int storageId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/storage/$storageId');
    if (kDebugMode) {
      //print('ApiService: deleteSupplier - Generated path: $path');
    }

    final response = await _deleteRequestWithBody(path,
        {"organization_id": organizationId, "sales_funnel_id": salesFunnelId});

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw Exception('Ошибка удаления поставщика: ${response.body}');
    }
  }

//--------------------------------MEASURE UNITS-------------------------------------------------

  //get measure units
  Future<List<MeasureUnitModel>> getMeasureUnits() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/unit');
    if (kDebugMode) {
      //print('ApiService: getSuppliers - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return (json.decode(response.body)['result'] as List)
            .map((unit) => MeasureUnitModel.fromJson(unit))
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Ошибка создания поставщика: ${response.body}');
    }
  }

  //create measure units
  Future<void> createMeasureUnit(
    MeasureUnitModel unit,
  ) async {
    final path = await _appendQueryParams('/unit');
    if (kDebugMode) {
      //print('ApiService: createSupplier - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': unit.name,
      'short_name': unit.shortName,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _postRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      throw Exception('Ошибка создания поставщика: ${response.body}');
    }
  }

  //delete measure units
  Future<void> deleteMeasureUnit(int supplierId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/unit/$supplierId');
    if (kDebugMode) {
      //print('ApiService: deleteSupplier - Generated path: $path');
    }

    final response = await _deleteRequestWithBody(path,
        {"organization_id": organizationId, "sales_funnel_id": salesFunnelId});

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw Exception('Ошибка удаления поставщика: ${response.body}');
    }
  }

  //update measure units
  Future<PriceTypeModel> updateUnit(
      {required MeasureUnitModel supplier, required int id}) async {
    final path = await _appendQueryParams('/unit/$id');
    if (kDebugMode) {
      //print('ApiService: updateSupplier - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': supplier.name,
      'short_name': supplier.shortName,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _patchRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return PriceTypeModel.fromJson(json.decode(response.body)['result']);
      } else {
        throw Exception('Ошибка обновления поставщика: ${response.body}');
      }
    } else {
      throw Exception('Ошибка обновления поставщика: ${response.body}');
    }
  }

//--------------------------PRICE TYPE---------------------------------------------

  Future<List<PriceTypeModel>> getPriceTypes() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/priceType');
    if (kDebugMode) {
      //print('ApiService: getSuppliers - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return (json.decode(response.body)['result']['data'] as List)
            .map((unit) => PriceTypeModel.fromJson(unit))
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Ошибка создания поставщика: ${response.body}');
    }
  }


  Future<void> createPriceType(
    PriceTypeModel unit,
  ) async {
    final path = await _appendQueryParams('/priceType');
    if (kDebugMode) {
      //print('ApiService: createSupplier - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': unit.name,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _postRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      throw Exception('Ошибка создания поставщика: ${response.body}');
    }
  }


  Future<void> deletePriceType(int supplierId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/priceType/$supplierId');
    if (kDebugMode) {
      //print('ApiService: deleteSupplier - Generated path: $path');
    }

    final response = await _deleteRequestWithBody(path,
        {"organization_id": organizationId, "sales_funnel_id": salesFunnelId});

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw Exception('Ошибка удаления поставщика: ${response.body}');
    }
  }


  Future<PriceTypeModel> updatePriceType(
      {required PriceTypeModel supplier, required int id}) async {
    final path = await _appendQueryParams('/priceType/$id');
    if (kDebugMode) {
      //print('ApiService: updateSupplier - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': supplier.name,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _patchRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return PriceTypeModel.fromJson(json.decode(response.body)['result']);
      } else {
        throw Exception('Ошибка обновления поставщика: ${response.body}');
      }
    } else {
      throw Exception('Ошибка обновления поставщика: ${response.body}');
    }
  }

//----------------------------------------------SUPPLIER----------------------------------
  //createSupplier
  Future<Supplier> createSupplier(
      Supplier supplier,
      String organizationId, String salesFunnelId) async {
    final path = await _appendQueryParams('/suppliers');
    if (kDebugMode) {
      //print('ApiService: createSupplier - Generated path: $path');
    }

    final body = {
      'name': supplier.name,
      'phone': supplier.phone,
      "note": supplier.note,
      "inn": supplier.inn,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _postRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return Supplier.fromJson(json.decode(response.body)['result']);
      } else {
        throw Exception('Ошибка создания поставщика: ${response.body}');
      }
    } else {
      throw Exception('Ошибка создания поставщика: ${response.body}');
    }
  }

  //updateSupplier
  Future<PriceTypeModel> updateSupplier(
      {required Supplier supplier, required int id}) async {
    final path = await _appendQueryParams('/suppliers/$id');
    if (kDebugMode) {
      //print('ApiService: updateSupplier - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': supplier.name,
      'phone': supplier.phone,
      if (supplier.note != null) 'note': supplier.note,
      if (supplier.inn != null) 'inn': supplier.inn,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _patchRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return PriceTypeModel.fromJson(json.decode(response.body)['result']);
      } else {
        throw Exception('Ошибка обновления поставщика: ${response.body}');
      }
    } else {
      throw Exception('Ошибка обновления поставщика: ${response.body}');
    }
  }

  //deleteSupplier
  Future<void> deleteSupplier(int supplierId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/suppliers/$supplierId');
    if (kDebugMode) {
      //print('ApiService: deleteSupplier - Generated path: $path');
    }

    final response = await _deleteRequestWithBody(path,
        {"organization_id": organizationId, "sales_funnel_id": salesFunnelId});

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw Exception('Ошибка удаления поставщика: ${response.body}');
    }
  }

  //getSuppliers
  Future<List<Supplier>> getSuppliers() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/suppliers');
    if (kDebugMode) {
      //print('ApiService: getSuppliers - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return (json.decode(response.body)['result']["data"] as List)
            .map((supplier) => Supplier.fromJson(supplier))
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Ошибка создания поставщика: ${response.body}');
    }
  }

  //getSupplier
  Future<List<Supplier>> getSupplier() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/suppliers');
    if (kDebugMode) {
      //print('ApiService: getSupplier - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////print('Полученные данные поставщиков: $data');

      // Извлекаем массив из поля "result"
      final List<dynamic> resultList = data['result']["data"] ?? [];

      return resultList
          .map((supplier) => Supplier.fromJson(supplier))
          .toList();
    } else {
      throw Exception('Ошибка загрузки поставщиков');
    }
  }

  //updateSupplier
  // Future<List<Supplier>> updateSupplier(){};







  Future<CashRegisterResponseModel> getCashRegister({
    int page = 1,
    int perPage = 15,
    String? query,
  }) async {
    String url = '/cashRegister?page=$page&per_page=$perPage';

    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getCashRegister - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          return CashRegisterResponseModel.fromJson(data['result']);
        } else {
          throw Exception('Нет данных по кассе');
        }
      } else {
        final data = json.decode(response.body);
        if (data['errors'] != null) {
          throw Exception(data['errors'] ?? 'Ошибка загрузки кассы');
        } else {
          throw Exception('Ошибка загрузки кассы: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Ошибка получения данных кассы: $e');
    }
  }

  Future<CashRegisterModel> postCashRegister(AddCashDeskModel value) async {
    final response = await _postRequest('/cashRegister', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return CashRegisterModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка добавления в кассу');
      } else {
        throw Exception('Ошибка добавления в кассу: ${response.body}');
      }
    }
  }

  Future<bool> deleteCashRegister(int id) async {
    final response = await _deleteRequest('/cashRegister/$id');
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      return data['result']['deleted'] as bool;
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка удаления кассы');
      } else {
        throw Exception('Ошибка удаления кассы: ${response.body}');
      }
    }
  }

  Future<CashRegisterModel> patchCashRegister(int id, AddCashDeskModel value) async {
    final response = await _patchRequest('/cashRegister/$id', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return CashRegisterModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка добавления в кассу');
      } else {
        throw Exception('Ошибка добавления в кассу: ${response.body}');
      }
    }
  }

  // Expense API methods
  Future<ExpenseResponseModel> getExpenses({
    int page = 1,
    int perPage = 15,
    String? query,
  }) async {
    String url = '/article?type=expense&page=$page&per_page=$perPage';

    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getExpenses - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          return ExpenseResponseModel.fromJson(data['result']);
        } else {
          throw Exception('Нет данных по расходам');
        }
      } else {
        final data = json.decode(response.body);
        if (data['errors'] != null) {
          throw Exception(data['errors'] ?? 'Ошибка загрузки расходов');
        } else {
          throw Exception('Ошибка загрузки расходов: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Ошибка получения данных расходов: $e');
    }
  }

  Future<ExpenseModel> postExpense(AddExpenseModel value) async {
    final response = await _postRequest('/article', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return ExpenseModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка добавления расхода');
      } else {
        throw Exception('Ошибка добавления расхода: ${response.body}');
      }
    }
  }

  Future<bool> deleteExpense(int id) async {
    final response = await _deleteRequest('/article/$id');
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      return data['result']['deleted'] as bool;
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка удаления расхода');
      } else {
        throw Exception('Ошибка удаления расхода: ${response.body}');
      }
    }
  }

  Future<ExpenseModel> patchExpense(int id, AddExpenseModel value) async {
    final response = await _patchRequest('/article/$id', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return ExpenseModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка обновления расхода');
      } else {
        throw Exception('Ошибка обновления расхода: ${response.body}');
      }
    }
  }

  // Income API methods
  Future<IncomeResponseModel> getIncomes({
    int page = 1,
    int perPage = 15,
    String? query,
  }) async {
    String url = '/article?type=income&page=$page&per_page=$perPage';

    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getIncomes - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          return IncomeResponseModel.fromJson(data['result']);
        } else {
          throw Exception('Нет данных по доходам');
        }
      } else {
        final data = json.decode(response.body);
        if (data['errors'] != null) {
          throw Exception(data['errors'] ?? 'Ошибка загрузки доходов');
        } else {
          throw Exception('Ошибка загрузки доходов: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Ошибка получения данных доходов: $e');
    }
  }

  Future<IncomeModel> postIncome(AddIncomeModel value) async {
    final response = await _postRequest('/article', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return IncomeModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка добавления дохода');
      } else {
        throw Exception('Ошибка добавления дохода: ${response.body}');
      }
    }
  }

  Future<bool> deleteIncome(int id) async {
    final response = await _deleteRequest('/article/$id');
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      return data['result']['deleted'] as bool;
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка удаления дохода');
      } else {
        throw Exception('Ошибка удаления дохода: ${response.body}');
      }
    }
  }

  Future<IncomeModel> patchIncome(int id, AddIncomeModel value) async {
    final response = await _patchRequest('/article/$id', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return IncomeModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка обновления дохода');
      } else {
        throw Exception('Ошибка обновления дохода: ${response.body}');
      }
    }
  }




  //______________________________start supplier return documents____________________________//
  Future<IncomingResponse> getSupplierReturnDocuments({
    int page = 1,
    int perPage = 20,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
    int? approved, // Для будущего фильтра по статусу
  }) async {
    String url =
        '/supplier-return-documents'; // Замена endpoint'а
    url += '?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (fromDate != null) {
      url += '&from=${fromDate.toIso8601String()}';
    }
    if (toDate != null) {
      url += '&to=${toDate.toIso8601String()}';
    }
    if (approved != null) {
      url += '&approved=$approved';
    }

    final path = await _appendQueryParams(url);

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result']; // Как в JSON
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка получения данных возврата поставщику',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocument> getSupplierReturnDocumentById(int documentId) async {
    try {
      String url = '/supplier-return-documents/$documentId';

      final path = await _appendQueryParams(url);
      if (kDebugMode) {
        print('ApiService: getSupplierReturnDocumentById - Generated path: $path');
      }

      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка получения данных документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveSupplierReturnDocument(int documentId) async {
    const String url = '/supplier-return-documents/approve';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: approveSupplierReturnDocument - Generated path: $path');
    }

    try {
      final response = await _postRequest(path, {
        'ids': [documentId]
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при проведении документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unApproveSupplierReturnDocument(int documentId) async {
    const String url = '/supplier-return-documents/unApprove';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: unApproveSupplierReturnDocument - Generated path: $path');
    }

    try {
      final response = await _postRequest(path, {
        'ids': [documentId]
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при отмене проведения документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // TODO remove if is not used anywhere
  Future<IncomingDocumentHistoryResponse> getSupplierReturnDocumentHistory(
      int documentId) async {
    String url = '/supplier-return-documents/history/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getSupplierReturnDocumentHistory - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocumentHistoryResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? "Ошибка получения истории документа", response.statusCode);
      }
    } catch (e) {
     rethrow;
    }
  }

  Future<void> createSupplierReturnDocument({
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    required bool approve,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/supplier-return-documents');
      final uri = Uri.parse('$baseUrl$path');
      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        'approve': approve,
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? "Ошибка создании документа", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSupplierReturnDocument({
    required int documentId,
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/supplier-return-documents/$documentId');
      final uri = Uri.parse('$baseUrl$path');
      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
      });

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? "Ошибка обновления документа", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteSupplierReturnDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams = await _appendQueryParams('/supplier-return-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      // Создаем чистый URI без параметров для DELETE запроса
      final cleanUri = Uri.parse('$baseUrl/supplier-return-documents');

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
        print('ApiService: deleteSupplierReturnDocument - Request body: $body');
      }

      final response = await http.delete(
        cleanUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? "Ошибка удалении документа", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreSupplierReturnDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final pathWithParams = await _appendQueryParams('/supplier-return-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      if (kDebugMode) {
        print('ApiService: restoreSupplierReturnDocument - Request body: $body');
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('ApiService: restoreSupplierReturnDocument - Document $documentId restored successfully');
        }
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при восстановлении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

//______________________________end supplier return documents____________________________//

//______________________________start cash register and suppliers____________________________//

  //Метод для получения cash register
  Future<CashRegistersDataResponse> getAllCashRegisters() async {
    final path = await _appendQueryParams('/cashRegister');

    final response = await _getRequest(path);

    late CashRegistersDataResponse cashRegistersData;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        cashRegistersData = CashRegistersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    return cashRegistersData;
  }

  //Метод для получения suppliers
  Future<SuppliersDataResponse> getAllSuppliers() async {
    final path = await _appendQueryParams('/suppliers');

    final response = await _getRequest(path);

    late SuppliersDataResponse cashRegistersData;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        cashRegistersData = SuppliersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    return cashRegistersData;
  }

  //______________________________STARTED: MONEY INCOME APIS____________________________//

  //Метод для получения income categories
  Future<IncomeCategoriesDataResponse> getAllIncomeCategories() async {
    final path = await _appendQueryParams('/article?type=income');

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          return IncomeCategoriesDataResponse.fromJson(data);
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка при получении данных прихода!',
            response.statusCode,
          );
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw message ?? 'Ошибка при получении данных!';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createMoneyIncomeDocument({required String date,
    required num amount,
    required String operationType,
    required String movementType,
    String? comment,
    int? leadId,
    int? articleId,
    int? senderCashRegisterId,
    int? cashRegisterId,
    int? supplierId,
    required bool approve,
  }) async {
    final path = await _appendQueryParams('/checking-account');

    try {
      final response = await _postRequest(path, {
        'date': date,
        'amount': amount,
        'operation_type': operationType,
        'movement_type': movementType,
        'lead_id': leadId,
        'article_id': articleId,
        'sender_cash_register_id': senderCashRegisterId,
        'comment': comment,
        'cash_register_id': cashRegisterId,
        'supplier_id': supplierId,
        'approved': approve,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при создании документа прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
     rethrow;
    }
  }

  Future<MoneyIncomeDocumentModel> getMoneyIncomeDocuments({
    int page = 1,
    int perPage = 20,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/checking-account?type=PKO&page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    debugPrint("Фильтры для прихода: $filters");

    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        final dateFrom = filters['date_from'] as DateTime;
        path += '&date_from=${dateFrom.toIso8601String()}';
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        final dateTo = filters['date_to'] as DateTime;
        path += "&date_to=${dateTo.toIso8601String()}";
      }

      if (filters.containsKey('deleted') && filters['deleted'] != null) {
        path += '&deleted=${filters['deleted']}';
      }

      if (filters.containsKey('lead_id') && filters['lead_id'] != null) {
        path += '&lead_id=${filters['lead_id']}';
      }

      if (filters.containsKey('cash_register_id') && filters['cash_register_id'] != null) {
        path += '&cash_register_id=${filters['cash_register_id']}';
      }

      if (filters.containsKey('supplier_id') && filters['supplier_id'] != null) {
        path += '&supplier_id=${filters['supplier_id']}';
      }

      if (filters.containsKey('author_id') && filters['author_id'] != null) {
        path += '&author_id=${filters['author_id']}';
      }

      if (filters.containsKey('approved') && filters['approved'] != null) {
        path += '&approved=${filters['approved']}';
      }
    }

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      path = await _appendQueryParams(path);
      if (kDebugMode) {
        print('ApiService: getMoneyIncomeDocuments - Generated path: $path');
      }

      try {
        final response = await _getRequest(path);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final rawData = json.decode(response.body);
          debugPrint("Полученные данные по приходу: $rawData");
          return MoneyIncomeDocumentModel.fromJson(rawData);
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка при получении данных прихода!',
            response.statusCode,
          );
        }
      } catch (e) {
        rethrow;
      }
    }

  Future<bool> deleteMoneyIncomeDocument(int documentId) async {
    final path = await _appendQueryParams('/checking-account/mass-delete');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': [documentId],
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при удалении документа прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Future<Map<String, dynamic>> restoreMoneyIncomeDocument(
  //     int documentId) async {
  //   final token = await getToken();
  //   if (token == null) throw Exception('Токен не найден');
  //
  //   final pathWithParams = await _appendQueryParams('/checking-account/restore');
  //   final uri = Uri.parse('$baseUrl$pathWithParams');
  //
  //   final body = jsonEncode({
  //     'ids': [documentId],
  //   });
  //
  //   final response = await http.post(
  //     uri,
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Accept': 'application/json',
  //       'Content-Type': 'application/json',
  //       'Device': 'mobile',
  //     },
  //     body: body,
  //   );
  //
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     return {'result': 'Success'};
  //   } else {
  //     final jsonResponse = jsonDecode(response.body);
  //     throw Exception(
  //         jsonResponse['message'] ?? 'Ошибка при восстановлении документа');
  //   }
  // }

  Future<void> updateMoneyIncomeDocument({
    required int documentId,
    required String date,
    required num amount,
    required String operationType,
    required String movementType,
    String? comment,
    int? leadId,
    int? articleId,
    int? senderCashRegisterId,
    int? cashRegisterId,
    int? supplierId,
  }) async {
    final path = await _appendQueryParams('/checking-account/$documentId');

    try {
      final response = await _patchRequest(path, {
        'date': date,
        'amount': amount,
        'operation_type': operationType,
        'movement_type': movementType,
        'lead_id': leadId,
        'article_id': articleId,
        'sender_cash_register_id': senderCashRegisterId,
        'comment': comment,
        'cash_register_id': cashRegisterId,
        'supplier_id': supplierId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        debugPrint("Полученные данные по обновлению прихода: $rawData");
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при обновлении документа прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Ошибка при обновлении документа прихода: $e");
      rethrow;
    }
  }

  Future<void> masApproveMoneyIncomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-approve');

    try {
      final response = await _patchRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов прихода!',
          response.statusCode,
        );
      }
    }  catch (e) {
      rethrow;
    }
  }

  Future<void> toggleApproveOneMoneyIncomeDocument(int id, bool approve) async {
    final path = approve
        ? await _appendQueryParams('/checking-account/mass-approve')
        : await _appendQueryParams('/checking-account/mass-unapprove');

    try {
      final response = await _patchRequest(path, {
        'ids': [id],
      });

      if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 201) {
       final message = _extractErrorMessageFromResponse(response);
       throw ApiException(
         message ?? 'Ошибка при изменении статуса документа прихода!',
         response.statusCode,
       );
      }

     return;

    } catch (e) {
      rethrow;
    }
  }

  Future<void> masDisapproveMoneyIncomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-unapprove');

    try {
      final response = await _patchRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом снятии проведения документов прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> masDeleteMoneyIncomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-delete');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> masRestoreMoneyIncomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом восстановлении документов прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================= END: MONEY INCOME API METHODS ============================= //

  // ============================= STARTED: MONEY OUTCOME API METHODS ============================= //

  //Метод для получения outcome categories
  Future<OutcomeCategoriesDataResponse> getAllOutcomeCategories() async {
    final path = await _appendQueryParams('/article?type=expense');

    final response = await _getRequest(path);;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return OutcomeCategoriesDataResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw message ?? 'Ошибка при получении данных!';
      }
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw message ?? 'Ошибка при получении данных!';
    }
  }

  Future<void> createMoneyOutcomeDocument({required String date,
    required num amount,
    required String operationType,
    required String movementType,
    String? comment,
    int? leadId,
    int? articleId,
    int? senderCashRegisterId,
    int? cashRegisterId,
    int? supplierId,
    required bool approve,
  }) async {
    final path = await _appendQueryParams('/checking-account');

    try {
      final response = await _postRequest(path, {
        'date': date,
        'amount': amount,
        'operation_type': operationType,
        'movement_type': movementType,
        'lead_id': leadId,
        'article_id': articleId,
        'sender_cash_register_id': senderCashRegisterId,
        'comment': comment,
        'cash_register_id': cashRegisterId,
        'supplier_id': supplierId,
        'approved': approve,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при создании документа расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MoneyOutcomeDocumentModel> getMoneyOutcomeDocuments({
    int page = 1,
    int perPage = 20,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/checking-account?type=RKO&page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    debugPrint("Фильтры для расхода: $filters");

    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        final dateFrom = filters['date_from'] as DateTime;
        path += '&date_from=${dateFrom.toIso8601String()}';
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        final dateTo = filters['date_to'] as DateTime;
        path += "&date_to=${dateTo.toIso8601String()}";
      }

      if (filters.containsKey('deleted') && filters['deleted'] != null) {
        path += '&deleted=${filters['deleted']}';
      }

      if (filters.containsKey('lead_id') && filters['lead_id'] != null) {
        path += '&lead_id=${filters['lead_id']}';
      }

      if (filters.containsKey('cash_register_id') && filters['cash_register_id'] != null) {
        path += '&cash_register_id=${filters['cash_register_id']}';
      }

      if (filters.containsKey('supplier_id') && filters['supplier_id'] != null) {
        path += '&supplier_id=${filters['supplier_id']}';
      }

      if (filters.containsKey('author_id') && filters['author_id'] != null) {
        path += '&author_id=${filters['author_id']}';
      }

      if (filters.containsKey('approved') && filters['approved'] != null) {
        path += '&approved=${filters['approved']}';
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      print('ApiService: getMoneyOutcomeDocuments - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        debugPrint("Полученные данные по расход: $rawData");
        return MoneyOutcomeDocumentModel.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteMoneyOutcomeDocument(int documentId) async {
    final path = await _appendQueryParams('/checking-account/mass-delete');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': [documentId],
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при удалении документа расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Future<Map<String, dynamic>> restoreMoneyOutcomeDocument(
  //     int documentId) async {
  //   final token = await getToken();
  //   if (token == null) throw Exception('Токен не найден');
  //
  //   final pathWithParams = await _appendQueryParams('/checking-account/restore');
  //   final uri = Uri.parse('$baseUrl$pathWithParams');
  //
  //   final body = jsonEncode({
  //     'ids': [documentId],
  //   });
  //
  //   final response = await http.post(
  //     uri,
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Accept': 'application/json',
  //       'Content-Type': 'application/json',
  //       'Device': 'mobile',
  //     },
  //     body: body,
  //   );
  //
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     return {'result': 'Success'};
  //   } else {
  //     final jsonResponse = jsonDecode(response.body);
  //     throw Exception(
  //         jsonResponse['message'] ?? 'Ошибка при восстановлении документа');
  //   }
  // }

  Future<void> updateMoneyOutcomeDocument({
    required int documentId,
    required String date,
    required num amount,
    required String operationType,
    required String movementType,
    String? comment,
    int? leadId,
    int? articleId,
    int? senderCashRegisterId,
    int? cashRegisterId,
    int? supplierId,
  }) async {
    final path = await _appendQueryParams('/checking-account/$documentId');

    try {
      final response = await _patchRequest(path, {
        'date': date,
        'amount': amount,
        'operation_type': operationType,
        'movement_type': movementType,
        'lead_id': leadId,
        'article_id': articleId,
        'sender_cash_register_id': senderCashRegisterId,
        'comment': comment,
        'cash_register_id': cashRegisterId,
        'supplier_id': supplierId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        debugPrint("Полученные данные по обновлению расхода: $rawData");
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при обновлении документа расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Ошибка при обновлении документа расхода: $e");
      rethrow;
    }
  }

  Future<void> masApproveMoneyOutcomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-approve');

    try {
      final response = await _patchRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов расхода!',
          response.statusCode,
        );
      }
    }  catch (e) {
      rethrow;
    }
  }

  Future<void> toggleApproveOneMoneyOutcomeDocument(int id, bool approve) async {
    final path = approve
        ? await _appendQueryParams('/checking-account/mass-approve')
        : await _appendQueryParams('/checking-account/mass-unapprove');

    try {
      final response = await _patchRequest(path, {
        'ids': [id],
      });

      if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 201) {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при изменении статуса документа расхода!',
          response.statusCode,
        );
      }

      return;

    } catch (e) {
      rethrow;
    }
  }

  Future<void> masDisapproveMoneyOutcomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-unapprove');

    try {
      final response = await _patchRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом снятии проведения документов расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> masDeleteMoneyOutcomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-delete');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> masRestoreMoneyOutcomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом восстановлении документов расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================= END MONEY OUTCOME API METHODS ============================= //

//_______________________________end cash register and suppliers____________________________//

//______________________________start client return____________________________//
  Future<IncomingResponse> getClientReturns({
    int page = 1,
    int perPage = 20,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
    int? approved, // Для будущего фильтра по статусу
  }) async {
    String url = '/client-return-documents'; // Заменили endpoint
    url += '?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (fromDate != null) {
      url += '&from=${fromDate.toIso8601String()}';
    }
    if (toDate != null) {
      url += '&to=${toDate.toIso8601String()}';
    }
    if (approved != null) {
      url += '&approved=$approved';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getClientReturns - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result']; // Как в JSON
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных возврата!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocument> getClientReturnById(int documentId) async {
    try {
      String url = '/client-return-documents/$documentId';

      final path = await _appendQueryParams(url);
      if (kDebugMode) {
        print('ApiService: getClientReturnById - Generated path: $path');
      }

      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных возврата!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  //createClientReturnDocument
  Future<void> createClientReturnDocument({
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    required bool approve,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/client-return-documents');

      final response = await _postRequest(path, {
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        'approve': approve,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных возврата!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  //deleteClientReturnDocument
  Future<Map<String, dynamic>> deleteClientReturnDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams = await _appendQueryParams('/client-return-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
        print('ApiService: deleteClientReturnDocument - Request body: $body');
        print('ApiService: deleteClientReturnDocument - Request params: $pathWithParams');
      }

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при удалении документа возврата от клиента', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateClientReturnDocument({
    required int documentId,
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/client-return-documents/$documentId');
      final uri = Uri.parse('$baseUrl$path');

      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
      });

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при обновлении документа возврата!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Проведение документа возврата
  Future<void> approveClientReturnDocument(int documentId) async {
    const String url = '/client-return-documents/approve';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно проведен
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при проведении документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Отмена проведения документа возврата
  Future<void> unApproveClientReturnDocument(int documentId) async {
    const String url = '/client-return-documents/unApprove';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно отменено
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при отмене проведения документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
  Future<void> massApproveClientReturnDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/client-return-documents/approve');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом проведении документов возврата от клиента!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDisapproveClientReturnDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/client-return-documents/unApprove');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом снятии проведения документов возврата от клиента!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDeleteClientReturnDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/client-return-documents/');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов возврата от клиента!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massRestoreClientReturnDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/client-return-documents/restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом восстановлении документов возврата от клиента!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Восстановление документа возврата
  Future<Map<String, dynamic>> restoreClientReturnDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final pathWithParams = await _appendQueryParams('/client-return-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при восстановлении документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

//______________________________end client return____________________________//

//______________________________start write-off____________________________//
  Future<IncomingResponse> getWriteOffDocuments({
    int page = 1,
    int perPage = 20,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/write-off-documents?page=$page&per_page=$perPage';

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    debugPrint("Фильтры для списания товаров: $filters");

    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        final dateFrom = filters['date_from'] as DateTime;
        path += '&date_from=${dateFrom.toIso8601String()}';
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        final dateTo = filters['date_to'] as DateTime;
        path += '&date_to=${dateTo.toIso8601String()}';
      }

      if (filters.containsKey('deleted') && filters['deleted'] != null) {
        path += '&deleted=${filters['deleted']}';
      }

      if (filters.containsKey('author_id') && filters['author_id'] != null) {
        path += '&author_id=${filters['author_id']}';
      }

      if (filters.containsKey('approved') && filters['approved'] != null) {
        path += '&approved=${filters['approved']}';
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      print('ApiService: getWriteOffDocuments - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body)['result'];
        debugPrint("Полученные данные по списанию товаров: $rawData");
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных документа списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocument> getWriteOffDocumentById(int documentId) async {
    String url = '/write-off-documents/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getWriteOffDocumentById - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при получении данных документа списания!', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  //createWriteOffDocument
  Future<void> createWriteOffDocument({
    required String date,
    required int storageId,
    required String comment,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required bool approve,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/write-off-documents');
      final response = await _postRequest(path, {
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'approve': approve,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при создании документа списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  //deleteWriteOffDocument
  Future<Map<String, dynamic>> deleteWriteOffDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams = await _appendQueryParams('/write-off-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      // Создаем чистый URI без параметров для DELETE запроса
      final cleanUri = Uri.parse('$baseUrl/write-off-documents');

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
        print('ApiService: deleteWriteOffDocument - Request body: $body');
      }

      final response = await http.delete(
        cleanUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при удалении документа списания', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateWriteOffDocument({
    required int documentId,
    required String date,
    required int storageId,
    required String comment,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final path = await _appendQueryParams('/write-off-documents/$documentId');
      final uri = Uri.parse('$baseUrl$path');

      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'document_goods': documentGoods,
        'organization_id': organizationId,
      });

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при обновлении документа списания!', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Проведение документа списания
  Future<void> approveWriteOffDocument(int documentId) async {
    const String url = '/write-off-documents/approve';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) 'Токен не найден';

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно проведен
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при проведении документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Отмена проведения документа списания
  Future<void> unApproveWriteOffDocument(int documentId) async {
    const String url = '/write-off-documents/unApprove';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно отменено
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при отмене проведения документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Восстановление документа списания
  Future<Map<String, dynamic>> restoreWriteOffDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) 'Токен не найден';

      final pathWithParams = await _appendQueryParams('/write-off-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при восстановлении документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massApproveWriteOffDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/write-off-documents/approve');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом проведении документов списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDisapproveWriteOffDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/write-off-documents/unApprove');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом снятии проведения документов списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDeleteWriteOffDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/write-off-documents/');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massRestoreWriteOffDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/write-off-documents/restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом восстановлении документов списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

//______________________________end write-off____________________________//

//______________________________start movement____________________________//
  Future<IncomingResponse> getMovementDocuments({
    int page = 1,
    int perPage = 20,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
    int? approved, // Для будущего фильтра по статусу
  }) async {
    String url =
        '/movement-documents'; // Изменено с write-off-documents на movement-documents
    url += '?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (fromDate != null) {
      url += '&from=${fromDate.toIso8601String()}';
    }
    if (toDate != null) {
      url += '&to=${toDate.toIso8601String()}';
    }
    if (approved != null) {
      url += '&approved=$approved';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getMovementDocuments - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocument> getMovementDocumentById(int documentId) async {
    String url = '/movement-documents/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      print('ApiService: getMovementDocumentById - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  //createMovementDocument
  Future<void> createMovementDocument({
    required String date,
    required int senderStorageId,
    required int recipientStorageId,
    required String comment,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required bool approve,
  }) async {
    final token = await getToken();
    if (token == null) throw 'Токен не найден';

    final path = await _appendQueryParams('/movement-documents');
    final response = await _postRequest(path, {
      'date': date,
      'sender_storage_id': senderStorageId,
      'recipient_storage_id': recipientStorageId,
      'comment': comment,
      'document_goods': documentGoods,
      'organization_id': organizationId,
      'approve': approve,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(message ?? 'Неизвестная ошибка', response.statusCode);
    }
  }

  //deleteMovementDocument
  Future<Map<String, dynamic>> deleteMovementDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams = await _appendQueryParams('/movement-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      // Создаем чистый URI без параметров для DELETE запроса
      final cleanUri = Uri.parse('$baseUrl/movement-documents');

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
        print('ApiService: deleteMovementDocument - Request body: $body');
      }

      final response = await http.delete(
        cleanUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при удалении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMovementDocument({
    required int documentId,
    required String date,
    required int senderStorageId,
    required int recipientStorageId,
    required String comment,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required bool approve,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final path = await _appendQueryParams('/movement-documents/$documentId');
      final uri = Uri.parse('$baseUrl$path');

      final body = jsonEncode({
        'date': date,
        'sender_storage_id': senderStorageId,
        'recipient_storage_id': recipientStorageId,
        'comment': comment,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'approve': approve,
      });

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка обновления документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Проведение документа перемещения
  Future<void> approveMovementDocument(int documentId) async {
    const String url = '/movement-documents/approve';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно проведен
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при проведении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Отмена проведения документа перемещения
  Future<void> unApproveMovementDocument(int documentId) async {
    const String url = '/movement-documents/unApprove';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно отменено
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при отмене проведения документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Восстановление документа перемещения
  Future<Map<String, dynamic>> restoreMovementDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final pathWithParams = await _appendQueryParams('/movement-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при восстановлении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massApproveMovementDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/movement-documents/approve');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом проведении документов перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDisapproveMovementDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/movement-documents/unApprove');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом снятии проведения документов перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDeleteMovementDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/movement-documents/');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massRestoreMovementDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/movement-documents/restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом восстановлении документов перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }


//______________________________end movement____________________________//

//====================================== SALES DASHBOARD ==================================//

  Future<ResultDashboardGoodsReport> getSalesDashboardGoodsReport({
    int page = 1,
    int perPage = 20,
  }) async {
    String path = '/dashboard/goods-report?page=$page&per_page=$perPage';

    path = await _appendQueryParams(path);
    if (kDebugMode) {
      print('ApiService: getSalesDashboardGoodsReport - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        debugPrint("Полученные данные по отчёту товаров: $rawData");

        // Extract the 'result' object from the response
        final resultData = rawData['result'] as Map<String, dynamic>;
        return ResultDashboardGoodsReport.fromJson(resultData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных отчёта товаров!',
          response.statusCode,
        );
      }
    } catch (e) {
      // todo rethrow
      throw e;
    }
  }

  Future<List<BatchData>> getBatchRemainders({
    required int goodVariantId,
    required int storageId,
    required int supplierId,
  }) async {
    String path = '/supplier-return-documents/get/good-variant-batch-remainders'
        '?good_variant_id=$goodVariantId'
        '&storage_id=$storageId'
        '&supplier_id=$supplierId';

    path = await _appendQueryParams(path);
    if (kDebugMode) {
      print('ApiService: getBatchRemainders - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        debugPrint("Полученные данные по остаткам партий: $rawData");

        final resultData = rawData['result'] as List<dynamic>;
        return resultData
            .map((item) => BatchData.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных остатков партий!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получение списка должников
  Future<DebtorsResponse> getDebtorsList({
    String? from,
    String? to,
    int? cashRegisterId,
    int? supplierId,
    int? clientId,
    int? leadId,
    String? operationType,
    String? search,
  }) async {
    try {
      // Формируем параметры запроса
      Map<String, String> queryParams = {};

      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;
      if (cashRegisterId != null) queryParams['cash_register_id'] = cashRegisterId.toString();
      if (supplierId != null) queryParams['supplier_id'] = supplierId.toString();
      if (clientId != null) queryParams['client_id'] = clientId.toString();
      if (leadId != null) queryParams['lead_id'] = leadId.toString();
      if (operationType != null) queryParams['operation_type'] = operationType;
      if (search != null) queryParams['search'] = search;

      var path = await _appendQueryParams('/fin/dashboard/debtors-list');

      if (queryParams.isNotEmpty) {
        path += '?${Uri.encodeQueryComponent(queryParams.entries.map((e) => '${e.key}=${e.value}').join('&'))}';
      }

      if (kDebugMode) {
        print('ApiService: getDebtorsList - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DebtorsResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении списка должников!',
          response.statusCode,
        );
      }
    } catch (e) {
      throw e;
    }
  }

  /// Получение списка кредиторов
  Future<CreditorsResponse> getCreditorsList({
    String? from,
    String? to,
    int? cashRegisterId,
    int? supplierId,
    int? clientId,
    int? leadId,
    String? operationType,
    String? search,
  }) async {
    try {
      // Формируем параметры запроса
      Map<String, String> queryParams = {};

      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;
      if (cashRegisterId != null) queryParams['cash_register_id'] = cashRegisterId.toString();
      if (supplierId != null) queryParams['supplier_id'] = supplierId.toString();
      if (clientId != null) queryParams['client_id'] = clientId.toString();
      if (leadId != null) queryParams['lead_id'] = leadId.toString();
      if (operationType != null) queryParams['operation_type'] = operationType;
      if (search != null) queryParams['search'] = search;

      var path = await _appendQueryParams('/fin/dashboard/creditors-list');

       if (queryParams.isNotEmpty) {
        path += '?${Uri.encodeQueryComponent(queryParams.entries.map((e) => '${e.key}=${e.value}').join('&'))}';
      }
      if (kDebugMode) {
        print('ApiService: getCreditorsList - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CreditorsResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении списка кредиторов!',
          response.statusCode,
        );
      }
    } catch (e) {
      throw e;
    }
  }

  /// Получение данных о неликвидных товарах
  Future<IlliquidGoodsResponse> getIlliquidGoods({
    String? from,
    String? to,
  }) async {
    try {
      // Формируем параметры запроса
      Map<String, String> queryParams = {};

      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;

      var path = await _appendQueryParams('/dashboard/illiquid-goods');

      if (queryParams.isNotEmpty) {
        path += '?${Uri.encodeQueryComponent(queryParams.entries.map((e) => '${e.key}=${e.value}').join('&'))}';
      }

      if (kDebugMode) {
        print('ApiService: getIlliquidGoods - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IlliquidGoodsResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных о неликвидных товарах!',
          response.statusCode,
        );
      }
    } catch (e) {
      throw e;
    }
  }

  /// Получение баланса денежных средств
  Future<CashBalanceResponse> getSalesDashboardCashBalance({
    String? from,
    String? to,
    int? page,
    int? perPage,
  }) async {
    // try{
      // Формируем параметры запроса
      Map<String, String> queryParams = {};

      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;
      if (page != null) queryParams['page'] = page.toString();
      if (perPage != null) queryParams['per_page'] = perPage.toString();

      var path = await _appendQueryParams('/fin/dashboard/cash-balance');

      if (queryParams.isNotEmpty) {
        path += '?${Uri.encodeQueryComponent(queryParams.entries.map((e) => '${e.key}=${e.value}').join('&'))}';
      }


      if (kDebugMode) {
        print('ApiService: getCashBalance - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CashBalanceResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении баланса денежных средств!',
          response.statusCode,
        );
      }
    // } catch (e) {
    //   throw e;
    // }
  }

  /// Получение баланса денежных средств
  Future<DashboardTopPart> getSalesDashboardTopPart() async {
      // Формируем параметры запроса
      var path = await _appendQueryParams('/fin/dashboard');

      debugPrint("ApiService: getSalesDashboardTopPart path: $path");

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DashboardTopPart.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка',
          response.statusCode,
        );
      }
  }


// API request function
  Future<List<AllExpensesData>> getExpenseStructure() async {
    // Define all periods to fetch
    final periods = [ExpensePeriodEnum.today, ExpensePeriodEnum.week, ExpensePeriodEnum.month, ExpensePeriodEnum.quarter, ExpensePeriodEnum.year];

    // List to store results
    final List<AllExpensesData> allExpensesData = [];

    // Iterate through each period
    for (final period in periods) {
      // Form the query path for the current period
      final path = await _appendQueryParams('/fin/dashboard/expense-structure?period=${period.name}');
      debugPrint("ApiService: getExpenseStructure path: $path");

      try {
        // Make the API request
        final response = await _getRequest(path);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final expenseDashboard = ExpenseDashboard.fromJson(data);
          // Create AllExpensesData for this period
          allExpensesData.add(AllExpensesData(
            period: period,
            data: expenseDashboard,
          ));
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка для периода $period',
            response.statusCode,
          );
        }
      } catch (e) {
        // Log errors for individual periods
        debugPrint("Error fetching data for period $period: $e");
        rethrow; // Rethrow to allow caller to handle
      }
    }

    return allExpensesData;
  }

  Future<SalesResponse> getSalesDynamics() async {
    // Формируем параметры запроса
    var path = await _appendQueryParams('/dashboard/sales-dynamics');

    debugPrint("ApiService: getSalesDynamics path: $path");

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SalesResponse.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка',
        response.statusCode,
      );
    }
  }

// API request function
  Future<List<AllNetProfitData>> getNetProfitData() async {
    // Define all periods to fetch
    final periods = [NetProfitPeriod.last_year, NetProfitPeriod.year];

    // List to store results
    final List<AllNetProfitData> allNetProfitData = [];

    // Iterate through each period
    for (final period in periods) {
      // Form the query path for the current period
      final path = await _appendQueryParams('/dashboard/net-profit?period=${period.name}');
      debugPrint("ApiService: getNetProfitDashboard path: $path");

      try {
        final response = await _getRequest(path);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final netProfitDashboard = NetProfitDashboard.fromJson(data);
          allNetProfitData.add(AllNetProfitData(
            period: period,
            data: netProfitDashboard,
          ));
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка для периода $period',
            response.statusCode,
          );
        }
      } catch (e) {
        debugPrint("Error fetching data for period $period: $e");
        rethrow;
      }
    }

    return allNetProfitData;
  }

  Future<List<AllOrdersData>> getOrderDashboard() async {
    // Define all periods to fetch
    final periods = [OrderTimePeriod.week, OrderTimePeriod.month, OrderTimePeriod.year];

    // List to store results
    final List<AllOrdersData> allOrdersData = [];

    // Iterate through each period
    for (final period in periods) {
      // Form the query path for the current period
      final path = await _appendQueryParams('/order/dashboard?period=${period.name}');
      debugPrint("ApiService: getOrderDashboard path: $path");

      try {
        // Make the API request
        final response = await _getRequest(path);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final orderDashboardResponse = OrderDashboardResponse.fromJson(data);
          // Create AllOrdersData for this period
          allOrdersData.add(AllOrdersData(
            period: period,
            data: orderDashboardResponse.result,
          ));
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка для периода $period',
            response.statusCode,
          );
        }
      } catch (e) {
        // Optionally handle or log errors for individual periods
        debugPrint("Error fetching data for period $period: $e");
        // You can choose to continue with other periods or rethrow
        rethrow; // Or handle differently based on your requirements
      }
    }

    return allOrdersData;
  }


// API request function
  Future<List<AllProfitabilityData>> getProfitability() async {
    // Define all periods to fetch
    final periods = [ProfitabilityTimePeriod.last_year, ProfitabilityTimePeriod.year];

    // List to store results
    final List<AllProfitabilityData> allProfitabilityData = [];

    // Iterate through each period
    for (final period in periods) {
      // Form the query path for the current period
      final path = await _appendQueryParams('/dashboard/profitability?period=${period.name}');
      debugPrint("ApiService: getProfitability path: $path");

      try {
        // Make the API request
        final response = await _getRequest(path);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final profitabilityResponse = ProfitabilityDashboard.fromJson(data);
          // Create AllProfitabilityData for this period
          allProfitabilityData.add(AllProfitabilityData(
            period: period,
            data: profitabilityResponse,
          ));
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка для периода $period',
            response.statusCode,
          );
        }
      } catch (e) {
        // Log errors for individual periods
        debugPrint("Error fetching data for period $period: $e");
        rethrow; // Rethrow to allow caller to handle
      }
    }

    return allProfitabilityData;
  }

  Future<List<AllTopSellingData>> getTopSellingGoodsDashboard({int perPage = 7}) async {
    // Define all periods to fetch
    final periods = [
      TopSellingTimePeriod.week,
      TopSellingTimePeriod.month,
      TopSellingTimePeriod.year,
    ];

    // List to store results
    final List<AllTopSellingData> allTopSellingData = [];

    // Iterate through each period
    for (final period in periods) {
      final query = ['per_page=$perPage', 'period=${period.name}'].join('&');

      final path = await _appendQueryParams('/dashboard/top-selling-goods?$query');
      debugPrint("ApiService: getTopSellingGoodsDashboard path: $path");

      try {
        final response = await _getRequest(path);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final topSellingResponse = TopSellingGoodsResponse.fromJson(data);

          // Create AllTopSellingData for this period
          allTopSellingData.add(AllTopSellingData(
            period: period,
            data: topSellingResponse.result,
          ));
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка для периода $period',
            response.statusCode,
          );
        }
      } catch (e) {
        // Log errors for individual periods
        debugPrint("Error fetching data for period $period: $e");
         throw e;
      }
    }

    return allTopSellingData;
  }

}