import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/models/LeadStatusForFilter.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
import 'package:crm_task_manager/models/calendar_model.dart';
import 'package:crm_task_manager/models/file_helper.dart';
import 'package:crm_task_manager/models/localization_model.dart';
import 'package:crm_task_manager/models/task_overdue_history_model.dart';
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
import 'package:crm_task_manager/utils/global_value.dart';
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
import 'package:crm_task_manager/screens/analytics/models/dashboard_statistics_model.dart';
import 'package:crm_task_manager/screens/analytics/models/deals_by_managers_model.dart';
import 'package:crm_task_manager/screens/analytics/models/lead_chart_model.dart';
import 'package:crm_task_manager/screens/analytics/models/lead_conversion_by_statuses_model.dart';
import 'package:crm_task_manager/screens/analytics/models/lead_process_speed_model.dart';
import 'package:crm_task_manager/screens/analytics/models/lead_channels_model.dart';
import 'package:crm_task_manager/screens/analytics/models/message_stats_model.dart';
import 'package:crm_task_manager/screens/analytics/models/online_store_orders_model.dart';
import 'package:crm_task_manager/screens/analytics/models/source_of_leads_model.dart';
import 'package:crm_task_manager/screens/analytics/models/task_chart_v2_model.dart';
import 'package:crm_task_manager/screens/analytics/models/top_selling_products_model.dart';
import 'package:crm_task_manager/screens/analytics/models/users_chart_model.dart';
import 'package:crm_task_manager/screens/analytics/models/completed_tasks_model.dart';
import 'package:crm_task_manager/screens/analytics/models/telephony_events_model.dart';
import 'package:crm_task_manager/screens/analytics/models/replies_messages_model.dart';
import 'package:crm_task_manager/screens/analytics/models/task_stats_by_project_model.dart';
import 'package:crm_task_manager/screens/analytics/models/connected_accounts_model.dart';
import 'package:crm_task_manager/screens/analytics/models/advertising_roi_model.dart';
import 'package:crm_task_manager/screens/analytics/models/telephony_by_hour_model.dart';
import 'package:crm_task_manager/screens/analytics/models/targeted_ads_model.dart';
import 'package:crm_task_manager/screens/analytics/models/dashboard_setting_item.dart';
import 'package:crm_task_manager/models/organization_model.dart';
import 'package:crm_task_manager/models/overdue_task_response.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/call_analytics_model.dart';
import 'package:crm_task_manager/models/page_2/call_center_by_id_model.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:crm_task_manager/models/page_2/call_statistics1_model.dart';
import 'package:crm_task_manager/models/page_2/call_summary_stats_model.dart';
import 'package:crm_task_manager/models/page_2/category_dashboard_warehouse_model.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/page_2/expense_details_document_model.dart'
    as expDoc;
import 'package:crm_task_manager/models/page_2/expense_document_model.dart'
    as expense;
import 'package:crm_task_manager/models/page_2/opening_supplier_model.dart'
    as opening_supplier;
import 'package:crm_task_manager/models/page_2/openings/client_dialog_model.dart'
    as opening_lead;
import 'package:crm_task_manager/models/page_2/order_status_warehouse_model.dart';
import 'package:crm_task_manager/models/page_2/expense_article_dashboard_warehouse_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/character_list_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/dashboard_goods_report.dart';
import 'package:crm_task_manager/models/page_2/dashboard/cash_balance_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/dashboard_top.dart';
import 'package:crm_task_manager/models/page_2/dashboard/debtors_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/creditors_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/illiquids_model.dart';
import 'package:crm_task_manager/models/page_2/delivery_address_model.dart';
import 'package:crm_task_manager/models/page_2/good_dashboard_warehouse_model.dart'
    as dgrmodel;
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
import 'package:crm_task_manager/models/page_2/order_internet_store_model.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/models/page_2/price_type_model.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryById.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/openings/goods_openings_model.dart';
import 'package:crm_task_manager/models/page_2/openings/supplier_openings_model.dart';
import 'package:crm_task_manager/models/page_2/openings/client_openings_model.dart';
import 'package:crm_task_manager/models/page_2/openings/cash_register_openings_model.dart'
    as openings;
import 'package:crm_task_manager/models/page_2/good_variants_model.dart';
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
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_edit_screen.dart';
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
import '../../models/dashboard_goods_movement_history_model.dart';
import '../../models/domain_check.dart';
import '../../models/income_categories_data_response.dart';
import '../../models/login_model.dart';
import '../../models/money/money_income_document_model.dart';
import '../../models/money/money_outcome_document_model.dart';
import '../../models/outcome_categories_data_response.dart';
import '../../models/page_2/dashboard/act_of_reconciliation_model.dart';
import '../../models/page_2/dashboard/expense_structure.dart';
import '../../models/page_2/dashboard/net_profit_model.dart';
import '../../models/page_2/dashboard/order_dashboard_model.dart';
import '../../models/page_2/dashboard/order_quantity_content.dart';
import '../../models/page_2/dashboard/profitability_dashboard_model.dart';
import '../../models/page_2/dashboard/sales_model.dart';
import '../../models/page_2/dashboard/net_profit_content_model.dart';
import '../../models/page_2/dashboard/profitability_content_model.dart';
import '../../models/page_2/dashboard/expense_structure_content.dart';
import '../../models/page_2/dashboard/top_selling_card_model.dart';
import '../../models/page_2/dashboard/top_selling_model.dart';

// HTTP Inspector imports (только для DEBUG)
import 'http_logger.dart';
import 'http_log_model.dart';
import 'dio_client.dart';

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
    // '/add-fcm-token',
  ];
  // Актуальные фильтры аналитики, применяемые ко всем графикам.
  static Map<String, dynamic>? _analyticsFilters;
  // In-memory cache аналитических GET-запросов (живет до перезапуска приложения).
  static final Map<String, String> _analyticsResponseCache = {};

  static void setAnalyticsFilters(Map<String, dynamic>? filters) {
    if (filters == null) {
      _analyticsFilters = null;
      return;
    }
    _analyticsFilters = Map<String, dynamic>.from(filters);
  }

  static void clearAnalyticsFilters() {
    _analyticsFilters = null;
  }

  static void clearAnalyticsResponseCache() {
    _analyticsResponseCache.clear();
  }

  String _appendAnalyticsFiltersToPath(String path) {
    final filters = _analyticsFilters;
    if (filters == null || filters.isEmpty) {
      if (kDebugMode) {
        debugPrint(
            '🟡 _appendAnalyticsFiltersToPath: No filters to apply to $path');
      }
      return path;
    }

    try {
      final uri = Uri.parse(path);
      // Create mutable copies of the lists to avoid "Cannot add to an unmodifiable list" error
      final params = uri.queryParametersAll.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );

      void addValue(String key, dynamic value) {
        if (value == null) {
          if (key == 'channel') {
            params.putIfAbsent(key, () => []).add('');
          }
          return;
        }
        if (value is String && value.isEmpty) return;

        if (value is Iterable) {
          for (final item in value) {
            if (item == null) continue;
            final stringValue = item.toString();
            if (stringValue.isEmpty) continue;
            // Use bracket notation for arrays: managers[] instead of managers[0]
            params.putIfAbsent('$key[]', () => []).add(stringValue);
          }
          return;
        }

        final stringValue = value.toString();
        if (stringValue.isEmpty) return;
        params.putIfAbsent(key, () => []).add(stringValue);
      }

      filters.forEach(addValue);

      final queryParts = <String>[];
      params.forEach((key, values) {
        for (final value in values) {
          queryParts
              .add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
        }
      });

      final queryString =
          queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
      final result = '${uri.path}$queryString';

      if (kDebugMode) {
        debugPrint(
            '🟢 _appendAnalyticsFiltersToPath: Applied filters to $path');
        debugPrint('   Filters: $filters');
        debugPrint('   Result: $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔴 _appendAnalyticsFiltersToPath: Exception caught: $e');
        debugPrint('   Original path: $path');
      }
      return path;
    }
  }

  // ОПТИМИЗАЦИЯ: Флаги для предотвращения повторной инициализации
  bool _isInitializing = false;
  bool _isInitialized = false;

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

// Вспомогательный метод для установки резервного домена
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

  // Инициализация API с доменом из QR-кода
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

  // Общая обработка ответа от сервера 401
  Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // debugPrint('ApiService: Received 401, forcing logout and redirect');
      await _forceLogoutAndRedirect();
      throw Exception('Неавторизованный доступ!');
    }

    // Дополнительная проверка на другие критические ошибки
    if (response.statusCode >= 500) {
      // debugPrint('ApiService: Server error ${response.statusCode}');
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
    ////debugPrint('API сброшено');
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

    // Clear widget permissions on iOS (via App Groups)
    await _clearWidgetPermissions();
  }

  // Clear widget permissions on logout
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

// Метод для сохранения данных после верификации email
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
      debugPrint(
          'ApiService: getVerifiedDomain - verifiedDomain: $verifiedDomain');
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
        debugPrint(
            'ApiService: initializeWithEmailFlow - Initialized with domain: $domain, organization_id: $organizationId');
      }
    } else {
      debugPrint(
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
    ////debugPrint('Перед удалением: ${prefs.getStringList('permissions')}');

    // Удаляем права доступа
    await prefs.remove('permissions');

    // Проверяем, что ключ действительно удалён
    ////debugPrint('После удаления: ${prefs.getStringList('permissions')}');
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
    final fullUrl = '$baseUrl$updatedPath';

    // HTTP Inspector: Создаем лог запроса (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Device': 'mobile'
      };
      String? requestPayload;
      try {
        final query = Uri.parse(fullUrl).queryParametersAll;
        if (query.isNotEmpty) {
          requestPayload = json.encode(
            query.map((k, v) => MapEntry(k, v.length == 1 ? v.first : v)),
          );
        }
      } catch (_) {
        requestPayload = null;
      }
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'GET',
        url: fullUrl,
        requestHeaders: headers,
        requestBody: requestPayload,
      ));
    }

    final startTime = DateTime.now();
    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Device': 'mobile'
        },
      );

      // HTTP Inspector: Обновляем лог с ответом (только в DEBUG)
      if (kDebugMode && logId != null) {
        final duration = DateTime.now().difference(startTime);
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              statusCode: response.statusCode,
              responseHeaders: response.headers,
              responseBody: response.body,
              duration: duration,
            ),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      // HTTP Inspector: Логируем ошибку (только в DEBUG)
      if (kDebugMode && logId != null) {
        final duration = DateTime.now().difference(startTime);
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              error: e.toString(),
              duration: duration,
            ),
          );
        }
      }
      rethrow;
    }
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
        debugPrint('Error: baseUrl is null');
        throw Exception('Base URL is not initialized');
      }
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final fullUrl = '$baseUrl$updatedPath';
    debugPrint('ApiService: _postRequest with updatedPath: $fullUrl');
    debugPrint('ApiService: Request body: ${json.encode(body)}');

    // HTTP Inspector: Создаем лог запроса (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'Device': 'mobile'
      };
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'POST',
        url: fullUrl,
        requestHeaders: headers,
        requestBody: json.encode(body),
      ));
    }

    final startTime = DateTime.now();
    try {
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Device': 'mobile'
        },
        body: json.encode(body),
      );

      debugPrint(
          'ApiService: _postRequest response status: ${response.statusCode}');
      debugPrint('ApiService: _postRequest response body: ${response.body}');

      // HTTP Inspector: Обновляем лог с ответом (только в DEBUG)
      if (kDebugMode && logId != null) {
        final duration = DateTime.now().difference(startTime);
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              statusCode: response.statusCode,
              responseHeaders: response.headers,
              responseBody: response.body,
              duration: duration,
            ),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      // HTTP Inspector: Логируем ошибку (только в DEBUG)
      if (kDebugMode && logId != null) {
        final duration = DateTime.now().difference(startTime);
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              error: e.toString(),
              duration: duration,
            ),
          );
        }
      }
      rethrow;
    }
  }

  Future<http.Response> _analyticsRequest(String path) async {
    if (kDebugMode) {
      debugPrint('🔵 _analyticsRequest called with path: $path');
      debugPrint('   Current _analyticsFilters: $_analyticsFilters');
    }
    final filteredPath = _appendAnalyticsFiltersToPath(path);
    if (kDebugMode) {
      debugPrint('🔵 _analyticsRequest filtered path: $filteredPath');
    }
    final cachedBody = _analyticsResponseCache[filteredPath];
    if (cachedBody != null) {
      if (kDebugMode) {
        debugPrint('🟢 _analyticsRequest cache HIT: $filteredPath');
      }
      return http.Response(
        cachedBody,
        200,
        headers: const {'x-analytics-cache': 'HIT'},
      );
    }

    final response = await _getRequest(filteredPath);
    if (response.statusCode == 200) {
      _analyticsResponseCache[filteredPath] = response.body;
      if (kDebugMode) {
        debugPrint('🟢 _analyticsRequest cache SAVE: $filteredPath');
      }
    }
    return response;
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

    //debugPrint('ApiService: _multipartPostRequest with path: ${request.url}');

    // HTTP Inspector: логируем multipart запрос/ответ (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      final multipartPayload = <String, dynamic>{
        'fields': request.fields,
        'files': request.files
            .map((file) => {
                  'field': file.field,
                  'filename': file.filename,
                  'length': file.length,
                  'contentType': file.contentType.toString(),
                })
            .toList(),
      };
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'POST',
        url: request.url.toString(),
        requestHeaders: request.headers,
        requestBody: json.encode(multipartPayload),
      ));
    }

    final startTime = DateTime.now();
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (kDebugMode && logId != null) {
      final existingLog = HttpLogger().getLogById(logId);
      if (existingLog != null) {
        HttpLogger().updateLog(
          logId,
          existingLog.copyWith(
            statusCode: response.statusCode,
            responseHeaders: response.headers,
            responseBody: response.body,
            duration: DateTime.now().difference(startTime),
          ),
        );
      }
    }

    //debugPrint(
    // 'ApiService: _multipartPostRequest response status: ${response.statusCode}');
    //debugPrint('ApiService: _multipartPostRequest response body: ${response.body}');
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
    final fullUrl = '$baseUrl$updatedPath';

    // HTTP Inspector: Создаем лог запроса (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'PATCH',
        url: fullUrl,
        requestBody: json.encode(body),
      ));
    }

    final startTime = DateTime.now();
    try {
      final response = await http.patch(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Device': 'mobile'
        },
        body: json.encode(body),
      );

      // HTTP Inspector: Обновляем лог с ответом (только в DEBUG)
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: DateTime.now().difference(startTime),
            ),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger()
              .updateLog(logId, existingLog.copyWith(error: e.toString()));
        }
      }
      rethrow;
    }
  }

  Future<http.Response> _putRequest(
      String path, Map<String, dynamic> body) async {
    if (!await _isSessionValid()) {
      await _forceLogoutAndRedirect();
      throw Exception('Session is invalid');
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final fullUrl = '$baseUrl$updatedPath';

    // HTTP Inspector: Создаем лог запроса (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'PUT',
        url: fullUrl,
        requestBody: json.encode(body),
      ));
    }

    final startTime = DateTime.now();
    try {
      final response = await http.put(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Device': 'mobile'
        },
        body: json.encode(body),
      );

      // HTTP Inspector: Обновляем лог с ответом (только в DEBUG)
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: DateTime.now().difference(startTime),
            ),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger()
              .updateLog(logId, existingLog.copyWith(error: e.toString()));
        }
      }
      rethrow;
    }
  }

  Future<http.Response> _deleteRequest(String path) async {
    if (!await _isSessionValid()) {
      await _forceLogoutAndRedirect();
      throw Exception('Session is invalid');
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final fullUrl = '$baseUrl$updatedPath';

    // HTTP Inspector: Создаем лог запроса (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'DELETE',
        url: fullUrl,
      ));
    }

    final startTime = DateTime.now();
    try {
      final response = await http.delete(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Device': 'mobile'
        },
      );

      // HTTP Inspector: Обновляем лог с ответом (только в DEBUG)
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger().updateLog(
            logId,
            existingLog.copyWith(
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: DateTime.now().difference(startTime),
            ),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode && logId != null) {
        final existingLog = HttpLogger().getLogById(logId);
        if (existingLog != null) {
          HttpLogger()
              .updateLog(logId, existingLog.copyWith(error: e.toString()));
        }
      }
      rethrow;
    }
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

    // HTTP Inspector: логируем DELETE с body (только в DEBUG)
    String? logId;
    if (kDebugMode) {
      logId = DateTime.now().millisecondsSinceEpoch.toString();
      HttpLogger().addLog(HttpLogModel(
        id: logId,
        timestamp: DateTime.now(),
        method: 'DELETE',
        url: request.url.toString(),
        requestHeaders:
            request.headers.map((k, v) => MapEntry(k, v.toString())),
        requestBody: json.encode(body),
      ));
    }

    final startTime = DateTime.now();
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (kDebugMode && logId != null) {
      final existingLog = HttpLogger().getLogById(logId);
      if (existingLog != null) {
        HttpLogger().updateLog(
          logId,
          existingLog.copyWith(
            statusCode: response.statusCode,
            responseHeaders: response.headers,
            responseBody: response.body,
            duration: DateTime.now().difference(startTime),
          ),
        );
      }
    }

    return _handleResponse(response);
  }

// Новый метод для проверки валидности сессии
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

  // Новый метод для принудительного сброса к начальному экрану
  Future<void> _forceLogoutAndRedirect() async {
    try {
      debugPrint('ApiService: Force logout and redirect to auth');

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
      debugPrint('ApiService: Error in force logout: $e');
    }
  }

  //_________________________________ END___API__METHOD__GET__POST__PATCH__DELETE____________________________________________//

  //        if (!await hasPermission('deal.read')) {
  //   throw Exception('У вас нет прав для просмотра сделки'); // Сообщение об отсутствии прав доступа
  // }

  //_________________________________ START___API__METHOD__POST__DEVICE__TOKEN_________________________________________________//

// ОТЛОЖЕННЫЙ ТОКЕН — ОДИН РАЗ, НАДЁЖНО
  static const String _pendingFcmKey = 'pending_fcm_token';

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

  // Сохранение отложенного токена
  Future<void> _savePendingToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingFcmKey, token);
    debugPrint('sendDeviceToken: Токен сохранён как отложенный');
  }

  // Удаление отложенного токена ТОЛЬКО при успехе
  Future<void> _removePendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final hadToken = prefs.containsKey(_pendingFcmKey);
    await prefs.remove(_pendingFcmKey);
    if (hadToken) debugPrint('sendDeviceToken: Отложенный токен удалён');
  }

  // ЕДИНАЯ точка отправки отложенного токена
  Future<void> sendPendingFCMTokenIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(_pendingFcmKey);

    if (pending == null || pending.isEmpty) {
      debugPrint('sendPendingFCMTokenIfNeeded: Нет отложенного токена');
      return;
    }

    debugPrint(
        'sendPendingFCMTokenIfNeeded: Найден отложенный токен → отправляем');
    await sendDeviceToken(pending); // ← внутри уже всё обработается
    // НЕ удаляем здесь! Удаление только в sendDeviceToken при успехе
  }

  // Гарантируем, что baseUrl готов (вызывать везде, где нужен ApiService)
  Future<void> ensureInitialized() async {
    if (baseUrl != null && baseUrl!.isNotEmpty) return;

    await initialize(); // твой текущий initialize()
    if (baseUrl == null || baseUrl!.isEmpty) {
      await _initializeIfDomainExists(); // если есть сохранённый домен
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
      debugPrint(
          'Initialized baseUrl: $baseUrl, baseUrlSocket: $baseUrlSocket');
      debugPrint('Saved domain: $domain, mainDomain: $mainDomain');
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
      debugPrint(
          'ApiService: saveQrData - domain: $domain, mainDomain: $mainDomain, organizationId: $organizationId');
      debugPrint('ApiService: saveQrData - baseUrl after init: $baseUrl');
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

//_________________________________ START___API__MARK:DOMAIN_CHECK____________________________________________//

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
    ////debugPrint(
    // '-=--=-=-=-=-=-=-==-=-=-=CHECK-DOMAIN-=--==-=-=--=-==--==-=-=-=-=-=-=-');
    ////debugPrint(domain);
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
    ////debugPrint('Ввведеный Doмен:----------------------');
    ////debugPrint('ДОМЕН: ${prefs.getString('enteredMainDomain')}');
    ////debugPrint('Ввведеный Poddomen---=----:----------------------');
    ////debugPrint('ПОДДОМЕН: ${prefs.getString('enteredDomain')}');
  }

// Метод для получения введенного домена
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

// Метод для получения полного URL файла
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
//_________________________________ END___API__DOMAIN_CHECK____________________________________________//

//_________________________________ START___API__LOGIN____________________________________________//

// Метод для проверки логина и пароля
  Future<LoginResponse> login(LoginModel loginModel) async {
    debugPrint('ApiService: Starting login process');
    debugPrint('ApiService: Login model: ${json.encode(loginModel.toJson())}');

    final organizationId = await getSelectedOrganization();
    debugPrint('ApiService: Using organization_id: $organizationId');

    // Проверяем baseUrl перед запросом
    if (baseUrl == null) {
      debugPrint('ApiService: baseUrl is null, trying to initialize');
      await _initializeIfDomainExists();
      if (baseUrl == null) {
        throw Exception('Failed to initialize baseUrl for login');
      }
    }
    debugPrint('ApiService: Current baseUrl: $baseUrl');

    final response = await _postRequest(
      '/login${organizationId != null ? '?organization_id=$organizationId' : ''}',
      loginModel.toJson(),
    );

    if (kDebugMode) {
      debugPrint('ApiService: login - Response: ${response.body}');
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
          debugPrint(
              'ApiService: login - Saved organization_id from response: $effectiveOrgId');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              'ApiService: login - Warning: organization_id is null, trying /organization');
        }
        // Пробуем получить organization_id из /organization
        try {
          final organizationsResponse = await _getRequest('/organization');
          if (organizationsResponse.statusCode == 200) {
            final organizations = json.decode(organizationsResponse.body);
            if (kDebugMode) {
              debugPrint(
                  'ApiService: login - /organization response: $organizations');
            }
            if (organizations is List && organizations.isNotEmpty) {
              effectiveOrgId = organizations[0]['id']?.toString();
              if (effectiveOrgId != null && effectiveOrgId.isNotEmpty) {
                await saveSelectedOrganization(effectiveOrgId);
                if (kDebugMode) {
                  debugPrint(
                      'ApiService: login - Saved organization_id from /organization: $effectiveOrgId');
                }
              } else {
                effectiveOrgId = '1'; // Дефолт id = 1
                await saveSelectedOrganization(effectiveOrgId);
                if (kDebugMode) {
                  debugPrint(
                      'ApiService: login - No valid organization_id, using default: $effectiveOrgId');
                }
              }
            } else {
              effectiveOrgId = '1'; // Дефолт id = 1
              await saveSelectedOrganization(effectiveOrgId);
              if (kDebugMode) {
                debugPrint(
                    'ApiService: login - Empty organizations list, using default: $effectiveOrgId');
              }
            }
          } else {
            effectiveOrgId = '1'; // Дефолт id = 1
            await saveSelectedOrganization(effectiveOrgId);
            if (kDebugMode) {
              debugPrint(
                  'ApiService: login - Failed to fetch /organization, using default: $effectiveOrgId');
            }
          }
        } catch (e) {
          effectiveOrgId = '1'; // Дефолт id = 1
          await saveSelectedOrganization(effectiveOrgId);
          if (kDebugMode) {
            debugPrint(
                'ApiService: login - Exception fetching /organization: $e, using default: $effectiveOrgId');
          }
        }
      }

      debugPrint('ApiService: Login successful, token saved');
      return loginResponse;
    } else {
      if (kDebugMode) {
        debugPrint(
            'ApiService: login - Error: Status ${response.statusCode}, Body: ${response.body}');
      }

      // Извлекаем сообщение об ошибке из ответа сервера
      String errorMessage = 'Неправильный Логин или Пароль!';
      try {
        final errorData = json.decode(response.body);
        if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      } catch (e) {
        debugPrint('ApiService: login - Error parsing error response: $e');
      }

      throw Exception('$errorMessage Status: ${response.statusCode}');
    }
  }

// Сохранение прав доступа в SharedPreferences
  Future<void> savePermissions(List<String> permissions) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('permissions', permissions);
    // ////debugPrint('Сохранённые права доступа: ${prefs.getStringList('permissions')}');
  }

// Получение списка прав доступа из SharedPreferences
  Future<List<String>> getPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final permissions = prefs.getStringList('permissions') ?? [];
    // ////debugPrint('Извлечённые права доступа: $permissions');
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
      //debugPrint('ApiService: fetchPermissionsByRoleId - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

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
      ////debugPrint('Ошибка при выполнении запроса fetchPermissionsByRoleId: $e');
      rethrow;
    }
  }

//_________________________________ END___API__LOGIN____________________________________________//
  Future<ForgotPinResponse> forgotPin(LoginModel loginModel) async {
    try {
      final organizationId = await getSelectedOrganization();
      final url =
          '/forgotPin${organizationId != null ? '?organization_id=$organizationId' : ''}';

      final response = await _postRequest(
        url,
        {
          'login': loginModel.login,
          'password': loginModel.password,
        },
      );

      // ✅ Успешный ответ
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);

        if (decodedJson['result'] != null) {
          return ForgotPinResponse.fromJson(decodedJson['result']);
        } else {
          throw Exception('Не удалось получить временный PIN.');
        }
      }
      // 🔴 Ошибка валидации (422)
      else if (response.statusCode == 422) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);

        // Приоритет 1: message
        if (decodedJson['message'] != null &&
            decodedJson['message'].toString().isNotEmpty) {
          throw Exception(decodedJson['message']);
        }
        // Приоритет 2: errors.login[0]
        else if (decodedJson['errors'] != null) {
          if (decodedJson['errors']['login'] != null) {
            final loginErrors = decodedJson['errors']['login'] as List;
            if (loginErrors.isNotEmpty) {
              throw Exception(loginErrors[0]);
            }
          }
          // Общая ошибка из errors
          throw Exception('Проверьте введённые данные');
        }
        // Fallback
        else {
          throw Exception('Неверный логин или пользователь не найден');
        }
      }
      // 🔴 Некорректный запрос (400)
      else if (response.statusCode == 400) {
        throw Exception('Некорректные данные запроса');
      }
      // 🔴 Другие ошибки
      else {
        throw Exception('Ошибка сервера (${response.statusCode})');
      }
    } catch (e) {
      // Пробрасываем исключение для обработки в BLoC
      rethrow;
    }
  }

//_________________________________ START_____API__SCREEN__LEAD____________________________________________//

//Метод для получения Лида через его ID
  Future<LeadById> getLeadById(int leadId) async {
    try {
      final path = await _appendQueryParams('/lead/$leadId');
      //debugPrint('ApiService: getLeadById - Generated path: $path');

      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic> jsonLead = decodedJson['result'];
        return LeadById.fromJson(jsonLead, jsonLead['leadStatus']['id']);
      } else {
        throw Exception('Ошибка загрузки лида ID!');
      }
    } catch (e) {
      //debugPrint('ApiService: getLeadById - Error:');
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
    bool? hasOrders,
    int? daysWithoutActivity,
    bool? hasNoReplies,
    bool? hasUnreadMessages,
    List<Map<String, dynamic>>? directoryValues,
    Map<String, List<String>>? customFieldFilters,
    int? salesFunnelId, // Новый параметр
  }) async {
    // Формируем базовый путь
    String path = '/lead?page=$page&per_page=$perPage';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getLeads - After _appendQueryParams: $path');
    }

    // // Добавляем sales_funnel_id из аргумента, если он передан
    // if (salesFunnelId != null) {
    //   path += '&sales_funnel_id=$salesFunnelId';
    // }

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
        (hasOrders == true) ||
        (hasNoReplies == true) ||
        (hasUnreadMessages == true) ||
        (daysWithoutActivity != null) ||
        (statuses != null) ||
        (directoryValues != null && directoryValues.isNotEmpty) ||
        (customFieldFilters != null && customFieldFilters.isNotEmpty);

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
    if (hasOrders == true) {
      path += '&hasOrders=1';
    }
    if (daysWithoutActivity != null) {
      path += '&lastUpdate=$daysWithoutActivity';
    }
    if (directoryValues != null && directoryValues.isNotEmpty) {
      final Map<String, LinkedHashSet<String>> groupedDirectoryValues = {};

      for (final dynamic rawValue in directoryValues) {
        if (rawValue is! Map) {
          continue;
        }

        final Map value = rawValue;
        final directoryIdRaw = value['directory_id'];
        final entryIdRaw = value['entry_id'];

        if (directoryIdRaw == null || entryIdRaw == null) {
          continue;
        }

        final directoryId = directoryIdRaw.toString();
        final Iterable<String> entryIds = entryIdRaw is List
            ? entryIdRaw
                .where((entry) => entry != null && entry.toString().isNotEmpty)
                .map((entry) => entry.toString())
            : [entryIdRaw.toString()];

        if (entryIds.isEmpty) {
          continue;
        }

        final entries = groupedDirectoryValues.putIfAbsent(
          directoryId,
          () => LinkedHashSet<String>(),
        );
        entries.addAll(entryIds);
      }

      if (groupedDirectoryValues.isNotEmpty) {
        var directoryIndex = 0;
        groupedDirectoryValues.forEach((directoryId, entryIds) {
          if (entryIds.isEmpty) {
            return;
          }
          path +=
              '&directory_values[$directoryIndex][directory_id]=$directoryId';

          var entryIndex = 0;
          for (final entryId in entryIds) {
            path +=
                '&directory_values[$directoryIndex][entry_id][$entryIndex]=$entryId';
            entryIndex++;
          }

          directoryIndex++;
        });
      }
    }
    if (customFieldFilters != null && customFieldFilters.isNotEmpty) {
      int index = 0;
      customFieldFilters.forEach((fieldKey, values) {
        if (values.isEmpty) {
          return;
        }
        final encodedKey = Uri.encodeQueryComponent(fieldKey);
        path += '&custom_fields[$index][key]=$encodedKey';
        for (int i = 0; i < values.length; i++) {
          final encodedValue = Uri.encodeQueryComponent(values[i]);
          path += '&custom_fields[$index][value][$i]=$encodedValue';
        }
        index++;
      });
    }

    if (kDebugMode) {
      debugPrint('ApiService: getLeads - Final path: $path');
    }
    final response = await _analyticsRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        debugPrint("getLeadsResponse: $data", wrapWidth: 999999);
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

  Future<List<LeadStatus>> getLeadStatuses({
    List<int>? managers,
    List<int>? regions,
    List<int>? sources,
    DateTime? fromDate,
    DateTime? toDate,
    bool? hasSuccessDeals,
    bool? hasInProgressDeals,
    bool? hasFailureDeals,
    bool? hasNotices,
    bool? hasContact,
    bool? hasChat,
    bool? hasNoReplies,
    bool? hasUnreadMessages,
    bool? hasDeal,
    bool? hasOrders,
    int? daysWithoutActivity,
    List<Map<String, dynamic>>? directoryValues,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    if (organizationId == null ||
        organizationId.isEmpty ||
        organizationId == 'null') {
      throw Exception('Organization ID is required but missing');
    }

    if (kDebugMode) {
      debugPrint('🔍 getLeadStatuses - START WITH FILTERS');
      debugPrint('🔍 getLeadStatuses - organizationId: $organizationId');
      debugPrint(
          '🔍 getLeadStatuses - salesFunnelId: ${salesFunnelId ?? "NULL"}');
    }

    final cacheKey =
        'cachedLeadStatuses_${organizationId}_funnel_${salesFunnelId ?? "null"}';

    try {
      String path = '/lead/statuses?organization_id=$organizationId';

      if (salesFunnelId != null &&
          salesFunnelId.isNotEmpty &&
          salesFunnelId != 'null') {
        path += '&sales_funnel_id=$salesFunnelId';
      }

      // Добавляем фильтры к запросу статусов
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
      if (fromDate != null && toDate != null) {
        final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
        final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
        path += '&from=$formattedFromDate&to=$formattedToDate';
      }
      if (hasSuccessDeals == true) path += '&hasSuccessDeals=1';
      if (hasInProgressDeals == true) path += '&hasInProgressDeals=1';
      if (hasFailureDeals == true) path += '&hasFailureDeals=1';
      if (hasNotices == true) path += '&hasNotices=1';
      if (hasContact == true) path += '&hasContact=1';
      if (hasChat == true) path += '&hasChat=1';
      if (hasNoReplies == true) path += '&hasNoReplies=1';
      if (hasUnreadMessages == true) path += '&hasUnreadMessages=1';
      if (hasDeal == true) path += '&withoutDeal=1';
      if (hasOrders == true) path += '&hasOrders=1';
      if (daysWithoutActivity != null)
        path += '&lastUpdate=$daysWithoutActivity';
      if (directoryValues != null && directoryValues.isNotEmpty) {
        for (int i = 0; i < directoryValues.length; i++) {
          final directoryId = directoryValues[i]['directory_id'];
          final entryId = directoryValues[i]['entry_id'];
          path += '&directory_values[$i][directory_id]=$directoryId';
          path += '&directory_values[$i][entry_id]=$entryId';
        }
      }

      if (kDebugMode) {
        debugPrint('📤 getLeadStatuses WITH FILTERS - Final path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode != 200) {
        throw Exception('Ошибка ${response.statusCode}!');
      }

      final dynamic data = json.decode(response.body);
      List<dynamic>? statusList;

      if (data is List) {
        statusList = data;
      } else if (data is Map<String, dynamic>) {
        if (data['result'] is List) {
          statusList = data['result'] as List;
        } else if (data['data'] is List) {
          statusList = data['data'] as List;
        } else if (data['statuses'] is List) {
          statusList = data['statuses'] as List;
        } else if (data['result'] is Map<String, dynamic> &&
            (data['result'] as Map<String, dynamic>)['statuses'] is List) {
          statusList =
              (data['result'] as Map<String, dynamic>)['statuses'] as List;
        }
      }

      if (statusList == null || statusList.isEmpty) {
        throw Exception('Результат отсутствует в ответе или пустой');
      }

      await prefs.setString(cacheKey, json.encode(statusList));

      final statuses = statusList
          .whereType<Map<String, dynamic>>()
          .map(LeadStatus.fromJson)
          .toList();

      await LeadCache.updatePersistentCountsFromStatuses(statuses);

      if (kDebugMode) {
        debugPrint(
            '✅ getLeadStatuses WITH FILTERS - Got ${statuses.length} statuses');
      }

      return statuses;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ getLeadStatuses WITH FILTERS - Error: $e');
      }

      final cachedStatuses = prefs.getString(cacheKey);
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => LeadStatus.fromJson(status))
            .toList();
        return cachedList;
      } else {
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
      ////debugPrint('Error while checking if status has leads!');
      return false;
    }
  }

// Метод для создания Cтатуса Лида
  Future<Map<String, dynamic>> createLeadStatus(
      String title, String color, bool? isFailure, bool? isSuccess) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead-status');
    if (kDebugMode) {
      //debugPrint('ApiService: createLeadStatus - Generated path: $path');
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
      //debugPrint('ApiService: updateLeadStatus - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        'position': position,
        'status_id': statusId,
      },
    );

    if (response.statusCode == 200) {
      ////debugPrint('Статус задачи успешно обновлен');
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
        //debugPrint('ApiService: getLeadHistory - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => LeadHistory.fromJson(json)).toList();
      } else {
        ////debugPrint('Failed to load lead history!');
        throw Exception('Ошибка загрузки истории лида!');
      }
    } catch (e) {
      ////debugPrint('Error occurred!');
      throw Exception('Ошибка загрузки истории лида!');
    }
  }

  Future<List<NoticeHistory>> getNoticeHistory(int leadId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path =
          await _appendQueryParams('/notices/history-by-lead-id/$leadId');
      if (kDebugMode) {
        //debugPrint('ApiService: getNoticeHistory - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

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
        //debugPrint('ApiService: getDealHistoryLead - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

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
      //debugPrint('ApiService: getLeadNotes - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

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
        //debugPrint('ApiService: createNotes - Generated path: $path');
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

      final response = await _multipartPostRequest('', request);

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
      //debugPrint('ApiService: updateNotes - Generated path: $path');
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
      //debugPrint('ApiService: deleteNotes - Generated path: $path');
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
      //debugPrint('ApiService: getLeadDeals - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

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
  Future<Map<String, dynamic>> createLeadWithData(
      Map<String, dynamic> data) async {
    // Формируем путь с query-параметрами
    final updatedPath = await _appendQueryParams('/lead');
    if (kDebugMode) {
      debugPrint(
          'ApiService: createLeadWithData - Generated path: $updatedPath');
    }

    final token = await getToken();
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl$updatedPath'));

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Device': 'mobile',
    });

    // Добавляем обычные поля
    data.forEach((key, value) {
      // Пропускаем массивы - их обработаем отдельно
      if (key != 'lead_custom_fields' && key != 'directory_values') {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      }
    });

    // Обрабатываем lead_custom_fields как массив объектов
    if (data['lead_custom_fields'] != null &&
        data['lead_custom_fields'] is List &&
        (data['lead_custom_fields'] as List).isNotEmpty) {
      List<Map<String, dynamic>> customFields =
          List<Map<String, dynamic>>.from(data['lead_custom_fields']);
      for (int i = 0; i < customFields.length; i++) {
        request.fields['lead_custom_fields[$i][key]'] =
            customFields[i]['key']?.toString() ?? '';
        request.fields['lead_custom_fields[$i][value]'] =
            customFields[i]['value']?.toString() ?? '';
        request.fields['lead_custom_fields[$i][type]'] =
            customFields[i]['type']?.toString() ?? 'string';
      }
    }

    // ВАЖНО: Обрабатываем directory_values как массив объектов
    if (data['directory_values'] != null &&
        data['directory_values'] is List &&
        (data['directory_values'] as List).isNotEmpty) {
      List<Map<String, dynamic>> directoryValues =
          List<Map<String, dynamic>>.from(data['directory_values']);
      for (int i = 0; i < directoryValues.length; i++) {
        request.fields['directory_values[$i][directory_id]'] =
            directoryValues[i]['directory_id'].toString();
        request.fields['directory_values[$i][entry_id]'] =
            directoryValues[i]['entry_id'].toString();
      }
    }
    // Добавляем файлы
    if (data['files'] != null && (data['files'] as List).isNotEmpty) {
      final filesList = data['files'] as List<FileHelper>;
      for (var fileData in filesList) {
        try {
          final file = await http.MultipartFile.fromPath(
            'files[]',
            fileData.path,
            filename: fileData.name,
          );
          request.files.add(file);
        } catch (e) {
          debugPrint("Error adding file ${fileData.name}: $e");
        }
      }
    }

    if (data['price_type_id'] != null) {
      request.fields['price_type_id'] = data['price_type_id'].toString();
    }

    if (kDebugMode) {
      debugPrint('ApiService: createLeadWithData - Request fields:');
      request.fields.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }

    final response = await _multipartPostRequest(updatedPath, request);

    if (kDebugMode) {
      debugPrint(
          'ApiService: createLeadWithData - Response status: ${response.statusCode}');
      debugPrint(
          'ApiService: createLeadWithData - Response body: ${response.body}');
    }

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
      if (response.body.contains('price_type_id')) {
        return {'success': false, 'message': 'invalid_price_type_id'};
      }
      if (response.body.contains('directory_values')) {
        return {'success': false, 'message': 'invalid_directory_values'};
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
      //debugPrint('ApiService: updateLead - Generated path: $path');
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
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/$leadId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateLeadWithData - Generated path: $path');
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

    if (data['files'] != null && (data['files'] as List).isNotEmpty) {
      final filesList = data['files'] as List<FileHelper>;
      for (var fileData in filesList) {
        try {
          if (fileData.path.startsWith('http')) {
            // If it's a URL, you need to download it first or send as URL
            // For now, skip URLs
            debugPrint("Skipping URL file: ${fileData.path}");
            continue;
          }

          final file = await http.MultipartFile.fromPath(
            'files[]',
            fileData.path,
            filename: fileData.name,
          );
          request.files.add(file);
        } catch (e) {
          debugPrint("Error adding file ${fileData.name}: $e");
        }
      }
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

    final response = await _multipartPostRequest(path, request);

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
      //debugPrint('ApiService: getAllDealNames - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

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
      //debugPrint('ApiService: getAllRegion - Generated path: $path');
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
      // ////debugPrint('getAll region!');
    }

    return dataRegion;
  }

//Метод для получения региона
  Future<List<SourceData>> getAllSource() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/source');
    if (kDebugMode) {
      //debugPrint('ApiService: getAllSource - Generated path: $path');
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
      //debugPrint('ApiService: getAllManager - Generated path: $path');
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
      //debugPrint('ApiService: getAllLeadMulti - Generated path: $path');
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

// Метод для получения Лидов с Пагинацией
  Future<LeadsDataResponse> getLeadPage(int page,
      {bool showDebt = false}) async {
    try {
      // Формируем путь с параметром страницы
      String basePath = '/lead?page=$page';

      // Добавляем параметр show_debt если нужно
      if (showDebt) {
        basePath += '&show_debt=1';
      }

      // Добавляем остальные query параметры (язык, токен и т.д.)
      final path = await _appendQueryParams(basePath);

      if (kDebugMode) {
        debugPrint('ApiService: getLeadPage - Loading page $page, path: $path');
      }

      // Выполняем GET запрос
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] != null) {
          // Парсим ответ в модель LeadsDataResponse
          final pageResponse = LeadsDataResponse.fromJson(data);

          if (kDebugMode) {
            debugPrint(
                'ApiService: Page $page loaded successfully with ${pageResponse.result?.length ?? 0} items');
            if (pageResponse.pagination != null) {
              debugPrint(
                  'ApiService: Pagination - current: ${pageResponse.pagination!.currentPage}, total pages: ${pageResponse.pagination!.totalPages}');
            }
          }

          return pageResponse;
        } else {
          // Если result пустой, возвращаем пустой response
          return LeadsDataResponse(result: [], errors: null, pagination: null);
        }
      } else {
        throw Exception(
            'Ошибка при получении данных со страницы $page! Статус: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: Error loading page $page: $e');
      }
      rethrow;
    }
  }

// Метод для Удаления Статуса Лида
  Future<Map<String, dynamic>> deleteLeadStatuses(int leadStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead-status/$leadStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteLeadStatuses - Generated path: $path');
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
      //debugPrint('ApiService: updateLeadStatusEdit - Generated path: $path');
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
      //debugPrint('ApiService: deleteLead - Generated path: $path');
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
      //debugPrint('ApiService: getContactPerson - Generated path: $path');
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
      //debugPrint('ApiService: createContactPerson - Generated path: $path');
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
      //debugPrint('ApiService: updateContactPerson - Generated path: $path');
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
      //debugPrint('ApiService: deleteContactPerson - Generated path: $path');
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
      //debugPrint('ApiService: getLeadToChat - Generated path: $path');
    }

    final response = await _getRequest(path);
    ////debugPrint('Request path: $path');

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
      //debugPrint('ApiService: getSourceLead - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные: $data');
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
      //debugPrint('ApiService: getLeadStatusForFilter - Generated path: $path');
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
      //debugPrint('ApiService: getPriceType - Generated path: $path');
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
        //debugPrint('ApiService: postLeadToC - Generated path: $path');
      }

      final response = await _postRequest(path, {});

      if (response.statusCode == 200) {
        ////debugPrint('Успешно отправлено в 1С');
      } else {
        ////debugPrint('Ошибка отправки в 1С Лид!');
        throw Exception('Ошибка отправки в 1С!');
      }
    } catch (e) {
      ////debugPrint('Произошла ошибка!');
      throw Exception('Ошибка отправки в 1С!');
    }
  }

// Метод для Обновления Данных 1С
  Future getData1C() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/get-all-data');
    if (kDebugMode) {
      //debugPrint('ApiService: getData1C - Generated path: $path');
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
      //debugPrint('ApiService: getCustomFieldslead - Generated path: $path');
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
      //debugPrint('ApiService: getLeadStatus - Generated path: $path');
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
      //debugPrint('ApiService: addLeadsFromContacts - Generated path: $path');
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
        debugPrint('ApiService: getDealById - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

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
    List<int>? regions,
    List<int>? leads,
    int? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    int? daysWithoutActivity,
    bool? hasTasks,
    List<Map<String, dynamic>>? directoryValues,
    List<String>? names,
    int? salesFunnelId, // ← КРИТИЧНО: Явный параметр
    Map<String, List<String>>? customFieldFilters,
  }) async {
    // ✅ КРИТИЧНО: Формируем базовый путь БЕЗ _appendQueryParams
    String path = '/deal?page=$page&per_page=$perPage';

    // ✅ ПЕРВЫМ делом добавляем organization_id
    final organizationId = await getSelectedOrganization();
    if (organizationId != null &&
        organizationId.isNotEmpty &&
        organizationId != 'null') {
      path += '&organization_id=$organizationId';
    }

    // ✅ ВТОРЫМ добавляем sales_funnel_id (если есть)
    if (salesFunnelId != null) {
      path += '&sales_funnel_id=$salesFunnelId';
      debugPrint('ApiService: getDeals - Added salesFunnelId: $salesFunnelId');
    } else {
      // Fallback: пробуем получить из SharedPreferences
      final savedFunnelId = await getSelectedDealSalesFunnel();
      if (savedFunnelId != null &&
          savedFunnelId.isNotEmpty &&
          savedFunnelId != 'null') {
        path += '&sales_funnel_id=$savedFunnelId';
        debugPrint(
            'ApiService: getDeals - Added savedFunnelId: $savedFunnelId');
      }
    }

    // Проверяем наличие фильтров
    bool hasFilters = (search != null && search.isNotEmpty) ||
        (managers != null && managers.isNotEmpty) ||
        (regions != null && regions.isNotEmpty) ||
        (leads != null && leads.isNotEmpty) ||
        (fromDate != null) ||
        (toDate != null) ||
        (daysWithoutActivity != null) ||
        (hasTasks == true) ||
        (statuses != null) ||
        (directoryValues != null && directoryValues.isNotEmpty) ||
        (names != null && names.isNotEmpty) ||
        (customFieldFilters != null &&
            customFieldFilters.isNotEmpty); // Учитываем кастомные поля

    // ✅ Добавляем dealStatusId только если нет фильтров
    if (dealStatusId != null && !hasFilters) {
      path += '&deal_statuses=$dealStatusId';
    }

    // Добавляем остальные параметры
    if (search != null && search.isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search)}';
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
      path += '&deal_statuses=$statuses';
    }

    if (fromDate != null && toDate != null) {
      final formattedFromDate =
          "${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}";
      final formattedToDate =
          "${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}";
      path += '&created_from=$formattedFromDate&created_to=$formattedToDate';
    }

    if (directoryValues != null && directoryValues.isNotEmpty) {
      final Map<String, LinkedHashSet<String>> groupedDirectoryValues = {};

      for (final dynamic rawValue in directoryValues) {
        if (rawValue is! Map) {
          continue;
        }

        final Map value = rawValue;
        final directoryIdRaw = value['directory_id'];
        final entryIdRaw = value['entry_id'];

        if (directoryIdRaw == null || entryIdRaw == null) {
          continue;
        }

        final directoryId = directoryIdRaw.toString();
        final Iterable<String> entryIds = entryIdRaw is List
            ? entryIdRaw
                .where((entry) => entry != null && entry.toString().isNotEmpty)
                .map((entry) => entry.toString())
            : [entryIdRaw.toString()];

        if (entryIds.isEmpty) {
          continue;
        }

        final entries = groupedDirectoryValues.putIfAbsent(
          directoryId,
          () => LinkedHashSet<String>(),
        );
        entries.addAll(entryIds);
      }

      if (groupedDirectoryValues.isNotEmpty) {
        var directoryIndex = 0;
        groupedDirectoryValues.forEach((directoryId, entryIds) {
          if (entryIds.isEmpty) {
            return;
          }
          path +=
              '&directory_values[$directoryIndex][directory_id]=$directoryId';

          var entryIndex = 0;
          for (final entryId in entryIds) {
            path +=
                '&directory_values[$directoryIndex][entry_id][$entryIndex]=$entryId';
            entryIndex++;
          }

          directoryIndex++;
        });
      }
    }

    if (names != null && names.isNotEmpty) {
      for (int i = 0; i < names.length; i++) {
        path += '&names[$i]=${Uri.encodeComponent(names[i])}';
      }
    }

    debugPrint("ApiService: getDeals - Final path: $path");

    final response = await _getRequest(path);
    debugPrint(
        "ApiService: getDeals - Response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null && data['result']['data'] != null) {
        final deals = (data['result']['data'] as List)
            .map((json) => Deal.fromJson(json, dealStatusId ?? -1))
            .toList();

        debugPrint("ApiService: getDeals - Loaded ${deals.length} deals");
        return deals;
      } else {
        debugPrint("ApiService: getDeals - No data in response");
        return []; // Возвращаем пустой массив вместо ошибки
      }
    } else {
      debugPrint("ApiService: getDeals - Error ${response.statusCode}");
      throw Exception('Ошибка загрузки сделок!');
    }
  }

// Метод для получения статусов Сделок
// ✅ ИСПРАВЛЕННЫЙ метод getDealStatuses
// Теперь ВСЕГДА использует явно переданный salesFunnelId
  Future<List<DealStatus>> getDealStatuses({
    bool includeAll = false,
    int? salesFunnelId, // ← КРИТИЧНО: Добавили явный параметр
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    // ✅ ПРИОРИТЕТ: Сначала используем переданный параметр
    String? funnelId = salesFunnelId?.toString();

    // ✅ FALLBACK: Если не передан - читаем из SharedPreferences
    if (funnelId == null || funnelId.isEmpty || funnelId == 'null') {
      funnelId = await getSelectedDealSalesFunnel();
    }

    // Проверка organizationId
    if (organizationId == null ||
        organizationId.isEmpty ||
        organizationId == 'null') {
      throw Exception('Organization ID is required but missing');
    }

    if (kDebugMode) {
      debugPrint('🔍 getDealStatuses - START: includeAll=$includeAll');
      debugPrint('🔍 getDealStatuses - organizationId: $organizationId');
      debugPrint(
          '🔍 getDealStatuses - salesFunnelId (параметр): $salesFunnelId');
      debugPrint('🔍 getDealStatuses - funnelId (итоговый): $funnelId');
    }

    final basePath = includeAll ? '/deal/statuses/all' : '/deal/statuses';
    final cacheKey = includeAll
        ? 'cachedDealStatuses_all_${organizationId}_funnel_${funnelId ?? "null"}'
        : 'cachedDealStatuses_${organizationId}_funnel_${funnelId ?? "null"}';

    try {
      // ✅ КРИТИЧНО: Формируем путь БЕЗ использования _appendQueryParams
      // Потому что _appendQueryParams может перезаписать наш salesFunnelId
      String path = '$basePath?organization_id=$organizationId';

      // ВСЕГДА добавляем sales_funnel_id если он есть
      if (funnelId != null && funnelId.isNotEmpty && funnelId != 'null') {
        path += '&sales_funnel_id=$funnelId';
        if (kDebugMode) {
          debugPrint('✅ getDealStatuses - Added sales_funnel_id: $funnelId');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ getDealStatuses - No funnel selected, loading ALL deal statuses');
        }
      }

      if (kDebugMode) {
        debugPrint('📤 getDealStatuses - Final path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          debugPrint(
              'ApiService: getDealStatuses - Response: ${response.body}');
        }

        List<dynamic>? statusList;

        // Определяем структуру ответа
        if (data is List) {
          statusList = data;
        } else if (data is Map) {
          if (data['result'] != null) {
            statusList = data['result'] is List
                ? data['result']
                : (data['result']['data'] as List?);
          } else if (data['data'] != null) {
            statusList = data['data'] as List;
          } else if (data['statuses'] != null) {
            statusList = data['statuses'] as List;
          }
        }

        // ✅ КРИТИЧНО: Обрабатываем ПУСТОЙ массив как валидный результат
        if (statusList != null) {
          if (statusList.isEmpty) {
            debugPrint(
                '⚠️ getDealStatuses - API вернул пустой массив статусов');
            // Очищаем кэш для этой воронки
            await prefs.remove(cacheKey);
            return []; // Возвращаем пустой список (это не ошибка!)
          }

          // Обновляем кэш
          await prefs.setString(cacheKey, json.encode(statusList));

          if (kDebugMode) {
            debugPrint(
                '✅ getDealStatuses - Loaded ${statusList.length} statuses');
          }

          return statusList
              .map((status) => DealStatus.fromJson(status))
              .toList();
        } else {
          debugPrint("❌ getDealStatuses - No valid data in response");
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ getDealStatuses - Ошибка: $e');
      debugPrint('⚠️ getDealStatuses - Используем кэш');

      final cachedStatuses = prefs.getString(cacheKey);
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => DealStatus.fromJson(status))
            .toList();

        debugPrint(
            '✅ getDealStatuses - Загружено ${cachedList.length} статусов из кэша');
        return cachedList;
      } else {
        debugPrint('❌ getDealStatuses - Нет кэшированных данных');
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
      ////debugPrint('Error while checking if status has deals!');
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
    List<int>? userIds,
    List<int>? changeStatusUserIds, // ✅ НОВОЕ
  ) async {
    final path = await _appendQueryParams('/deal/statuses');

    if (kDebugMode) {
      debugPrint('ApiService: createDealStatus - userIds: $userIds');
      debugPrint(
          'ApiService: createDealStatus - changeStatusUserIds: $changeStatusUserIds'); // ✅ НОВОЕ
    }

    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    final body = {
      'title': title,
      'day': day,
      'color': color,
      'notification_message': notificationMessage,
      'show_on_main_page': showOnMainPage ? 1 : 0,
      'is_success': isSuccess ? 1 : 0,
      'is_failure': isFailure ? 1 : 0,
      'organization_id': organizationId?.toString() ?? '',
      if (salesFunnelId != null) 'sales_funnel_id': salesFunnelId.toString(),
      if (userIds != null && userIds.isNotEmpty) 'users': userIds,
      if (changeStatusUserIds != null && changeStatusUserIds.isNotEmpty)
        'change_status_users': changeStatusUserIds, // ✅ НОВОЕ
    };

    if (kDebugMode) {
      debugPrint('ApiService: createDealStatus request body: $body');
    }

    final response = await _postRequest(path, body);

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
        //debugPrint('ApiService: getDealHistory - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => DealHistory.fromJson(json)).toList();
      } else {
        ////debugPrint('Failed to load deal history!');
        throw Exception('Ошибка загрузки истории сделки!');
      }
    } catch (e) {
      ////debugPrint('Error occurred!');
      throw Exception('Ошибка загрузки истории сделки!');
    }
  }

  Future<List<OrderHistory>> getOrderHistory(int orderId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order/history/$orderId');
      if (kDebugMode) {
        //debugPrint('ApiService: getOrderHistory - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => OrderHistory.fromJson(json)).toList();
      } else {
        ////debugPrint('Failed to load order history!');
        throw Exception('Ошибка загрузки истории заказа!');
      }
    } catch (e) {
      ////debugPrint('Error occurred: $e');
      throw Exception('Ошибка загрузки истории заказа!');
    }
  }

// Обновление статуса карточки Сделки в колонке
  Future<void> updateDealStatus(
    int dealId,
    int currentStatusId, // from_status_id
    List<int> statusIds, // to_status_id (один или несколько)
    {
    bool isMultiSelect = false, // новый параметр
    String? organizationId,
    String? salesFunnelId,
  }) async {
    if (isMultiSelect) {
      // ============ МУЛЬТИВЫБОР (как было) ============
      final path =
          await _appendQueryParams('/deal/change-multiple-status/$dealId');
      if (kDebugMode) {
        debugPrint('ApiService: MULTI-SELECT mode');
        debugPrint('ApiService: Path: $path');
        debugPrint('ApiService: Statuses: $statusIds');
      }

      final response = await _postRequest(
        path,
        {
          'position': 1,
          'statuses': statusIds,
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Статусы успешно обновлены (multi-select)');
        }
      } else if (response.statusCode == 422) {
        throw DealStatusUpdateException(
          422,
          'Вы не можете переместить задачу на эти статусы',
        );
      } else {
        throw Exception('Ошибка обновления статусов сделки!');
      }
    } else {
      // ============ ОДИНОЧНЫЙ ВЫБОР (новая логика) ============
      if (statusIds.isEmpty) {
        throw Exception('Не выбран статус для перемещения');
      }

      final int toStatusId = statusIds.first; // берём первый (и единственный)

      // Формируем URL с query параметрами
      String path = '/deal/changeStatus1/$dealId';
      final queryParams = <String, String>{};

      if (organizationId != null) {
        queryParams['organization_id'] = organizationId;
      }
      if (salesFunnelId != null) {
        queryParams['sales_funnel_id'] = salesFunnelId;
      }

      // Добавляем параметры через _appendQueryParams или вручную
      if (queryParams.isNotEmpty) {
        final query =
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
        path = '$path?$query';
      }

      if (kDebugMode) {
        debugPrint('ApiService: SINGLE-SELECT mode');
        debugPrint('ApiService: Path: $path');
        debugPrint(
            'ApiService: from_status_id: $currentStatusId → to_status_id: $toStatusId');
      }

      final response = await _postRequest(
        path,
        {
          'from_status_id': currentStatusId,
          'to_status_id': toStatusId,
          'position': 1,
          'organization_id': organizationId ?? '1',
          'sales_funnel_id': salesFunnelId ?? '1',
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Статус успешно обновлён (single-select)');
        }
      } else if (response.statusCode == 422) {
        throw DealStatusUpdateException(
          422,
          'Вы не можете переместить задачу на этот статус',
        );
      } else {
        throw Exception('Ошибка обновления статуса сделки!');
      }
    }
  }

// Метод для Получения Сделки в Окно Лида
  Future<List<DealTask>> getDealTasks(int dealId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/getByDeal/$dealId');
    if (kDebugMode) {
      //debugPrint('ApiService: getDealTasks - Generated path: $path');
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
    List<FileHelper>? files,
    List<int>? userIds, // ✅ НОВОЕ
  }) async {
    try {
      final updatedPath = await _appendQueryParams('/deal');
      if (kDebugMode) {
        debugPrint('ApiService: createDeal - Generated path: $updatedPath');
        debugPrint('ApiService: createDeal - userIds: $userIds'); // ✅ НОВОЕ
      }

      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl$updatedPath'));

      request.fields['name'] = name;
      request.fields['deal_status_id'] = dealStatusId.toString();
      request.fields['deal_status_ids[0]'] = dealStatusId.toString();
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

      // ✅ НОВОЕ: Добавляем user_ids
      if (userIds != null && userIds.isNotEmpty) {
        for (int i = 0; i < userIds.length; i++) {
          request.fields['users[$i]'] = userIds[i].toString();
        }
        debugPrint('ApiService: createDeal - Added user_ids: $userIds');
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

      if (files != null && files.isNotEmpty) {
        for (var fileData in files) {
          try {
            final file = await http.MultipartFile.fromPath(
              'files[]',
              fileData.path,
              filename: fileData.name,
            );
            request.files.add(file);
          } catch (e) {
            debugPrint("Error adding file ${fileData.name}: $e");
          }
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
    List<FileHelper>? files,
    List<int>? dealStatusIds, // ✅ НОВОЕ
    List<int>? existingFiles, // ID существующих файлов
    List<int>? userIds, // ✅ НОВОЕ: массив ID пользователей
  }) async {
    // Формируем путь с query-параметрами
    final updatedPath = await _appendQueryParams('/deal/$dealId');
    if (kDebugMode) {
      debugPrint('ApiService: updateDeal - Generated path: $updatedPath');
      debugPrint('ApiService: updateDeal - userIds: $userIds'); // ✅ НОВОЕ
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

    // Отправляем массив статусов
    if (dealStatusIds != null && dealStatusIds.isNotEmpty) {
      for (int i = 0; i < dealStatusIds.length; i++) {
        request.fields['deal_status_ids[$i]'] = dealStatusIds[i].toString();
      }
      debugPrint('ApiService: Отправка deal_status_ids: $dealStatusIds');
    }

    // ✅ НОВОЕ: Добавляем user_ids
    if (userIds != null && userIds.isNotEmpty) {
      for (int i = 0; i < userIds.length; i++) {
        request.fields['users[$i]'] = userIds[i].toString();
      }
      debugPrint('ApiService: updateDeal - Added user_ids: $userIds');
    }

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

    // Добавляем ID существующих файлов
    if (existingFiles != null && existingFiles.isNotEmpty) {
      for (int i = 0; i < existingFiles.length; i++) {
        request.fields['existing_files[$i]'] = existingFiles[i].toString();
      }
    }

    // Отправляем только новые файлы (id == 0)
    if (files != null && files.isNotEmpty) {
      final newFiles = files.where((f) => f.id == 0).toList();
      for (var fileData in newFiles) {
        try {
          final file = await http.MultipartFile.fromPath(
            'files[]',
            fileData.path,
            filename: fileData.name,
          );
          request.files.add(file);
        } catch (e) {
          debugPrint("Error adding file ${fileData.name}: $e");
        }
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
      //debugPrint('ApiService: deleteDealStatuses - Generated path: $path');
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
      //debugPrint('ApiService: deleteDeal - Generated path: $path');
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
      //debugPrint('ApiService: getCustomFieldsdeal - Generated path: $path');
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
    List<int>? userIds, // пользователи, которые могут ВИДЕТЬ сделки
    List<int>?
        changeStatusUserIds, // ✅ НОВОЕ: пользователи, которые могут ИЗМЕНЯТЬ статус
  ) async {
    final path = await _appendQueryParams('/deal/statuses/$dealStatusId');

    if (kDebugMode) {
      debugPrint('ApiService: updateDealStatusEdit - userIds: $userIds');
      debugPrint(
          'ApiService: updateDealStatusEdit - changeStatusUserIds: $changeStatusUserIds'); // ✅ НОВОЕ
    }

    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    final payload = {
      "title": title,
      "day": day,
      "color": "#000",
      "is_success": isSuccess ? 1 : 0,
      "is_failure": isFailure ? 1 : 0,
      "notification_message": notificationMessage,
      "show_on_main_page": showOnMainPage ? 1 : 0,
      "organization_id": organizationId?.toString() ?? '',
      if (salesFunnelId != null) "sales_funnel_id": salesFunnelId.toString(),
      // ✅ Добавляем оба массива пользователей
      if (userIds != null && userIds.isNotEmpty) "users": userIds,
      if (changeStatusUserIds != null && changeStatusUserIds.isNotEmpty)
        "change_status_users": changeStatusUserIds, // ✅ НОВОЕ
    };

    if (kDebugMode) {
      debugPrint('ApiService: updateDealStatusEdit payload: $payload');
    }

    final response = await _patchRequest(path, payload);

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
      //debugPrint('ApiService: getDealStatus - Generated path: $path');
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
        //debugPrint('ApiService: getTaskById - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

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
    List<int>? projectIds,
    List<String>? authors,
    String? department,
    List<Map<String, dynamic>>? directoryValues, // Добавляем directoryValues
  }) async {
    // Формируем базовый путь
    String path = '/task?page=$page&per_page=$perPage';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getTasks - Generated path: $path');
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
        (projectIds != null && projectIds.isNotEmpty) ||
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
    if (projectIds != null && projectIds.isNotEmpty) {
      for (int projectId in projectIds) {
        path += '&project_ids[]=$projectId';
      }
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
      final Map<String, LinkedHashSet<String>> groupedDirectoryValues = {};

      for (final dynamic rawValue in directoryValues) {
        if (rawValue is! Map) {
          continue;
        }

        final Map value = rawValue;
        final directoryIdRaw = value['directory_id'];
        final entryIdRaw = value['entry_id'];

        if (directoryIdRaw == null || entryIdRaw == null) {
          continue;
        }

        final directoryId = directoryIdRaw.toString();
        final Iterable<String> entryIds = entryIdRaw is List
            ? entryIdRaw
                .where((entry) => entry != null && entry.toString().isNotEmpty)
                .map((entry) => entry.toString())
            : [entryIdRaw.toString()];

        if (entryIds.isEmpty) {
          continue;
        }

        final entries = groupedDirectoryValues.putIfAbsent(
          directoryId,
          () => LinkedHashSet<String>(),
        );
        entries.addAll(entryIds);
      }

      if (groupedDirectoryValues.isNotEmpty) {
        var directoryIndex = 0;
        groupedDirectoryValues.forEach((directoryId, entryIds) {
          if (entryIds.isEmpty) {
            return;
          }
          path +=
              '&directory_values[$directoryIndex][directory_id]=$directoryId';

          var entryIndex = 0;
          for (final entryId in entryIds) {
            path +=
                '&directory_values[$directoryIndex][entry_id][$entryIndex]=$entryId';
            entryIndex++;
          }

          directoryIndex++;
        });
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
      ////debugPrint('Error response! - ${response.body}');
      throw Exception('Ошибка загрузки задач!');
    }
  }

// Метод для получения статусов задач
  Future<List<TaskStatus>> getTaskStatuses({
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
    List<int>? projectIds,
    List<String>? authors,
    String? department,
    List<Map<String, dynamic>>? directoryValues,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    if (kDebugMode) {
      debugPrint('🔍 getTaskStatuses - START WITH FILTERS');
      debugPrint('🔍 getTaskStatuses - organizationId: $organizationId');
    }

    try {
      String path = '/task-status';
      path = await _appendQueryParams(path);

      // Добавляем фильтры к запросу статусов
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
      if (overdue == true) path += '&overdue=1';
      if (hasFile == true) path += '&hasFile=1';
      if (hasDeal == true) path += '&hasDeal=1';
      if (urgent == true) path += '&urgent=1';
      if (deadlinefromDate != null && deadlinetoDate != null) {
        final formattedDeadlineFrom =
            DateFormat('yyyy-MM-dd').format(deadlinefromDate);
        final formattedDeadlineTo =
            DateFormat('yyyy-MM-dd').format(deadlinetoDate);
        path +=
            '&deadline_from=$formattedDeadlineFrom&deadline_to=$formattedDeadlineTo';
      }
      if (projectIds != null && projectIds.isNotEmpty) {
        for (int i = 0; i < projectIds.length; i++) {
          path += '&project_ids[$i]=${projectIds[i]}';
        }
      }
      if (authors != null && authors.isNotEmpty) {
        for (int i = 0; i < authors.length; i++) {
          path += '&authors[$i]=${Uri.encodeQueryComponent(authors[i])}';
        }
      }
      if (department != null && department.isNotEmpty) {
        path += '&department=${Uri.encodeQueryComponent(department)}';
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
        debugPrint('📤 getTaskStatuses WITH FILTERS - Final path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic>? statusList;

        if (data is List) {
          statusList = data;
        } else if (data is Map) {
          if (data['result'] != null) {
            statusList = data['result'] as List;
          } else if (data['data'] != null) {
            statusList = data['data'] as List;
          } else if (data['statuses'] != null) {
            statusList = data['statuses'] as List;
          }
        }

        if (statusList != null && statusList.isNotEmpty) {
          // Обновляем кэш новыми данными
          await prefs.setString(
              'cachedTaskStatuses_$organizationId', json.encode(statusList));

          final statuses =
              statusList.map((status) => TaskStatus.fromJson(status)).toList();

          if (kDebugMode) {
            debugPrint(
                '✅ getTaskStatuses WITH FILTERS - Got ${statuses.length} statuses');
          }

          return statuses;
        } else {
          throw Exception('Результат отсутствует в ответе или пустой');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      ////debugPrint('Ошибка загрузки статусов задач. Используем кэшированные данные.');
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
      ////debugPrint('Error while checking if status has deals!');
      return false;
    }
  }

// Обновление статуса карточки Задачи в колонке
  Future<void> updateTaskStatus(int taskId, int position, int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/changeStatus/$taskId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateTaskStatus - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'position': 1,
      'status_id': statusId,
    });

    if (response.statusCode == 200) {
      ////debugPrint('Статус задачи успешно обновлен');
    } else if (response.statusCode == 422) {
      // ПАРСИМ JSON ОТВЕТ ОТ СЕРВЕРА
      final jsonResponse = json.decode(response.body);
      // БЕРЁМ message ИЗ ОТВЕТА СЕРВЕРА
      final errorMessage = jsonResponse['message'] ??
          'Вы не можете переместить задачу на этот статус';
      throw TaskStatusUpdateException(422, errorMessage);
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
        //debugPrint('ApiService: CreateTaskStatusAdd - Generated path: $path');
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
        //debugPrint('ApiService: createTaskFromDeal - Generated path: $path');
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

      final response = await _multipartPostRequest('', request);

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
    List<FileHelper>? files,
    List<Map<String, int>>? directoryValues,
    int position = 1,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task');
      if (kDebugMode) {
        //debugPrint('ApiService: createTask - Generated path: $path');
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
          request.fields['custom_fields[$i][key]'] = field['key'] ?? '';
          request.fields['custom_fields[$i][value]'] = field['value'] ?? '';
          request.fields['custom_fields[$i][type]'] = field['type'] ?? 'string';
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

      // Отправляем файлы (все файлы при создании новые, id == 0)
      if (files != null && files.isNotEmpty) {
        final newFiles = files.where((f) => f.id == 0).toList();
        for (var fileData in newFiles) {
          try {
            final file = await http.MultipartFile.fromPath(
              'files[]',
              fileData.path,
              filename: fileData.name,
            );
            request.files.add(file);
          } catch (e) {
            debugPrint("Error adding file ${fileData.name}: $e");
          }
        }
      }

      final response = await _multipartPostRequest('', request);

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
        //debugPrint('ApiService: updateTask - Generated path: $path');
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
          request.fields['custom_fields[$i][key]'] = field['key']!.toString();
          request.fields['custom_fields[$i][value]'] =
              field['value']!.toString();
          request.fields['custom_fields[$i][type]'] =
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
      final response = await _multipartPostRequest('', request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'task_update_successfully',
        };
      } else if (response.statusCode == 422) {
        ////debugPrint('Server Response: ${response.body}'); // Добавим для отладки

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
        ////debugPrint('Server Response: ${response.body}'); // Добавим для отладки

        return {
          'success': false,
          'message': 'error_task_update_successfully',
        };
      }
    } catch (e) {
      ////debugPrint('Update Task Error: $e'); // Добавим для отладки

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
        //debugPrint('ApiService: getTaskHistory - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => TaskHistory.fromJson(json)).toList();
      } else {
        ////debugPrint('Failed to load task history!');
        throw Exception('Ошибка загрузки истории задач!');
      }
    } catch (e) {
      ////debugPrint('Error occurred!');
      throw Exception('Ошибка загрузки истории задач!');
    }
  }

  /// Получить историю выполнения задачи (overdue history)
  /// GET /api/task/overdue-history/{taskId}?organization_id=1&sales_funnel_id=1
  Future<TaskOverdueHistoryResponse?> getTaskOverdueHistory(int taskId) async {
    try {
      final path = await _appendQueryParams('/task/overdue-history/$taskId');
      if (kDebugMode) {
        debugPrint('ApiService: getTaskOverdueHistory - Path: $path');
      }

      final response = await _analyticsRequest(path);

      if (kDebugMode) {
        debugPrint(
            'ApiService: getTaskOverdueHistory - Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final historyResponse = TaskOverdueHistoryResponse.fromJson(data);

        if (kDebugMode) {
          debugPrint(
              'ApiService: История выполнения получена - ${historyResponse.result?.length ?? 0} записей');
        }

        return historyResponse;
      } else {
        if (kDebugMode) {
          debugPrint(
              'ApiService: Ошибка получения истории выполнения: ${response.statusCode}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            'ApiService: Исключение при получении истории выполнения: $e');
        debugPrint('ApiService: StackTrace: $stackTrace');
      }
      return null;
    }
  }

// Метод для получения Проекта
  Future<ProjectsDataResponse> getAllProject() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/project');
    if (kDebugMode) {
      //debugPrint('ApiService: getAllProject - Generated path: $path');
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
  Future<ProjectTaskDataResponse> getTaskProject(
      {int page = 1, int perPage = 20}) async {
    // Формируем базовый путь с параметрами пагинации
    String path = '/task/get/projects?page=$page&per_page=$perPage';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      debugPrint('ApiService: getTaskProject - Generated path: $path');
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
      // ////debugPrint('getAll project!');
    }

    return dataProject;
  }

// Метод для получения Пользователя
  Future<List<UserTask>> getUserTask() async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/user');
      if (kDebugMode) {
        //debugPrint('ApiService: getUserTask - Generated path: $path');
      }

      ////debugPrint('Отправка запроса на /user');
      final response = await _analyticsRequest(path);
      // ////debugPrint('Статус ответа!');
      // ////debugPrint('Тело ответа!');

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
      //debugPrint('ApiService: getRoles - Generated path: $path');
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
      //debugPrint('ApiService: getStatusName - Generated path: $path');
    }

    ////debugPrint('Начало запроса статусов задач'); // Отладочный вывод
    final response = await _getRequest(path);
    ////debugPrint('Статус код ответа!'); // Отладочный вывод

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные: $data'); // Отладочный вывод

      if (data['result'] != null) {
        final statusList = (data['result'] as List)
            .map((name) => StatusName.fromJson(name))
            .toList();
        ////debugPrint(
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
      //debugPrint('ApiService: deleteTask - Generated path: $path');
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
      //debugPrint('ApiService: deleteTaskStatuses - Generated path: $path');
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
      //debugPrint('ApiService: finishTask - Generated path: $path');
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
      //debugPrint('ApiService: getCustomFields - Generated path: $path');
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
      //debugPrint('ApiService: getTaskStatus - Generated path: $path');
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
      //debugPrint('ApiService: updateTaskStatusEdit - Generated path: $path');
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
      //debugPrint('ApiService: deleteTaskFile - Generated path: $path');
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
      //debugPrint('ApiService: getDepartments - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result']; // Извлекаем массив из ключа "result"
      ////debugPrint('Полученные данные отделов: $result');
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
      //debugPrint('ApiService: getDirectory - Generated path: $path');
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
      ////debugPrint('getAll directory!');
    }

    return dataDirectory;
  }

  Future<MainFieldResponse> getMainFields(int directoryId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/directory/getMainFields/$directoryId');
    if (kDebugMode) {
      //debugPrint('ApiService: getMainFields - Generated path: $path');
    }

    ////debugPrint('Вызов getMainFields для directoryId: $directoryId');
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Ответ getMainFields для directoryId $directoryId: $data');
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
      //debugPrint('ApiService: linkDirectory - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        'directory_id': directoryId,
        'model_type': modelType,
        'organization_id': organizationId,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ('Ошибка при связывании справочника: ${response.statusCode}');
    }

    if (kDebugMode) {
      ////debugPrint('Directory linked successfully!');
    }
  }

  Future<DirectoryLinkResponse> getTaskDirectoryLinks() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/directoryLink/task');
    if (kDebugMode) {
      //debugPrint('ApiService: getTaskDirectoryLinks - Generated path: $path');
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
      //debugPrint('ApiService: getLeadDirectoryLinks - Generated path: $path');
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
      //debugPrint('ApiService: getDealDirectoryLinks - Generated path: $path');
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
      //debugPrint('ApiService: getLeadChart - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

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
      //debugPrint('ApiService: getLeadConversionData - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

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
      //debugPrint('ApiService: getDealStatsData - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DealStatsResponse.fromJson(jsonData);
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера!');
      } else {
        throw Exception('Ошибка загрузки данных!');
      }
    } catch (e) {
      ////debugPrint('Ошибка запроса!');
      throw ('');
    }
  }

// Метод для получения графика Задачи
  Future<TaskChart> getTaskChartData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/task-chart');
    if (kDebugMode) {
      //debugPrint('ApiService: getTaskChartData - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

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
      //debugPrint('ApiService: getProcessSpeedData - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

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
      //debugPrint('ApiService: getUsersChartData - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

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

  Future<OverdueTasksResponse> getUsersOverdueTaskData(
      {required int userId}) async {
    // Use _appendQueryParams to include organization_id, etc.
    final path =
        await _appendQueryParams('/dashboard/user/$userId/overdue-tasks');

    if (kDebugMode) {
      // debugPrint('ApiService: getUserOverdueTasksData - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['result'] != null) {
        return OverdueTasksResponse.fromJson(data);
      } else {
        throw ('Нет данных в ответе "Просроченные задачи"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Ошибка загрузки данных "Просроченные задачи"!');
    }
  }

  // ============ NEW ANALYTICS API METHODS ============

  /// Получение графика лидов с датами
  /// Endpoint: /api/dashboard/lead-chart?fromDate=YYYY-MM-DD&toDate=YYYY-MM-DD
  Future<LeadChartResponse> getLeadChartWithDates({
    required String fromDate,
    required String toDate,
  }) async {
    final path = await _appendQueryParams(
      '/dashboard/lead-chart?fromDate=$fromDate&toDate=$toDate',
    );

    if (kDebugMode) {
      debugPrint('ApiService: getLeadChartWithDates - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return LeadChartResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки данных графика лидов!');
      }
    } catch (e) {
      debugPrint('ApiService: getLeadChartWithDates error: $e');
      throw Exception('Ошибка получения данных графика лидов: $e');
    }
  }

  /// Получение конверсии по статусам
  /// Endpoint: /api/v2/dashboard/leadConversion-by-statuses-chart
  Future<LeadConversionByStatusesResponse> getLeadConversionByStatuses() async {
    final path = await _appendQueryParams(
        '/v2/dashboard/leadConversion-by-statuses-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getLeadConversionByStatuses - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return LeadConversionByStatusesResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки данных конверсии по статусам!');
      }
    } catch (e) {
      debugPrint('ApiService: getLeadConversionByStatuses error: $e');
      throw Exception('Ошибка получения данных конверсии: $e');
    }
  }

  /// Получение скорости обработки лидов (V2)
  /// Endpoint: /api/v2/dashboard/lead-process-speed
  Future<LeadProcessSpeedResponse> getLeadProcessSpeedV2() async {
    final path = await _appendQueryParams('/v2/dashboard/lead-process-speed');

    if (kDebugMode) {
      debugPrint('ApiService: getLeadProcessSpeedV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return LeadProcessSpeedResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки данных скорости обработки!');
      }
    } catch (e) {
      debugPrint('ApiService: getLeadProcessSpeedV2 error: $e');
      throw Exception('Ошибка получения данных скорости обработки: $e');
    }
  }

  Future<List<OrderInternetStore>> getOrderInternetStores() async {
    var path = '/integrations?type=mini_app_telegram_bot';
    path = await _appendQueryParams(path);

    if (kDebugMode) {
      debugPrint('ApiService: getOrderInternetStores - Generated path: $path');
    }

    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки интернет магазинов');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final result = data['result'];
    final rawList = <dynamic>[];

    if (result is List) {
      rawList.addAll(result);
    } else if (result is Map<String, dynamic>) {
      if (result['data'] is List) {
        rawList.addAll(result['data'] as List<dynamic>);
      } else if (result['integrations'] is List) {
        rawList.addAll(result['integrations'] as List<dynamic>);
      }
    }

    if (kDebugMode) {
      debugPrint(
          'ApiService: getOrderInternetStores - parsed items count: ${rawList.length}');
      if (rawList.isEmpty) {
        debugPrint(
            'ApiService: getOrderInternetStores - empty body: ${response.body}');
      }
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(OrderInternetStore.fromJson)
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
  }

  /// Получение каналов привлечения лидов
  /// Endpoint: /api/dashboard/lead-channels
  Future<LeadChannelsResponse> getLeadChannels() async {
    final path = await _appendQueryParams('/dashboard/lead-channels');

    if (kDebugMode) {
      debugPrint('ApiService: getLeadChannels - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return LeadChannelsResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки данных каналов!');
      }
    } catch (e) {
      debugPrint('ApiService: getLeadChannels error: $e');
      throw Exception('Ошибка получения данных каналов: $e');
    }
  }

  /// Получение статистики сообщений
  /// Endpoint: /api/dashboard/message-stats
  Future<MessageStatsResponse> getMessageStats() async {
    final path = await _appendQueryParams('/dashboard/message-stats');

    if (kDebugMode) {
      debugPrint('ApiService: getMessageStats - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return MessageStatsResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки статистики сообщений!');
      }
    } catch (e) {
      debugPrint('ApiService: getMessageStats error: $e');
      throw Exception('Ошибка получения статистики сообщений: $e');
    }
  }

  /// Получение графика пользователей (V2)
  /// Endpoint: /api/v2/dashboard/users-chart
  Future<UsersChartResponse> getUsersChartV2() async {
    final path = await _appendQueryParams('/v2/dashboard/users-chart');

    if (kDebugMode) {
      debugPrint('ApiService: getUsersChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UsersChartResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки данных пользователей!');
      }
    } catch (e) {
      debugPrint('ApiService: getUsersChartV2 error: $e');
      throw Exception('Ошибка получения данных пользователей: $e');
    }
  }

  /// Получение статистики для 4 карточек (V2)
  /// Endpoint: /api/v2/dashboard/statistics
  Future<DashboardStatisticsResponse> getDashboardStatisticsV2() async {
    final path = await _appendQueryParams('/v2/dashboard/statistics');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getDashboardStatisticsV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DashboardStatisticsResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки статистики!');
      }
    } catch (e) {
      debugPrint('ApiService: getDashboardStatisticsV2 error: $e');
      throw Exception('Ошибка получения статистики: $e');
    }
  }

  /// Получение настроек/доступов графиков для аналитики (V2)
  /// Endpoint: /api/v2/dashboard-settings
  Future<List<DashboardSettingItem>> getDashboardSettingsV2() async {
    final path = await _appendQueryParams('/v2/dashboard-settings');

    if (kDebugMode) {
      debugPrint('ApiService: getDashboardSettingsV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode != 200) {
        throw Exception(
          'Ошибка загрузки настроек графиков! Код: ${response.statusCode}',
        );
      }

      final dynamic jsonData = json.decode(response.body);
      final dynamic result =
          jsonData is Map<String, dynamic> ? jsonData['result'] : null;

      if (result is! List) {
        return [];
      }

      return result
          .whereType<Map<String, dynamic>>()
          .map(DashboardSettingItem.fromJson)
          .where((item) => item.nameEn.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('ApiService: getDashboardSettingsV2 error: $e');
      rethrow;
    }
  }

  /// Применение фильтров аналитики (V2)
  /// Endpoint: /api/v2/dashboard/filters
  Future<void> applyAnalyticsFiltersV2(Map<String, dynamic> filters) async {
    const path = '/v2/dashboard/filters';

    if (kDebugMode) {
      debugPrint('ApiService: applyAnalyticsFiltersV2 - Filters: $filters');
    }

    try {
      final response = await _postRequest(path, filters);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw Exception('Ошибка применения фильтров аналитики!');
    } catch (e) {
      debugPrint('ApiService: applyAnalyticsFiltersV2 error: $e');
      throw Exception('Ошибка применения фильтров аналитики: $e');
    }
  }

  /// Конверсия лидов (V2)
  /// Endpoint: /api/v2/dashboard/leadConversion-chart
  Future<LeadConversion> getLeadConversionDataV2() async {
    final path = await _appendQueryParams('/v2/dashboard/leadConversion-chart');

    if (kDebugMode) {
      debugPrint('ApiService: getLeadConversionDataV2 - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        return LeadConversion.fromJson(data);
      } else {
        throw ('Нет данных графика в ответе "Конверсия лидов"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('');
    }
  }

  /// Задачи (V2)
  /// Endpoint: /api/v2/dashboard/task-chart
  Future<TaskChartV2Response> getTaskChartDataV2() async {
    final path = await _appendQueryParams('/v2/dashboard/task-chart');

    if (kDebugMode) {
      debugPrint('ApiService: getTaskChartDataV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return TaskChartV2Response.fromJson(jsonMap);
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера!');
      } else {
        throw ('Ошибка загрузки данных графика!');
      }
    } catch (e) {
      throw ('Ошибка получения данных!');
    }
  }

  /// Источники лидов (V2)
  /// Endpoint: /api/v2/dashboard/source-of-leads-chart
  Future<SourceOfLeadsChartResponse> getSourceOfLeadsChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/source-of-leads-chart');

    if (kDebugMode) {
      debugPrint('ApiService: getSourceOfLeadsChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SourceOfLeadsChartResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки источников лидов!');
      }
    } catch (e) {
      debugPrint('ApiService: getSourceOfLeadsChartV2 error: $e');
      throw Exception('Ошибка получения источников лидов: $e');
    }
  }

  /// Сделки по менеджерам (V2)
  /// Endpoint: /api/v2/dashboard/deals-by-managers
  Future<DealsByManagersResponse> getDealsByManagersV2() async {
    final path = await _appendQueryParams('/v2/dashboard/deals-by-managers');

    if (kDebugMode) {
      debugPrint('ApiService: getDealsByManagersV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DealsByManagersResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки данных менеджеров!');
      }
    } catch (e) {
      debugPrint('ApiService: getDealsByManagersV2 error: $e');
      throw Exception('Ошибка получения данных менеджеров: $e');
    }
  }

  /// Заказы интернет-магазина (V2)
  /// Endpoint: /api/v2/dashboard/online-store-orders-chart
  Future<OnlineStoreOrdersResponse> getOnlineStoreOrdersChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/online-store-orders-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getOnlineStoreOrdersChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return OnlineStoreOrdersResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки заказов интернет-магазина!');
      }
    } catch (e) {
      debugPrint('ApiService: getOnlineStoreOrdersChartV2 error: $e');
      throw Exception('Ошибка получения заказов интернет-магазина: $e');
    }
  }

  /// Выполненные задачи (график)
  /// Endpoint: /api/v2/dashboard/completed-task-chart
  Future<CompletedTasksChartResponse> getCompletedTasksChartV2() async {
    final path = await _appendQueryParams('/v2/dashboard/completed-task-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getCompletedTasksChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CompletedTasksChartResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки выполненных задач!');
      }
    } catch (e) {
      debugPrint('ApiService: getCompletedTasksChartV2 error: $e');
      throw Exception('Ошибка получения выполненных задач: $e');
    }
  }

  /// Телефония и события (график)
  /// Endpoint: /api/v2/dashboard/telephony-and-events-chart
  Future<TelephonyEventsResponse> getTelephonyAndEventsChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/telephony-and-events-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getTelephonyAndEventsChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TelephonyEventsResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки телефонии и событий!');
      }
    } catch (e) {
      debugPrint('ApiService: getTelephonyAndEventsChartV2 error: $e');
      throw Exception('Ошибка получения телефонии и событий: $e');
    }
  }

  /// Ответы на сообщения (график)
  /// Endpoint: /api/v2/dashboard/replies-to-messages-chart
  Future<RepliesToMessagesResponse> getRepliesToMessagesChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/replies-to-messages-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getRepliesToMessagesChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RepliesToMessagesResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки ответов на сообщения!');
      }
    } catch (e) {
      debugPrint('ApiService: getRepliesToMessagesChartV2 error: $e');
      throw Exception('Ошибка получения ответов на сообщения: $e');
    }
  }

  /// Статистика задач по проектам
  /// Endpoint: /api/v2/dashboard/task-statistics-by-project-chart
  Future<TaskStatsByProjectResponse> getTaskStatsByProjectChartV2() async {
    final path = await _appendQueryParams(
        '/v2/dashboard/task-statistics-by-project-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getTaskStatsByProjectChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TaskStatsByProjectResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки статистики задач по проектам!');
      }
    } catch (e) {
      debugPrint('ApiService: getTaskStatsByProjectChartV2 error: $e');
      throw Exception('Ошибка получения статистики задач по проектам: $e');
    }
  }

  /// Подключенные аккаунты
  /// Endpoint: /api/v2/dashboard/connected-accounts-chart
  Future<ConnectedAccountsResponse> getConnectedAccountsChartV2(
      {int? channel}) async {
    var path =
        await _appendQueryParams('/v2/dashboard/connected-accounts-chart');
    if (channel != null) {
      path += '&channel=$channel';
    }

    if (kDebugMode) {
      debugPrint(
          'ApiService: getConnectedAccountsChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ConnectedAccountsResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки подключенных аккаунтов!');
      }
    } catch (e) {
      debugPrint('ApiService: getConnectedAccountsChartV2 error: $e');
      throw Exception('Ошибка получения подключенных аккаунтов: $e');
    }
  }

  /// ROI рекламы (график)
  /// Endpoint: /api/v2/dashboard/advertising-ROI-chart
  Future<AdvertisingRoiResponse> getAdvertisingRoiChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/advertising-ROI-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getAdvertisingRoiChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AdvertisingRoiResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки ROI рекламы!');
      }
    } catch (e) {
      debugPrint('ApiService: getAdvertisingRoiChartV2 error: $e');
      throw Exception('Ошибка получения ROI рекламы: $e');
    }
  }

  /// Аналитика звонков по часам
  /// Endpoint: /api/v2/dashboard/telephony-and-events-by-hour
  Future<TelephonyByHourResponse> getTelephonyByHourChartV2({
    DateTime? date,
  }) async {
    var path =
        await _appendQueryParams('/v2/dashboard/telephony-and-events-by-hour');
    if (date != null) {
      final oneDay = DateFormat('yyyy/MM/dd').format(date);
      final separator = path.contains('?') ? '&' : '?';
      path +=
          '${separator}date_from=${Uri.encodeComponent(oneDay)}&date_to=${Uri.encodeComponent(oneDay)}';
    }

    if (kDebugMode) {
      debugPrint(
          'ApiService: getTelephonyByHourChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TelephonyByHourResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки аналитики звонков по часам!');
      }
    } catch (e) {
      debugPrint('ApiService: getTelephonyByHourChartV2 error: $e');
      throw Exception('Ошибка получения аналитики звонков по часам: $e');
    }
  }

  /// Таргетированная реклама (Meta Ads)
  /// Endpoint: /api/v2/dashboard/targeted-advertising-chart
  Future<TargetedAdsResponse> getTargetedAdvertisingChartV2(
      {int? projectId}) async {
    var path =
        await _appendQueryParams('/v2/dashboard/targeted-advertising-chart');
    if (projectId != null) {
      path += '&project_id=$projectId';
    }

    if (kDebugMode) {
      debugPrint(
          'ApiService: getTargetedAdvertisingChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TargetedAdsResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки таргетированной рекламы!');
      }
    } catch (e) {
      debugPrint('ApiService: getTargetedAdvertisingChartV2 error: $e');
      throw Exception('Ошибка получения таргетированной рекламы: $e');
    }
  }

  /// ТОП продаваемых товаров (V2)
  /// Endpoint: /api/v2/dashboard/top-selling-products-chart
  Future<TopSellingProductsResponse> getTopSellingProductsChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/top-selling-products-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getTopSellingProductsChartV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TopSellingProductsResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки данных товаров!');
      }
    } catch (e) {
      debugPrint('ApiService: getTopSellingProductsChartV2 error: $e');
      throw Exception('Ошибка получения данных товаров: $e');
    }
  }

//_________________________________ END_____API_SCREEN__DASHBOARD____________________________________________//

//_________________________________ START_____API_SCREEN__DASHBOARD_Manager____________________________________________//

// Метод для получения графика Сделки
  Future<DealStatsResponseManager> getDealStatsManagerData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/dealStats/for-manager');
    if (kDebugMode) {
      //debugPrint('ApiService: getDealStatsManagerData - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DealStatsResponseManager.fromJson(jsonData);
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера!');
      } else {
        throw Exception('Ошибка загрузки данных!');
      }
    } catch (e) {
      ////debugPrint('Ошибка запроса!');
      throw ('');
    }
  }

  /// Получение данных графика для дашборда
  Future<List<ChartDataManager>> getLeadChartManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/lead-chart/for-manager');
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadChartManager - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

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
      //debugPrint('ApiService: getLeadConversionDataManager - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

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
      //debugPrint('ApiService: getProcessSpeedDataManager - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

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
      //debugPrint('ApiService: getTaskChartDataManager - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

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
      //debugPrint('ApiService: getUserStatsManager - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

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

    path = await _appendQueryParams(path);

    if (search != null && search.isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search)}';
    }

    if (salesFunnelId != null && endPoint == 'lead') {
      path += '&funnel_id=$salesFunnelId';
    }

    if (filters != null) {
      if (endPoint == 'lead') {
        // ИСПРАВЛЕНО: Менеджеры - поддержка Map и объектов
        if (filters['managers'] != null &&
            (filters['managers'] as List).isNotEmpty) {
          List<int> managerIds = (filters['managers'] as List).map((m) {
            if (m is Map) {
              return m['id'] as int;
            }
            return m.id as int; // Для объектов ManagerData
          }).toList();
          for (int managerId in managerIds) {
            path += '&managers[]=$managerId';
          }
        }

        // ИСПРАВЛЕНО: Регионы - поддержка Map и объектов
        if (filters['regions'] != null &&
            (filters['regions'] as List).isNotEmpty) {
          List<int> regionIds = (filters['regions'] as List).map((r) {
            if (r is Map) {
              return r['id'] as int;
            }
            return r.id as int; // Для объектов RegionData
          }).toList();
          for (int regionId in regionIds) {
            path += '&regions[]=$regionId';
          }
        }

        // ИСПРАВЛЕНО: Источники - поддержка Map и объектов
        if (filters['sources'] != null &&
            (filters['sources'] as List).isNotEmpty) {
          List<int> sourceIds = (filters['sources'] as List).map((s) {
            if (s is Map) {
              return s['id'] as int;
            }
            return s.id as int; // Для объектов SourceData
          }).toList();
          for (int sourceId in sourceIds) {
            path += '&sources[]=$sourceId';
          }
        }

        // Статусы (без изменений)
        if (filters['statuses'] != null &&
            (filters['statuses'] as List).isNotEmpty) {
          List<String> statusIds = (filters['statuses'] as List).cast<String>();
          for (String statusId in statusIds) {
            path += '&leadStatus[]=$statusId';
          }
        }

        // Даты (без изменений)
        if (filters['fromDate'] != null) {
          path += '&from_date=${filters['fromDate'].toIso8601String()}';
        }
        if (filters['toDate'] != null) {
          path += '&to_date=${filters['toDate'].toIso8601String()}';
        }

        // Флаги (без изменений)
        if (filters['hasSuccessDeals'] == true) {
          path += '&has_success_deals=1';
        }
        if (filters['hasInProgressDeals'] == true) {
          path += '&has_in_progress_deals=1';
        }
        if (filters['hasFailureDeals'] == true) {
          path += '&has_failure_deals=1';
        }
        if (filters['hasNotices'] == true) {
          path += '&has_notices=1';
        }
        if (filters['hasContact'] == true) {
          path += '&has_contact=1';
        }
        if (filters['hasChat'] == true) {
          path += '&has_chat=1';
        }
        if (filters['hasNoReplies'] == true) {
          path += '&has_no_replies=1';
        }
        if (filters['hasUnreadMessages'] == true) {
          path += '&unread_only=1';
        }
        if (filters['hasDeal'] == true) {
          path += '&has_deal=1';
        }
        if (filters['unreadOnly'] == true) {
          path += '&unread_only=1';
        }
        if (filters['daysWithoutActivity'] != null &&
            filters['daysWithoutActivity'] > 0) {
          path += '&days_without_activity=${filters['daysWithoutActivity']}';
        }
        if (filters['directory_values'] != null &&
            (filters['directory_values'] as List).isNotEmpty) {
          List<Map<String, dynamic>> directoryValues =
              filters['directory_values'] as List<Map<String, dynamic>>;
          for (var value in directoryValues) {
            path +=
                '&directory_values[${value['directory_id']}]=${value['entry_id']}';
          }
        }
      } else if (endPoint == 'task') {
        // Обработка фильтров для task (без изменений)
        if (filters['task_number'] != null &&
            filters['task_number'].isNotEmpty) {
          path += '&task_number=${Uri.encodeComponent(filters['task_number'])}';
        }
        if (filters['department_id'] != null) {
          path += '&department_id=${filters['department_id']}';
        }
        if (filters['task_created_from'] != null) {
          path += '&task_created_from=${filters['task_created_from']}';
        }
        if (filters['task_created_to'] != null) {
          path += '&task_created_to=${filters['task_created_to']}';
        }
        if (filters['deadline_from'] != null) {
          path += '&deadline_from=${filters['deadline_from']}';
        }
        if (filters['deadline_to'] != null) {
          path += '&deadline_to=${filters['deadline_to']}';
        }
        if (filters['executor_ids'] != null &&
            (filters['executor_ids'] as List).isNotEmpty) {
          List<String> executorIds = (filters['executor_ids'] as List)
              .map((id) => id.toString())
              .toList();
          for (String executorId in executorIds) {
            path += '&executor_ids[]=$executorId';
          }
        }
        if (filters['author_ids'] != null &&
            (filters['author_ids'] as List).isNotEmpty) {
          List<int> authorIds = (filters['author_ids'] as List).cast<int>();
          for (int authorId in authorIds) {
            path += '&author_ids[]=$authorId';
          }
        }
        if (filters['project_ids'] != null &&
            (filters['project_ids'] as List).isNotEmpty) {
          List<int> projectIds = (filters['project_ids'] as List).cast<int>();
          for (int projectId in projectIds) {
            path += '&project_ids[]=$projectId';
          }
        }
        if (filters['task_status_ids'] != null &&
            (filters['task_status_ids'] as List).isNotEmpty) {
          List<int> taskStatusIds =
              (filters['task_status_ids'] as List).cast<int>();
          for (int statusId in taskStatusIds) {
            path += '&task_status_ids[]=$statusId';
          }
        }
        if (filters['unread_only'] == true) {
          path += '&unread_only=1';
        }
      }
    }

    final fullUrl = '$baseUrl$path';

    // ДОБАВЛЕНО: Отладочный вывод
    debugPrint('ApiService.getAllChats: Final URL: $fullUrl');

    try {
      // ДОБАВЛЕНО: Timeout для диагностики медленных ответов бэкенда
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'FlutterApp/1.0',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 302) {
        throw Exception('Получен редирект 302. Проверьте URL и авторизацию.');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          final pagination = PaginationDTO<Chats>.fromJson(data['result'], (e) {
            return Chats.fromJson(e);
          });
          return pagination;
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService.getAllChats: Error: $e');
      rethrow;
    }
  }

  Future<String> getDynamicBaseUrlFixed() async {
    // Сначала проверяем кешированное значение
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedBaseUrl = prefs.getString('cached_base_url');

    if (cachedBaseUrl != null &&
        cachedBaseUrl.isNotEmpty &&
        cachedBaseUrl != 'null') {
      if (kDebugMode) {
        debugPrint('ApiService: Using cached baseUrl: $cachedBaseUrl');
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

    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('🔍 [getChatById] Requesting: $baseUrl$path');

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

    debugPrint('📥 [getChatById] Status: ${response.statusCode}');
    debugPrint('📥 [getChatById] Full Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // ✅ ЛОГИРУЕМ СТРУКТУРУ ВЕРХНЕГО УРОВНЯ
      debugPrint('📊 [getChatById] Top-level keys: ${data.keys.toList()}');

      if (data['result'] != null) {
        final result = data['result'];

        // ✅ ЛОГИРУЕМ СТРУКТУРУ result
        debugPrint('📊 [getChatById] Result keys: ${result.keys.toList()}');
        debugPrint('📊 [getChatById] Result type: ${result['type']}');
        debugPrint('📊 [getChatById] Result name: "${result['name']}"');
        debugPrint('📊 [getChatById] Result group: ${result['group']}');
        debugPrint(
            '📊 [getChatById] Result chatUsers type: ${result['chatUsers']?.runtimeType}');
        debugPrint(
            '📊 [getChatById] Result chatUsers length: ${result['chatUsers']?.length}');

        if (result['chatUsers'] != null && result['chatUsers'] is List) {
          debugPrint('📊 [getChatById] ChatUsers content:');
          for (var i = 0; i < (result['chatUsers'] as List).length; i++) {
            final user = result['chatUsers'][i];
            debugPrint(
                '   [$i] type: ${user['type']}, participant: ${user['participant']?['name']}');
          }
        }

        debugPrint('════════════════════════════════════════════════════════');

        return ChatsGetId.fromJson(result);
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
      //debugPrint('ApiService: sendMessages - Generated path: $path');
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
    String? chatType, // Тип чата: 'lead', 'corporate', 'task'
  }) async {
    try {
      final token = await getToken();
      // ✅ Обновляем userID.value, чтобы Message.fromJson корректно определял isMyMessage
      try {
        if (userID.value.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final storedUserId = prefs.getString('userID') ?? '';
          if (storedUserId.isNotEmpty) {
            userID.value = storedUserId;
          }
        }
      } catch (_) {}

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

          // 🔍 ДИАГНОСТИКА: Логируем первое сообщение для проверки структуры
          if (messagesList.isNotEmpty) {
            debugPrint('🔍 API ДИАГНОСТИКА - Структура первого сообщения:');
            final firstMsg = messagesList[0];
            debugPrint('   Полное сообщение: $firstMsg');
            debugPrint('   ---');
          }

          return messagesList.map((msgData) {
            try {
              // Передаём chatType при парсинге сообщения
              return Message.fromJson(msgData as Map<String, dynamic>,
                  chatType: chatType);
            } catch (e) {
              debugPrint('Error parsing message: $e, data: $msgData');
              // Возвращаем пустое сообщение с базовыми полями
              return Message(
                id: msgData['id'] ?? -1,
                text:
                    msgData['text']?.toString() ?? 'Ошибка загрузки сообщения',
                type: msgData['type']?.toString() ?? 'text',
                createMessateTime: msgData['created_at']?.toString() ??
                    DateTime.now().toIso8601String(),
                isMyMessage: false,
                senderName: msgData['sender']?['name']?.toString() ??
                    'Неизвестный отправитель',
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
      //debugPrint('ApiService: closeChatSocket - Generated path: $path');
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
      //debugPrint('ApiService: getIntegrationForLead - Generated path: $path');
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
      // debug//debugPrint('API response: $data'); // Лог для отладки
      if (data['result'] != null) {
        return IntegrationForLead.fromJson(data['result']);
      } else {
        // debug//debugPrint('Integration not found in response: $data');
        throw Exception('Интеграция не найдена в ответе');
      }
    } else {
      // debug//debugPrint('API error: ${response.statusCode}, body: ${response.body}');
      throw Exception(
          'Ошибка ${response.statusCode}: Не удалось получить интеграцию');
    }
  }

// Метод для отправки текстового сообщения
  Future<void> sendMessage(int chatId, String message,
      {String? replyMessageId, String? responseType}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendMessage/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: sendMessage - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'message': message,
      if (replyMessageId != null) 'forwarded_message_id': replyMessageId,
      if (responseType != null) 'response_type': responseType,
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки сообщения!');
    }
  }

  Future<void> pinMessage(String messageId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/pinMessage/$messageId');
    if (kDebugMode) {
      //debugPrint('ApiService: pinMessage - Generated path: $path');
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
      //debugPrint('ApiService: unpinMessage - Generated path: $path');
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
      //debugPrint('ApiService: editMessage - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'message': message,
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка изменения сообщения!');
    }
  }

// Метод для отправки audio file
  Future<void> sendChatAudioFile(int chatId, File audio,
      {String? responseType}) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendVoice/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: sendChatAudioFile - Generated path: $path');
    }

    String requestUrl = '$baseUrl$path';

    Dio dio = LoggedDioClient.create();
    try {
      final voice = await MultipartFile.fromFile(audio.path,
          contentType: MediaType('audio', 'm4a'));
      FormData formData = FormData.fromMap({
        'voice': voice,
        if (responseType != null) 'response_type': responseType,
      });

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
        ////debugPrint('response.statusCode!');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          ////debugPrint('Audio message sent successfully!');
        }
      } else {
        if (kDebugMode) {
          ////debugPrint('Error sending audio message: ${response.data}');
        }
        throw Exception('Error sending audio message: ${response.data}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        ////debugPrint('Exception caught!');
      }
      if (kDebugMode) {
        ////debugPrint(e.response?.data);
      }
      throw Exception('Failed to send audio message due to an exception!');
    }
  }

// Метод для отправки audio file
  Future<void> sendChatFile(int chatId, String pathFile,
      {String? responseType}) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendFile/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: sendChatFile - Generated path: $path');
    }

    String requestUrl = '$baseUrl$path';

    Dio dio = LoggedDioClient.create();
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(pathFile),
        if (responseType != null) 'response_type': responseType,
      });

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
        ////debugPrint('response.statusCode!');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          ////debugPrint('Audio message sent successfully!');
        }
      } else {
        if (kDebugMode) {
          ////debugPrint('Error sending audio message: ${response.data}');
        }
        throw Exception('Error sending audio message: ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        ////debugPrint('Exception caught!');
      }
      throw Exception('Failed to send audio message due to an exception!');
    }
  }

// Метод для отправки файла
  Future<void> sendFile(int chatId, String filePath) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/sendFile/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: sendFile - Generated path: $path');
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
      //debugPrint('ApiService: sendVoice - Generated path: $path');
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
//         ////debugPrint('Messages marked as read');
//       } else {
//         ////debugPrint('Error marking messages as read!');
//       }
//     } catch (e) {
//       ////debugPrint('Exception when marking messages as read!');
//     }
//   }

  // Метод для удаления чата
  Future<Map<String, dynamic>> deleteChat(int chatId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/v2/chat/$chatId');
      if (kDebugMode) {
        //debugPrint('ApiService: deleteChat - Generated path: $path');
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
      //debugPrint('ApiService: getAllUser - Generated path: $path');
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
        //debugPrint('ApiService: getAllUser - Response: $data');
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
      //debugPrint('ApiService: getAnotherUsers - Generated path: $path');
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
      // ////debugPrint('Статус ответа!');
    }
    if (kDebugMode) {
      // ////debugPrint('getAll user!');
    }

    return dataUser;
  }

// addUserToGroup
  Future<UsersDataResponse> getUsersNotInChat(String chatId) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/user/users-not-in-chat/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: getUsersNotInChat - Generated path: $path');
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
      // ////debugPrint('Статус ответа!');
    }
    if (kDebugMode) {
      // ////debugPrint('getUsersNotInChat!');
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
      //debugPrint('ApiService: getUsersWihtoutCorporateChat - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    ////debugPrint(
    // '----------------------------------------------------------------------');
    ////debugPrint(
    // '-------------------------------getUsersWihtoutCorporateChat---------------------------------------');
    ////debugPrint(response);

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
      // ////debugPrint('Статус ответа!');
    }
    if (kDebugMode) {
      // ////debugPrint('getAll user!');
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
          debugPrint(
              'ApiService: createNewClient - Using fallback organization_id=1');
        }
      }

      if (kDebugMode) {
        debugPrint('ApiService: createNewClient - Base URL: $baseUrl');
        debugPrint('ApiService: createNewClient - Generated path: $path');
        debugPrint('ApiService: createNewClient - Token: $token');
        debugPrint(
            'ApiService: createNewClient - Organization ID: $organizationId');
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
        debugPrint(
            'ApiService: createNewClient - Status code: ${response.statusCode}');
        debugPrint(
            'ApiService: createNewClient - Response body: ${response.body}');
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
        debugPrint('ApiService: createNewClient - Error: $e');
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
        //debugPrint('ApiService: createGroupChat - Generated path: $path');
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
        //debugPrint('ApiService: addUserToGroup - Generated path: $path');
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
        //debugPrint('ApiService: deleteUserFromGroup - Generated path: $path');
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
      //debugPrint('ApiService: DeleteMessage - Generated path: $path');
    }

    ////debugPrint('Sending DELETE request to API with path: $path');

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

    // Проверяем инициализацию baseUrl
    if (baseUrl == null || baseUrl!.isEmpty || baseUrl == 'null') {
      await initialize();
      if (baseUrl == null || baseUrl!.isEmpty || baseUrl == 'null') {
        throw Exception('Base URL не может быть инициализирован');
      }
    }

    final path = await _appendQueryParams('/v2/chat/templates');
    if (kDebugMode) {
      //debugPrint('ApiService: getTemplates - Generated path: $path');
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
        //debugPrint('ApiService: getChatProfile - Generated path: $path');
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
        ////debugPrint('Ошибка загрузки профиля чата!');
        throw Exception('${response.statusCode}');
      }
    } catch (e) {
      ////debugPrint('Ошибка в getChatProfile!');
      throw ('Ошибка загрузки профиля чата!');
    }
  }

  Future<TaskProfile> getTaskProfile(int chatId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task/getByChat/$chatId');
      if (kDebugMode) {
        //debugPrint('ApiService: getTaskProfile - Generated path: $path');
      }

      ////debugPrint('Organization ID: $organizationId'); // Добавим логирование

      final response = await _getRequest(path);

      ////debugPrint('Response status code!'); // Логируем статус ответа
      ////debugPrint('Response body!'); // Логируем тело ответа

      if (response.statusCode == 200) {
        try {
          final dynamic decodedJson = json.decode(response.body);
          ////debugPrint(
          // 'Decoded JSON type: ${decodedJson.runtimeType}'); // Логируем тип декодированного JSON
          ////debugPrint('Decoded JSON: $decodedJson'); // Отладочный вывод

          if (decodedJson is Map<String, dynamic>) {
            if (decodedJson['result'] != null) {
              ////debugPrint(
              // 'Result type: ${decodedJson['result'].runtimeType}'); // Логируем тип результата
              return TaskProfile.fromJson(decodedJson['result']);
            } else {
              ////debugPrint('Result is null');
              throw Exception('Данные задачи не найдены');
            }
          } else {
            ////debugPrint('Decoded JSON is not a Map: ${decodedJson.runtimeType}');
            throw Exception('Неверный формат ответа');
          }
        } catch (parseError) {
          ////debugPrint('Ошибка парсинга JSON: $parseError');
          throw Exception('Ошибка парсинга ответа: $parseError');
        }
      } else {
        ////debugPrint('Ошибка загрузки задачи!');
        throw Exception('Ошибка загрузки задачи!');
      }
    } catch (e) {
      ////debugPrint('Полная ошибка в getTaskProfile!');
      ////debugPrint('Трассировка стека: ${StackTrace.current}');
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
      //debugPrint('ApiService: readMessages - Путь: $path, messageId: $messageId, token: $token');
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
        //debugPrint('ApiService.readMessages: Код ответа: ${response.statusCode}');
        //debugPrint('ApiService.readMessages: Тело ответа: ${response.body}');
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
        //debugPrint('ApiService.readMessages: Поймано исключение: $e');
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
      //debugPrint('ApiService: getOrganization - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Тело ответа: $data'); // Для отладки

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

      debugPrint(
          'ApiService: getSelectedOrganization - orgId: $organizationId');

      // Возвращаем null если организация не найдена или содержит 'null'
      if (organizationId == null ||
          organizationId.isEmpty ||
          organizationId == 'null') {
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
      debugPrint(
          'ApiService: saveSelectedOrganization - Saved: $organizationId');
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
      //debugPrint('ApiService: logoutAccount - Generated path: $path');
    }

    final response = await _postRequest(path, {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка logout аккаунта!');
    }
  }

// Существующий метод для получения выбранной воронки
  Future<String?> getSelectedSalesFunnel() async {
    debugPrint(
        '🔍 ApiService: Getting selected sales funnel from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final funnelId = prefs.getString('selected_sales_funnel');

    if (funnelId == null || funnelId.isEmpty || funnelId == 'null') {
      debugPrint(
          '⚠️ ApiService: No valid funnel ID found in SharedPreferences');
      return null;
    }

    debugPrint('✅ ApiService: Retrieved selected funnel ID: $funnelId');
    return funnelId;
  }

  /// Гарантирует, что selected_sales_funnel сохранён до первых запросов Dashboard.
  /// Порядок: SharedPreferences -> кэш воронок -> API /sales-funnel.
  Future<String?> ensureSelectedSalesFunnelInitialized() async {
    final existing = await getSelectedSalesFunnel();
    if (existing != null && existing.isNotEmpty && existing != 'null') {
      return existing;
    }

    try {
      final cachedFunnels = await getCachedSalesFunnels();
      if (cachedFunnels.isNotEmpty) {
        final funnelId = cachedFunnels.first.id.toString();
        await saveSelectedSalesFunnel(funnelId);
        return funnelId;
      }
    } catch (e) {
      debugPrint(
          'ApiService: ensureSelectedSalesFunnelInitialized cache error: $e');
    }

    try {
      final serverFunnels = await getSalesFunnels();
      if (serverFunnels.isNotEmpty) {
        final funnelId = serverFunnels.first.id.toString();
        await saveSelectedSalesFunnel(funnelId);
        return funnelId;
      }
    } catch (e) {
      debugPrint(
          'ApiService: ensureSelectedSalesFunnelInitialized API error: $e');
    }

    return null;
  }

// Существующий метод для сохранения выбранной воронки
  Future<void> saveSelectedSalesFunnel(String funnelId) async {
    debugPrint('🔧 ApiService: Saving selected sales funnel ID: $funnelId');
    if (funnelId.isEmpty || funnelId == 'null') {
      debugPrint(
          '⚠️ ApiService: Attempting to save invalid funnelId: $funnelId');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_sales_funnel', funnelId);

    // Проверяем, что сохранилось
    final saved = prefs.getString('selected_sales_funnel');
    if (saved == funnelId) {
      debugPrint(
          '✅ ApiService: Selected sales funnel ID saved successfully: $funnelId');
    } else {
      debugPrint(
          '❌ ApiService: Failed to save funnel ID. Expected: $funnelId, Got: $saved');
    }
  }

  Future<void> saveSelectedDealSalesFunnel(String funnelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deal_selected_sales_funnel', funnelId);
    //debugPrint('ApiService: Saved deal funnel ID $funnelId to SharedPreferences');
  }

  Future<String?> getSelectedDealSalesFunnel() async {
    final prefs = await SharedPreferences.getInstance();
    final funnelId = prefs.getString('deal_selected_sales_funnel');
    //debugPrint('ApiService: Retrieved deal funnel ID $funnelId from SharedPreferences');
    return funnelId;
  }

  Future<void> saveSelectedEventSalesFunnel(String funnelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('event_selected_sales_funnel', funnelId);
    //debugPrint('ApiService: Saved event funnel ID $funnelId to SharedPreferences');
  }

  Future<String?> getSelectedEventSalesFunnel() async {
    final prefs = await SharedPreferences.getInstance();
    final funnelId = prefs.getString('event_selected_sales_funnel');
    //debugPrint('ApiService: Retrieved event funnel ID $funnelId from SharedPreferences');
    return funnelId;
  }

  Future<void> saveSelectedChatSalesFunnel(String funnelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      //debugPrint('ApiService.saveSelectedChatSalesFunnel: Saving funnelId: $funnelId');
      final success =
          await prefs.setString('selected_chat_sales_funnel', funnelId);
      //debugPrint('ApiService.saveSelectedChatSalesFunnel: Save success: $success');

      // Проверяем, что значение сохранено
      final savedFunnelId = prefs.getString('selected_chat_sales_funnel');
      //debugPrint('ApiService.saveSelectedChatSalesFunnel: Verified saved funnelId: $savedFunnelId');
      if (savedFunnelId != funnelId) {
        //debugPrint('ApiService.saveSelectedChatSalesFunnel: Warning - saved funnelId ($savedFunnelId) does not match input ($funnelId)');
      }
    } catch (e) {
      //debugPrint('ApiService.saveSelectedChatSalesFunnel: Error saving funnelId: $e');
      rethrow;
    }
  }

  Future<String?> getSelectedChatSalesFunnel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedFunnel = prefs.getString('selected_chat_sales_funnel');
      //debugPrint('ApiService.getSelectedChatSalesFunnel: Retrieved funnelId: $selectedFunnel');
      return selectedFunnel;
    } catch (e) {
      //debugPrint('ApiService.getSelectedChatSalesFunnel: Error retrieving funnelId: $e');
      return null;
    }
  }

// Новый метод для сохранения списка воронок в кэш
  Future<void> cacheSalesFunnels(List<SalesFunnel> funnels) async {
    //debugPrint('ApiService: Caching sales funnels');
    final prefs = await SharedPreferences.getInstance();
    final funnelsJson = funnels.map((funnel) => funnel.toJson()).toList();
    await prefs.setString('cached_sales_funnels', json.encode(funnelsJson));
    //debugPrint('ApiService: Cached ${funnels.length} sales funnels');
  }

// Новый метод для получения списка воронок из кэша
  Future<List<SalesFunnel>> getCachedSalesFunnels() async {
    //debugPrint('ApiService: Retrieving cached sales funnels');
    final prefs = await SharedPreferences.getInstance();
    final funnelsJson = prefs.getString('cached_sales_funnels');
    if (funnelsJson != null) {
      final List<dynamic> decoded = json.decode(funnelsJson);
      final funnels =
          decoded.map((json) => SalesFunnel.fromJson(json)).toList();
      //debugPrint(
      // 'ApiService: Retrieved ${funnels.length} cached sales funnels: $funnels');
      return funnels;
    }
    //debugPrint('ApiService: No cached sales funnels found');
    return [];
  }

// Новый метод для очистки кэша воронок
  Future<void> clearCachedSalesFunnels() async {
    //debugPrint('ApiService: Clearing cached sales funnels');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_sales_funnels');
    //debugPrint('ApiService: Cached sales funnels cleared');
  }

// Предполагаемый существующий метод для загрузки воронок с сервера
  Future<List<SalesFunnel>> getSalesFunnels() async {
    //debugPrint('ApiService: Starting getSalesFunnels request');
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/sales-funnel');
    if (kDebugMode) {
      //debugPrint('ApiService: getSalesFunnels - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      //debugPrint(
      // 'ApiService: getSalesFunnels response status: ${response.statusCode}');
      //debugPrint('ApiService: getSalesFunnels response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        //debugPrint('ApiService: Decoded JSON data: $data');

        if (data['result'] != null && data['result'] is List) {
          List<SalesFunnel> funnels = (data['result'] as List)
              .map((funnel) => SalesFunnel.fromJson(funnel))
              .toList();
          //debugPrint('ApiService: Parsed ${funnels.length} sales funnels: $funnels');
          // Сохраняем воронки в кэш после успешной загрузки
          await cacheSalesFunnels(funnels);
          return funnels;
        } else {
          //debugPrint('ApiService: No funnels found in response');
          throw Exception('Воронки продаж не найдены');
        }
      } else {
        //debugPrint('ApiService: Failed with status code ${response.statusCode}');
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      //debugPrint('ApiService: Error in getSalesFunnels');
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
      // Парсим существующий URI
      final uri = Uri.parse(path);
      // Используем queryParametersAll для сохранения всех значений (включая повторяющиеся ключи)
      final existingParamsAll =
          Map<String, List<String>>.from(uri.queryParametersAll);
      // Получаем ID из SharedPreferences
      final organizationId = await getSelectedOrganization();
      final salesFunnelId = await getSelectedSalesFunnel();

      // ✅ Добавляем organization_id ТОЛЬКО если его нет
      if (organizationId != null &&
          organizationId.isNotEmpty &&
          organizationId != 'null' &&
          !existingParamsAll.containsKey('organization_id')) {
        existingParamsAll['organization_id'] = [organizationId];
      }

      // ✅ Добавляем sales_funnel_id ТОЛЬКО если его нет
      if (salesFunnelId != null &&
          salesFunnelId.isNotEmpty &&
          salesFunnelId != 'null' &&
          !existingParamsAll.containsKey('sales_funnel_id')) {
        existingParamsAll['sales_funnel_id'] = [salesFunnelId];
      }

      // Собираем query string вручную для сохранения всех значений
      final queryParts = <String>[];
      existingParamsAll.forEach((key, values) {
        for (final value in values) {
          queryParts
              .add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
        }
      });

      final queryString =
          queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
      final result = '${uri.path}$queryString';

      debugPrint('✅ _appendQueryParams: $path → $result');
      return result;
    } catch (e) {
      debugPrint('❌ _appendQueryParams error: $e');
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

// Замените метод DeleteAllNotifications на это:

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

// Метод для удаления Уведомлений
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

//_________________________________ END_____API_SCREEN__NOTIFICATIONS____________________________________________//

//_________________________________ START_____API_PROFILE_SCREEN____________________________________________//

//Метод для получения Пользователя через его ID
  Future<UserByIdProfile> getUserById(int userId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/user/$userId');
      if (kDebugMode) {
        //debugPrint('ApiService: getUserById - Generated path: $path');
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
          ////debugPrint('unique_id сохранён: ${userProfile.uniqueId}');
        } else {
          ////debugPrint('unique_id не получен от сервера');
        }

        return userProfile;
      } else {
        throw Exception('Ошибка загрузки User ID: ${response.statusCode}');
      }
    } catch (e) {
      ////debugPrint('Ошибка загрузки User ID: $e');
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
        //debugPrint('ApiService: updateProfile - Generated path: $path');
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
      final response = await _multipartPostRequest('', request);

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
        //debugPrint('ApiService: getMyTaskById - Generated path: $path');
      }

      final response = await _getRequest(path);

      ////debugPrint('Response status code: ${response.statusCode}');
      ////debugPrint('Response body: ${response.body}');

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
      ////debugPrint('Error in getMyTaskById: $e');
      throw ('Ошибка загрузки task ID');
    }
  }

  Future<bool> checkOverdueTasks() async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task/check/overdue');
      if (kDebugMode) {
        //debugPrint('ApiService: checkOverdueTasks - Generated path: $path');
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
      //debugPrint('ApiService: getMyTasks - Generated path: $path');
    }

    // Логируем конечный URL запроса
    // ////debugPrint('Sending request to API with path: $path');
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
      ////debugPrint('Error response! - ${response.body}');
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
        //debugPrint('ApiService: getMyTaskStatuses - Generated path: $path');
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
          // ////debugPrint(
          //     '------------------------------------ Новые данные, которые сохраняются в кэш ---------------------------------');
          // ////debugPrint(data['result']); // Новые данные, которые будут сохранены в кэш

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
      ////debugPrint('Ошибка загрузки статусов задач. Используем кэшированные данные.');
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
      ////debugPrint('Error while checking if status has deals!');
      return false;
    }
  }

// Обновление статуса карточки Задачи в колонке
  Future<void> updateMyTaskStatus(
      int taskId, int position, int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-task/change-status/$taskId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateMyTaskStatus - Generated path: $path');
    }

    final response = await _postRequest(path, {
      'position': 1,
      'status_id': statusId,
    });

    if (response.statusCode == 200) {
      ////debugPrint('Статус задачи успешно обновлен');
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
        //debugPrint('ApiService: CreateMyTaskStatusAdd - Generated path: $path');
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
    List<Map<String, dynamic>>? customFields,
    List<Map<String, int>>? directoryValues,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/my-task');
      if (kDebugMode) {
        //debugPrint('ApiService: createMyTask - Generated path: $path');
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

      // Добавляем кастомные поля
      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          final field = customFields[i];
          request.fields['custom_fields[$i][key]'] = field['key'].toString();
          request.fields['custom_fields[$i][value]'] =
              field['value'].toString();
          request.fields['custom_fields[$i][type]'] = field['type'].toString();
        }
      }

      // Добавляем справочники
      if (directoryValues != null && directoryValues.isNotEmpty) {
        for (int i = 0; i < directoryValues.length; i++) {
          final directory = directoryValues[i];
          request.fields['directories[$i][directory_id]'] =
              directory['directory_id'].toString();
          request.fields['directories[$i][entry_id]'] =
              directory['entry_id'].toString();
        }
      }

      // Отправляем запрос
      final response = await _multipartPostRequest('', request);

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
      ////debugPrint('Detailed error: $e');
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
        //debugPrint('ApiService: updateMyTask - Generated path: $path');
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
      final response = await _multipartPostRequest('', request);

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
      ////debugPrint('Detailed error: $e');
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
        //debugPrint('ApiService: getMyTaskHistory - Generated path: $path');
      }

      // Используем метод _getRequest вместо прямого выполнения запроса
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => MyTaskHistory.fromJson(json)).toList();
      } else {
        ////debugPrint('Failed to load task history!');
        throw Exception('Ошибка загрузки истории задач!');
      }
    } catch (e) {
      ////debugPrint('Error occurred!');
      throw Exception('Ошибка загрузки истории задач!');
    }
  }

// Метод для получения Статуса задачи
  Future<List<MyStatusName>> getMyStatusName() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/my-taskStatusName');
    if (kDebugMode) {
      //debugPrint('ApiService: getMyStatusName - Generated path: $path');
    }

    ////debugPrint('Начало запроса статусов задач'); // Отладочный вывод
    final response = await _getRequest(path);
    ////debugPrint('Статус код ответа!'); // Отладочный вывод

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные: $data'); // Отладочный вывод

      if (data['result'] != null) {
        final statusList = (data['result'] as List)
            .map((name) => MyStatusName.fromJson(name))
            .toList();
        ////debugPrint(
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
      //debugPrint('ApiService: deleteMyTask - Generated path: $path');
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
      //debugPrint('ApiService: deleteMyTaskStatuses - Generated path: $path');
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
      //debugPrint('ApiService: finishMyTask - Generated path: $path');
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
      //debugPrint('ApiService: getMyCustomFields - Generated path: $path');
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
      //debugPrint('ApiService: getMyTaskStatus - Generated path: $path');
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
      //debugPrint('ApiService: updateMyTaskStatusEdit - Generated path: $path');
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
        //debugPrint('ApiService: getEvents - Generated path: $path');
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
        //debugPrint('ApiService: getNoticeById - Generated path: $path');
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
        //debugPrint('ApiService: createNotice - Generated path: $path');
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
      //debugPrint('ApiService: updateNotice - Generated path: $path');
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
      //debugPrint('ApiService: deleteNotice - Generated path: $path');
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
      //debugPrint('ApiService: finishNotice - Generated path: $path');
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
      //debugPrint('ApiService: getAllSubjects - Generated path: $path');
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
      //debugPrint('ApiService: getAllAuthor - Generated path: $path');
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
      // ////debugPrint('Статус ответа!');
    }
    if (kDebugMode) {
      // ////debugPrint('getAll author!');
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
      //debugPrint('ApiService: getTutorialProgress - Generated path: $path');
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
      //debugPrint('ApiService: getSettings - Generated path: $path');
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
      //debugPrint('ApiService: getMiniAppSettings - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rawList = <dynamic>[];
      final result = data['result'];

      if (result is List) {
        rawList.addAll(result);
      } else if (result is Map<String, dynamic>) {
        if (result['data'] is List) {
          rawList.addAll(result['data'] as List<dynamic>);
        } else if (result['items'] is List) {
          rawList.addAll(result['items'] as List<dynamic>);
        }
      }

      if (kDebugMode) {
        debugPrint(
            'ApiService: getMiniAppSettings - parsed items count: ${rawList.length}');
        if (rawList.isEmpty) {
          debugPrint(
              'ApiService: getMiniAppSettings - empty body: ${response.body}');
        }
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => MiniAppSettings.fromJson(item))
          .toList();
    } else {
      throw Exception(
          'Failed to get mini-app settings: ${response.statusCode}');
    }
  }

  Future<void> markPageCompleted(String section, String pageType) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/tutorials/markPageCompleted');
    if (kDebugMode) {
      //debugPrint('ApiService: markPageCompleted - Generated path: $path');
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
      //debugPrint('ApiService: getAllCharacteristics - Generated path: $path');
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
      //debugPrint('ApiService: getCategory - Generated path: $path');
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
        //debugPrint('ApiService: getSubCategoryById - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        ////debugPrint(decodedJson);
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
        //debugPrint('ApiService: createCategory - Generated path: $path');
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

      final response = await _multipartPostRequest('', request);

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
        //debugPrint('ApiService: updateCategory - Generated path: $path');
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

      final response = await _multipartPostRequest('', request);
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
      //debugPrint('ApiService: deleteCategory - Generated path: $path');
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
        //debugPrint('ApiService: updateSubCategory - Generated path: $path');
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

      final response = await _multipartPostRequest('', request);
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
          //debugPrint('ApiService: Добавлены label_id: $labelIds');
        }
      }

      if (filters.containsKey('is_active')) {
        path += '&is_active=${filters['is_active'] ? 1 : 0}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр is_active: ${filters['is_active']}');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getGoods - Generated path: $path');
    }

    final response = await _getRequest(path);
    if (kDebugMode) {
      //debugPrint(
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
          //debugPrint(
          // 'ApiService: Успешно получено ${goods.length} товаров, всего: $total, страниц: $totalPages');
        }
        return goods;
      } else {
        if (kDebugMode) {
          //debugPrint('ApiService: Ошибка формата данных: $data');
        }
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      if (kDebugMode) {
        //debugPrint('ApiService: Ошибка загрузки товаров: ${response.statusCode}');
      }
      throw Exception('Ошибка загрузки товаров: ${response.statusCode}');
    }
  }

  Future<VariantResponse> getVariants({
    int page = 1,
    int perPage = 15,
    String? search,
    Map<String, dynamic>? filters,
    bool? isService,
  }) async {
    String path = '/good/get/variant?page=$page&per_page=$perPage';

    if (isService != null) {
      path += '&is_service=${isService ? 1 : 0}';
    }

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    if (filters != null) {
      // Добавляем counterparty_id
      if (filters.containsKey('counterparty_id')) {
        path += '&counterparty_id=${filters['counterparty_id']}';
      }

      // Добавляем storage_id
      if (filters.containsKey('storage_id')) {
        path += '&storage_id=${filters['storage_id']}';
      }

      if (filters.containsKey('category_id')) {
        final categoryId = filters['category_id'];
        if (categoryId is int) {
          path += '&category_id=$categoryId';
        }
      }

      if (filters.containsKey('is_active')) {
        path += '&is_active=${filters['is_active'] ? 1 : 0}';
      }
    }

    path = await _appendQueryParams(path);

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        return VariantResponse.fromJson(data['result'] as Map<String, dynamic>);
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
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
      //debugPrint('ApiService: getGoodsById - Generated path: $updatedPath');
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
      //debugPrint('ApiService: getSubCategoryAttributes - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      ////debugPrint('Response data: $data'); // Debug: //print the response
      if (data.containsKey('data')) {
        return (data['data'] as List).map((item) {
          ////debugPrint('Item: $item'); // Debug: //print each item
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
    required bool isService,
    required String name,
    required int parentId,
    required String description,
    required int quantity,
    required int? unitId,
    required List<Map<String, dynamic>> attributes,
    required List<Map<String, dynamic>> variants,
    required List<File> images,
    required bool isActive,
    // double? discountPrice,
    double? price,
    int? storageId,
    int? mainImageIndex,
    int? labelId, // Parameter for label ID
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/good');
      if (kDebugMode) {
        //debugPrint('ApiService: createGoods - Generated path: $path');
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
      request.fields['unit_id'] = unitId.toString();
      request.fields['is_active'] = isActive ? '1' : '0';
      request.fields['is_service'] = isService ? '1' : '0';

      // Pass the actual labelId if it exists
      if (labelId != null) {
        request.fields['label_id'] = labelId.toString();
      }

      if (price != null) {
        request.fields['price'] = price.toString();
      }

      // if (discountPrice != null) {
      //   request.fields['discount_price'] = discountPrice.toString();
      // }

      if (storageId != null) {
        request.fields['storage_id'] = storageId.toString();
        request.fields['branch_id'] = storageId.toString();
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

      final response = await _multipartPostRequest('', request);
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
      // //debugPrint('ApiService: Error in createGoods: $e');
      // //debugPrint('ApiService: Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Произошла ошибка',
      };
    }
  }

  Future<Map<String, dynamic>> updateGoods({
    required bool isService,
    required int goodId,
    required String name,
    required int parentId,
    required String description,
    required int quantity,
    int? unitId,
    required List<Map<String, dynamic>> attributes,
    required List<Map<String, dynamic>> variants,
    required List<File> images,
    required bool isActive,
    double? discountPrice,
    required int? storageId,
    String? comments,
    int? mainImageIndex,
    int? labelId, // Добавляем параметр для ID метки
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/good/$goodId');
      if (kDebugMode) {
        //debugPrint('ApiService: updateGoods - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile',
        'Content-Type': 'multipart/form-data; charset=utf-8',
      });

      ////debugPrint('ApiService: Sending updateGoods request:');
      ////debugPrint('ApiService: goodId: $goodId, name: $name, parentId: $parentId, description: $description');
      ////debugPrint('ApiService: quantity: $quantity, isActive: $isActive, discountPrice: $discountPrice, branch: $branch, comments: $comments, mainImageIndex: $mainImageIndex');
      ////debugPrint('ApiService: attributes: $attributes');
      ////debugPrint('ApiService: variants: $variants');
      ////debugPrint('ApiService: images: ${images.map((file) => file.path).toList()}');

      request.fields['name'] = name;
      request.fields['category_id'] = parentId.toString();
      request.fields['description'] = description;
      request.fields['quantity'] = quantity.toString();
      request.fields['is_active'] = isActive ? '1' : '0';
      request.fields['label_id'] =
          labelId != null ? labelId.toString() : ''; // Add label fields
      request.fields['is_service'] = isService ? '1' : '0';

      if (unitId != null) {
        request.fields['unit_id'] = unitId.toString();
      }

      if (storageId != null) {
        request.fields['branch_id'] = storageId.toString();
        request.fields['storage_id'] = storageId.toString();
        ////debugPrint('ApiService: Added branch: $branch');
      }
      if (comments != null && comments.isNotEmpty) {
        request.fields['comments'] = comments;
        ////debugPrint('ApiService: Added comments: $comments');
      }
      if (discountPrice != null) {
        request.fields['price'] = discountPrice.toString();
        ////debugPrint('ApiService: Added discount_price: $discountPrice');
      }

      for (int i = 0; i < attributes.length; i++) {
        request.fields['attributes[$i][category_attribute_id]'] =
            attributes[i]['category_attribute_id'].toString();
        request.fields['attributes[$i][value]'] =
            attributes[i]['value'].toString();
        ////debugPrint('ApiService: Added attribute $i: ${request.fields['attributes[$i][category_attribute_id]']}, ${request.fields['attributes[$i][value]']}');
      }

      for (int i = 0; i < variants.length; i++) {
        if (variants[i].containsKey('id')) {
          request.fields['variants[$i][id]'] = variants[i]['id'].toString();
          ////debugPrint('ApiService: Added variant ID $i: ${variants[i]['id']}');
        }
        request.fields['variants[$i][is_active]'] =
            variants[i]['is_active'] ? '1' : '0';
        request.fields['variants[$i][price]'] =
            (variants[i]['price'] ?? 0.0).toString();
        ////debugPrint('ApiService: Added variant $i: is_active=${variants[i]['is_active']}, price=${variants[i]['price']}');

        List<dynamic> variantAttributes =
            variants[i]['variant_attributes'] ?? [];
        for (int j = 0; j < variantAttributes.length; j++) {
          if (variantAttributes[j].containsKey('id')) {
            request.fields['variants[$i][variant_attributes][$j][id]'] =
                variantAttributes[j]['id'].toString();
            ////debugPrint('ApiService: Added variant attribute ID $i-$j: ${variantAttributes[j]['id']}');
          }
          request.fields[
                  'variants[$i][variant_attributes][$j][category_attribute_id]'] =
              variantAttributes[j]['category_attribute_id'].toString();
          request.fields['variants[$i][variant_attributes][$j][value]'] =
              variantAttributes[j]['value'].toString();
          ////debugPrint('ApiService: Added variant attribute $i-$j: ${variantAttributes[j]}');
        }

        List<File> variantFiles = variants[i]['files'] ?? [];
        for (int j = 0; j < variantFiles.length; j++) {
          File file = variantFiles[j];
          if (await file.exists()) {
            final imageFile = await http.MultipartFile.fromPath(
                'variants[$i][files][$j]', file.path);
            request.files.add(imageFile);
            ////debugPrint('ApiService: Added variant file $i-$j: ${file.path}');
          } else {
            ////debugPrint('ApiService: Variant file not found, skipping: ${file.path}');
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
          ////debugPrint('ApiService: Added general image $i: ${file.path}, is_main: ${request.fields['files[$i][is_main]']}');
        } else {
          ////debugPrint('ApiService: General image not found, skipping: ${file.path}');
        }
      }

      final response = await _multipartPostRequest('', request);
      final responseBody = json.decode(response.body);

      ////debugPrint('ApiService: Response status: ${response.statusCode}');
      ////debugPrint('ApiService: Response body: $responseBody');

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
      ////debugPrint('ApiService: Error in updateGoods: ');
      ////debugPrint('ApiService: Stack trace: $stackTrace');
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
        //debugPrint('ApiService: deleteGoods - Generated path: $path');
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
      ////debugPrint('Ошибка удаления товара: ');
      return false;
    }
  }

  Future<List<Label>> getLabels() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/label');
    if (kDebugMode) {
      //debugPrint('ApiService: getLabels - Generated path: $path');
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
      debugPrint('ApiService: Запрос товаров по штрихкоду: $path');
    }

    final response = await _getRequest(path);
    if (kDebugMode) {
      debugPrint(
          'ApiService: Ответ сервера: statusCode=${response.statusCode}, body=${response.body}');
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('errors') && data['errors'] != null) {
        if (kDebugMode) {
          debugPrint('ApiService: Ошибка сервера: ${data['errors']}');
        }
        throw Exception('Ошибка сервера: ${data['errors']}');
      }
      if (data.containsKey('result')) {
        final result = data['result'];
        if (result == null || result == 'Товар не найден') {
          if (kDebugMode) {
            debugPrint('ApiService: Товары по штрихкоду не найдены');
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
            debugPrint(
                'ApiService: Ошибка формата данных: result не является списком или объектом: $data');
          }
          throw Exception('Ошибка: Неверный формат данных');
        }

        final goods = goodsData
            .map((item) => Goods.fromJson(item as Map<String, dynamic>))
            .toList();
        if (kDebugMode) {
          debugPrint(
              'ApiService: Успешно получено ${goods.length} товаров по штрихкоду');
        }
        return goods;
      } else {
        if (kDebugMode) {
          debugPrint(
              'ApiService: Ошибка формата данных: отсутствует поле result в $data');
        }
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
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
      //debugPrint('ApiService: getOrderStatuses - Generated path: $path');
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
      ////debugPrint(
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
    List<String>? regionsIds,
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
    if (regionsIds != null && regionsIds.isNotEmpty) {
      for (int i = 0; i < regionsIds.length; i++) {
        url += '&regions[$i]=${regionsIds[i]}';
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
      //debugPrint('ApiService: getOrders - Generated path: $path');
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
      //debugPrint('ApiService: getOrderDetails - Generated path: $path');
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
      ////debugPrint(
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
      //debugPrint('ApiService: getOrdersByLead - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (kDebugMode) {
        // //debugPrint('Request URL: $path');
        // //debugPrint('Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        return OrderResponse.fromJson(rawData);
      } else {
        throw Exception('Ошибка сервера при загрузке заказов!');
      }
    } catch (e) {
      if (kDebugMode) {
        // //debugPrint('Ошибка загрузки заказов по лиду: $e');
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
    int? integration,
    required double sum,
    List<Map<String, dynamic>>? customFields,
    List<Map<String, int>>? directoryValues,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order/store/from-online-shop');
      if (kDebugMode) {
        //debugPrint('ApiService: createOrder - Generated path: $path');
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
        'integration_id': integration,
        'sum': sum,
      };

      if (delivery) {
        body['delivery_address_id'] = deliveryAddressId;
      } else {
        body['delivery_address_id'] = null;
      }

      // Всегда отправляем branch_id, если он указан
      body['branch_id'] = branchId;

      if (customFields != null && customFields.isNotEmpty) {
        body['custom_fields'] = customFields;
      }

      if (directoryValues != null && directoryValues.isNotEmpty) {
        body['directory_values'] = directoryValues;
      }

      ////debugPrint('ApiService: Тело запроса для создания заказа: ${jsonEncode(body)}');

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

      ////debugPrint('ApiService: Код ответа сервера: ${response.statusCode}');
      ////debugPrint('ApiService: Тело ответа сервера: ${response.body}');

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
      ////debugPrint('ApiService: Ошибка создания заказа: ');
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
    int? integration,
    required double sum,
    List<Map<String, dynamic>>? customFields,
    List<Map<String, int>>? directoryValues,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order/$orderId');
      if (kDebugMode) {
        //debugPrint('ApiService: updateOrder - Generated path: $path');
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
        'integration_id': integration,
        'sum': sum,
      };

      if (delivery) {
        body['delivery_address'] = deliveryAddress;
        body['delivery_address_id'] = deliveryAddressId?.toString();
      } else {
        body['delivery_address'] = null;
        body['delivery_address_id'] = null;
      }

      // Всегда отправляем branch_id, если он указан
      body['branch_id'] = branchId;

      if (customFields != null && customFields.isNotEmpty) {
        body['custom_fields'] = customFields;
      }

      if (directoryValues != null && directoryValues.isNotEmpty) {
        body['directory_values'] = directoryValues;
      }

      ////debugPrint('ApiService: Тело запроса для обновления заказа: ${jsonEncode(body)}');

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

      ////debugPrint('ApiService: Код ответа сервера: ${response.statusCode}');
      ////debugPrint('ApiService: Тело ответа сервера: ${response.body}');

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
      ////debugPrint('ApiService: Ошибка обновления заказа: ');
      ////debugPrint('ApiService: StackTrace: $stackTrace');
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
        //debugPrint('ApiService: getDeliveryAddresses - Generated path: $path');
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

  Future<http.Response> createDeliveryAddress({
    required String address,
    required int leadId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/mini-app/delivery-address');
    if (kDebugMode) {
      debugPrint('ApiService: createDeliveryAddress - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        'address': address,
        'lead_id': leadId,
      },
    );

    if (kDebugMode) {
      debugPrint(
          'ApiService: createDeliveryAddress - Response status: ${response.statusCode}');
    }

    return response;
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
      //debugPrint('ApiService: createOrderStatus - Generated path: $path');
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
      //debugPrint('ApiService: updateOrderStatus - Generated path: $path');
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
      //debugPrint('ApiService: deleteOrderStatus - Generated path: $path');
    }

    final response = await _deleteRequest(path);
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> checkIfStatusHasOrders(int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/orders?status_id=$statusId');
    if (kDebugMode) {
      //debugPrint('ApiService: checkIfStatusHasOrders - Generated path: $path');
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
        //debugPrint('ApiService: deleteOrder - Generated path: $path');
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
      ////debugPrint('Ошибка удаления заказа: ');
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
        //debugPrint('ApiService: changeOrderStatus - Generated path: $path');
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
      ////debugPrint('Ошибка смены статуса заказа: ');
      return false;
    }
  }

  Future<List<Branch>> getBranches() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/storage');
    if (kDebugMode) {
      //debugPrint('ApiService: getBranches - Generated path: $path');
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
      //debugPrint('ApiService: getLeadOrders - Generated path: $path');
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
      if (kDebugMode) {
        debugPrint(
            '📅 Calendar types to send: $types (count: ${types.length})');
      }
      url += types.map((type) => '&type[]=${Uri.encodeComponent(type)}').join();
    }

    if (kDebugMode) {
      debugPrint('📅 Calendar URL after types: $url');
    }

    if (userIds != null && userIds.isNotEmpty) {
      url += userIds
          // TODO check if users[] or user_id[]
          .map((userId) => '&user_id[]=$userId')
          .join(); // Append user IDs
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('📅 Calendar API URL: $path');
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
          //debugPrint('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр to: ${filters['endDate']}');
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
          //debugPrint('ApiService: Добавлены lead_id: $leadIds');
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
          //debugPrint('ApiService: Добавлены operator_id: $operatorIds');
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
          //debugPrint('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id (только если не добавлена выше)
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getAllCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //debugPrint('ApiService: Response for getAllCalls: $data');
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
        //debugPrint('ApiService: Error response body: ${response.body}');
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
          //debugPrint('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр to: ${filters['endDate']}');
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
          //debugPrint('ApiService: Добавлены lead_id: $leadIds');
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
          //debugPrint('ApiService: Добавлены operator_id: $operatorIds');
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
          //debugPrint('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getIncomingCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //debugPrint('ApiService: Response for getIncomingCalls: $data');
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
        //debugPrint('ApiService: Error response body: ${response.body}');
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
          //debugPrint('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр to: ${filters['endDate']}');
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
          //debugPrint('ApiService: Добавлены lead_id: $leadIds');
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
          //debugPrint('ApiService: Добавлены operator_id: $operatorIds');
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
          //debugPrint('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getOutgoingCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //debugPrint('ApiService: Response for getOutgoingCalls: $data');
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
        //debugPrint('ApiService: Error response body: ${response.body}');
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
          //debugPrint('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр to: ${filters['endDate']}');
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
          //debugPrint('ApiService: Добавлены lead_id: $leadIds');
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
          //debugPrint('ApiService: Добавлены operator_id: $operatorIds');
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
          //debugPrint('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getMissedCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //debugPrint('ApiService: Response for getMissedCalls: $data');
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
        //debugPrint('ApiService: Error response body: ${response.body}');
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
      //debugPrint('ApiService: getCallById - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      //debugPrint("API response for getCallById: $data");
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
      //debugPrint('ApiService: getCallStatistics - Generated path: $path');
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
      //debugPrint('ApiService: getCallAnalytics - Generated path: $path');
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
      //debugPrint('ApiService: getMonthlyCallStats - Generated path: $path');
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
      //debugPrint('ApiService: getCallSummaryStats - Generated path: $path');
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
      //debugPrint('ApiService: setCallRating - Generated path: $path');
    }
    final body = {
      'rating': rating,
      'organization_id': organizationId,
    };

    if (kDebugMode) {
      //debugPrint("API Request: setCallRating (PUT) with path: $path, body: $body");
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
      //debugPrint('ApiService: addCallReport - Generated path: $path');
    }
    final body = {
      'report': report,
      'organization_id': organizationId,
    };

    if (kDebugMode) {
      //debugPrint("API Request: addCallReport (PUT) with path: $path, body: $body");
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
      //debugPrint('ApiService: getOperators - Generated path: $path');
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
      debugPrint('ApiService: getIncomingDocuments - Generated path: $path');
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
      debugPrint('ApiService: getIncomingDocumentById - Generated path: $path');
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
      debugPrint('ApiService: approveIncomingDocument - Generated path: $path');
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
          debugPrint(
              'ApiService: approveIncomingDocument - Document $documentId approved successfully');
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при проведении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unApproveIncomingDocument(int documentId) async {
    const String url = '/income-documents/unApprove';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint(
          'ApiService: unApproveIncomingDocument - Generated path: $path');
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
          debugPrint(
              'ApiService: unApproveIncomingDocument - Document $documentId unapproved successfully');
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при отмене проведения документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreIncomingDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final pathWithParams =
          await _appendQueryParams('/income-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      if (kDebugMode) {
        debugPrint('ApiService: restoreIncomingDocument - Request body: $body');
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
          debugPrint(
              'ApiService: restoreIncomingDocument - Document $documentId restored successfully');
        }
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при восстановлении документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocumentHistoryResponse> getIncomingDocumentHistory(
      int documentId) async {
    String url = '/income-documents/history/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint(
          'ApiService: getIncomingDocumentHistory - Generated path: $path');
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
        debugPrint('ApiService: deleteIncomingDocument - Request body: $body');
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
        throw ApiException(
            message ?? 'Ошибка при удалении документа', response.statusCode);
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
          message ??
              'Ошибка при массовом снятии проведения документов прихода!',
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
  Future<expense.ExpenseResponse> getClientSales({
    int page = 1,
    int perPage = 20,
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? approved,
    int? deleted,
    int? leadId,
    int? cashRegisterId,
    int? supplierId,
    int? authorId,
    int? storageId,
  }) async {
    String url =
        '/expense-documents'; // Предполагаемый endpoint; подкорректируй если нужно
    url += '?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (dateFrom != null) {
      url += '&date_from=${dateFrom.toIso8601String()}';
    }
    if (dateTo != null) {
      url += '&date_to=${dateTo.toIso8601String()}';
    }
    if (approved != null) {
      url += '&approved=$approved';
    }
    if (deleted != null) {
      url += '&deleted=$deleted';
    }
    if (leadId != null) {
      url += '&lead_id=$leadId';
    }
    if (cashRegisterId != null) {
      url += '&cash_register_id=$cashRegisterId';
    }
    if (supplierId != null) {
      url += '&supplier_id=$supplierId';
    }
    if (authorId != null) {
      url += '&author_id=$authorId';
    }
    if (storageId != null) {
      url += '&storage_id=$storageId';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getClientSales - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result']; // Как в JSON
        return expense.ExpenseResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<expDoc.ExpenseDocumentDetail> getClienSalesById(int documentId) async {
    String url = '/expense-documents/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getIncomingDocumentById - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return expDoc.ExpenseDocumentDetail.fromJson(rawData);
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
        throw ApiException(
            message ?? 'Неизвестная ошибка при создании документа',
            response.statusCode);
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
        debugPrint(
            'ApiService: deleteClientSaleDocument - Request body: $body');
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
        throw ApiException(
            message ?? 'Ошибка при удалении документа', response.statusCode);
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
        throw ApiException(
            message ?? 'Ошибка обновления документа', response.statusCode);
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
            message ?? 'Ошибка при проведении документа', response.statusCode);
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
        throw ApiException(message ?? 'Ошибка при отмене проведения документа',
            response.statusCode);
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

      final pathWithParams =
          await _appendQueryParams('/expense-documents/restore');
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
        throw ApiException(message ?? 'Ошибка при восстановлении документа',
            response.statusCode);
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
          message ??
              'Ошибка при массовом снятии проведения документов реализации!',
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
          message ??
              'Ошибка при массовом восстановлении документов реализации!',
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
      //debugPrint('ApiService: getStorage - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные складов: $data');

      // Извлекаем массив из поля "result"
      final List<dynamic> resultList = data['result'] ?? [];

      return resultList.map((storage) => WareHouse.fromJson(storage)).toList();
    } else {
      throw Exception('Ошибка загрузки складов');
    }
  }

  //get storage
  Future<List<WareHouse>> getWareHouses({
    String? search,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    var path = await _appendQueryParams('/storage');
    if (kDebugMode) {
      //debugPrint('ApiService: getStorage - Generated path: $path');
    }

    path += search != null && search.isNotEmpty ? '&search=$search' : '';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные складов: $data');

      // Извлекаем массив из поля "result"
      final List<dynamic> resultList = data['result'] ?? [];

      return resultList.map((storage) => WareHouse.fromJson(storage)).toList();
    } else {
      throw ApiException('Ошибка загрузки складов', response.statusCode);
    }
  }

  //create storage
  Future<bool> createStorage(
    WareHouse unit,
    List<int> userIds,
  ) async {
    final path = await _appendQueryParams('/storage');
    if (kDebugMode) {
      debugPrint('ApiService: createStorage - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': unit.name,
      "users": userIds,
      "show_on_site": unit.showOnSite,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _postRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка создания склада', response.statusCode);
    }
  }

  //updateStorage
  Future<void> updateStorage({
    required WareHouse storage,
    required int id,
    required List<int> ids,
  }) async {
    final path = await _appendQueryParams('/storage/$id');

    if (kDebugMode) {
      debugPrint('ApiService: updateStorage - Generated path: $path');
    }

    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': storage.name,
      'users': ids,
      'show_on_site': storage.showOnSite,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _patchRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        debugPrint("Склад обновлен успешно");
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        debugPrint('Ошибка обновления склада: $message');
        throw ApiException(message ?? 'Ошибка обновления', response.statusCode);
      }
    } else {
      final message = _extractErrorMessageFromResponse(response);
      debugPrint('Ошибка обновления склада2: $message');
      throw ApiException(message ?? 'Ошибка обновления', response.statusCode);
    }
  }

  //delete storage
  Future<void> deleteStorage(int storageId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/storage/$storageId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteSupplier - Generated path: $path');
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

  Future<List<MeasureUnitModel>> getAllMeasureUnits() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/unit');

    if (kDebugMode) {
      debugPrint("ApiService: getAllMeasureUnits - Generated path: $path");
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
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка загрузки единиц измерения', response.statusCode);
    }
  }

  //get measure units
  Future<List<MeasureUnitModel>> getMeasureUnits({String? search}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/unit');

    // Добавляем параметр поиска, если он передан
    if (search != null && search.isNotEmpty) {
      path =
          path.contains('?') ? '$path&search=$search' : '$path?search=$search';
    }

    if (kDebugMode) {
      //debugPrint('ApiService: getMeasureUnits - Generated path: $path');
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
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка загрузки единиц измерения', response.statusCode);
    }
  }

  //create measure units
  Future<void> createMeasureUnit(
    MeasureUnitModel unit,
  ) async {
    final path = await _appendQueryParams('/unit');
    if (kDebugMode) {
      //debugPrint('ApiService: createSupplier - Generated path: $path');
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
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка создания поставщика', response.statusCode);
    }
  }

  //delete measure units
  Future<void> deleteMeasureUnit(int supplierId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/unit/$supplierId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteSupplier - Generated path: $path');
    }

    final response = await _deleteRequestWithBody(path,
        {"organization_id": organizationId, "sales_funnel_id": salesFunnelId});

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка удаления поставщика', response.statusCode);
    }
  }

  //update measure units
  Future<void> updateUnit(
      {required MeasureUnitModel supplier, required int id}) async {
    final path = await _appendQueryParams('/unit/$id');
    if (kDebugMode) {
      //debugPrint('ApiService: updateSupplier - Generated path: $path');
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
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка обновления', response.statusCode);
      }
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(message ?? 'Ошибка обновления', response.statusCode);
    }
  }

//--------------------------PRICE TYPE---------------------------------------------

  Future<List<PriceTypeModel>> getPriceTypes({String? search}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/priceType');

    // Добавляем параметр поиска, если он передан
    if (search != null && search.isNotEmpty) {
      path =
          path.contains('?') ? '$path&search=$search' : '$path?search=$search';
    }

    if (kDebugMode) {
      //debugPrint('ApiService: getPriceTypes - Generated path: $path');
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
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка загрузки типов цен', response.statusCode);
    }
  }

  Future<void> createPriceType(
    PriceTypeModel unit,
  ) async {
    final path = await _appendQueryParams('/priceType');
    if (kDebugMode) {
      debugPrint('ApiService: createPriceType - Generated path: $path');
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
      if (kDebugMode) {
        debugPrint('createPriceType success: ${response.body}');
      }
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка создания типа цены', response.statusCode);
    }
  }

  Future<void> updatePriceType(
      {required PriceTypeModel priceType, required int id}) async {
    final path = await _appendQueryParams('/priceType/$id');
    if (kDebugMode) {
      debugPrint('ApiService: updatePriceType - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': priceType.name,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _patchRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (kDebugMode) {
        debugPrint('updatePriceType success: ${response.body}');
      }
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка обновления типа цены', response.statusCode);
    }
  }

  Future<void> deletePriceType(int priceTypeId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/priceType/$priceTypeId');
    if (kDebugMode) {
      debugPrint('ApiService: deletePriceType - Generated path: $path');
    }

    final response = await _deleteRequestWithBody(path,
        {"organization_id": organizationId, "sales_funnel_id": salesFunnelId});

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (kDebugMode) {
        debugPrint('deletePriceType success: ${response.body}');
      }
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка удаления типа цены', response.statusCode);
    }
  }

//----------------------------------------------SUPPLIER----------------------------------
  //createSupplier
  Future<void> createSupplier(
      Supplier supplier, String organizationId, String salesFunnelId) async {
    final path = await _appendQueryParams('/suppliers');
    if (kDebugMode) {
      //debugPrint('ApiService: createSupplier - Generated path: $path');
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
        return; //Supplier.fromJson(json.decode(response.body)['result']);
      } else {
        throw Exception('Ошибка создания поставщика: ${response.body}');
      }
    } else {
      throw Exception('Ошибка создания поставщика: ${response.body}');
    }
  }

  //updateSupplier
  Future<void> updateSupplier(
      {required Supplier supplier, required int id}) async {
    final path = await _appendQueryParams('/suppliers/$id');
    if (kDebugMode) {
      //debugPrint('ApiService: updateSupplier - Generated path: $path');
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
    debugPrint('Response body: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return;
      } else {
        debugPrint("Ошибка: Пустой ответ при обновлении поставщика");
        throw Exception('Ошибка обновления поставщика: ${response.body}');
      }
    } else {
      debugPrint("Ошибка: ${response.body}");
      throw Exception('Ошибка обновления поставщика: ${response.body}');
    }
  }

  //deleteSupplier
  Future<void> deleteSupplier(int supplierId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/suppliers/$supplierId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteSupplier - Generated path: $path');
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
      //debugPrint('ApiService: getSuppliers - Generated path: $path');
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
  Future<List<Supplier>> getSupplier({String? search}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/suppliers');

    // Добавляем параметр поиска, если он передан
    if (search != null && search.isNotEmpty) {
      path =
          path.contains('?') ? '$path&search=$search' : '$path?search=$search';
    }

    if (kDebugMode) {
      //debugPrint('ApiService: getSupplier - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные поставщиков: $data');

      // Извлекаем массив из поля "result"
      final List<dynamic> resultList = data['result']["data"] ?? [];

      return resultList.map((supplier) => Supplier.fromJson(supplier)).toList();
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
      debugPrint('🔵 ApiService: getCashRegister - path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (kDebugMode) {
        debugPrint(
            '🔵 ApiService: getCashRegister - statusCode: ${response.statusCode}');
        debugPrint(
            '🔵 ApiService: getCashRegister - body length: ${response.body.length}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          debugPrint('🔵 ApiService: getCashRegister - JSON decoded');
          debugPrint(
              '🔵 ApiService: getCashRegister - keys: ${data is Map ? (data as Map).keys.toList() : "not a map"}');
          if (data is Map && data['result'] != null) {
            final result = data['result'];
            debugPrint(
                '🔵 ApiService: getCashRegister - result type: ${result.runtimeType}');
            if (result is Map) {
              debugPrint(
                  '🔵 ApiService: getCashRegister - result keys: ${result.keys.toList()}');
              if (result['data'] != null) {
                debugPrint(
                    '🔵 ApiService: getCashRegister - data type: ${result['data'].runtimeType}');
                if (result['data'] is List) {
                  debugPrint(
                      '🔵 ApiService: getCashRegister - data length: ${(result['data'] as List).length}');
                  if ((result['data'] as List).isNotEmpty) {
                    final first = (result['data'] as List)[0];
                    if (first is Map) {
                      debugPrint(
                          '🔵 ApiService: getCashRegister - first item keys: ${first.keys.toList()}');
                      if (first['users'] != null) {
                        debugPrint(
                            '🔵 ApiService: getCashRegister - first item users type: ${first['users'].runtimeType}');
                        if (first['users'] is List &&
                            (first['users'] as List).isNotEmpty) {
                          final firstUser = (first['users'] as List)[0];
                          if (firstUser is Map) {
                            debugPrint(
                                '🔵 ApiService: getCashRegister - first user keys: ${firstUser.keys.toList()}');
                            debugPrint(
                                '🔵 ApiService: getCashRegister - first user job_title: ${firstUser['job_title']} (type: ${firstUser['job_title'].runtimeType})');
                          }
                        }
                      }
                    }
                  }
                }
              }
              if (result['pagination'] != null) {
                debugPrint(
                    '🔵 ApiService: getCashRegister - pagination keys: ${(result['pagination'] as Map).keys.toList()}');
              }
            }
          }
        }

        if (data['result'] != null) {
          if (kDebugMode) {
            debugPrint(
                '🔵 ApiService: getCashRegister - calling CashRegisterResponseModel.fromJson');
          }
          final parsed = CashRegisterResponseModel.fromJson(data['result']);
          if (kDebugMode) {
            debugPrint(
                '🔵 ApiService: getCashRegister - parsed successfully, count: ${parsed.data.length}');
          }
          return parsed;
        } else {
          if (kDebugMode) {
            debugPrint(
                '🔴 ApiService: getCashRegister - data["result"] is null');
          }
          throw Exception('Нет данных по кассе');
        }
      } else {
        final data = json.decode(response.body);
        if (kDebugMode) {
          debugPrint(
              '🔴 ApiService: getCashRegister - error status: ${response.statusCode}');
        }
        if (data['errors'] != null) {
          throw Exception(data['errors'] ?? 'Ошибка загрузки кассы');
        } else {
          throw Exception('Ошибка загрузки кассы: ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('🔴 ApiService: getCashRegister - EXCEPTION: $e');
        debugPrint('🔴 ApiService: getCashRegister - STACK: $stackTrace');
      }
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

  Future<CashRegisterModel> patchCashRegister(
      int id, AddCashDeskModel value) async {
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
      debugPrint('ApiService: getExpenses - Generated path: $path');
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
      debugPrint('ApiService: getIncomes - Generated path: $path');
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
    String url = '/supplier-return-documents'; // Замена endpoint'а
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
        debugPrint(
            'ApiService: getSupplierReturnDocumentById - Generated path: $path');
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
      debugPrint(
          'ApiService: approveSupplierReturnDocument - Generated path: $path');
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
      debugPrint(
          'ApiService: unApproveSupplierReturnDocument - Generated path: $path');
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
        throw ApiException(
            message ?? "Ошибка создании документа", response.statusCode);
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

      final path =
          await _appendQueryParams('/supplier-return-documents/$documentId');
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
            message ?? "Ошибка обновления документа", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteSupplierReturnDocument(
      int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams =
          await _appendQueryParams('/supplier-return-documents');
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
        debugPrint(
            'ApiService: deleteSupplierReturnDocument - Request body: $body');
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
        throw ApiException(
            message ?? "Ошибка удалении документа", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreSupplierReturnDocument(
      int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final pathWithParams =
          await _appendQueryParams('/supplier-return-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      if (kDebugMode) {
        debugPrint(
            'ApiService: restoreSupplierReturnDocument - Request body: $body');
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
          debugPrint(
              'ApiService: restoreSupplierReturnDocument - Document $documentId restored successfully');
        }
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при восстановлении документа',
            response.statusCode);
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

  Future<void> createMoneyIncomeDocument({
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

      if (filters.containsKey('cash_register_id') &&
          filters['cash_register_id'] != null) {
        path += '&cash_register_id=${filters['cash_register_id']}';
      }

      if (filters.containsKey('supplier_id') &&
          filters['supplier_id'] != null) {
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
      debugPrint('ApiService: getMoneyIncomeDocuments - Generated path: $path');
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

  Future<Map<String, dynamic>> restoreMoneyIncomeDocument(
      int documentId) async {
    final token = await getToken();
    if (token == null) throw Exception('Токен не найден');

    final pathWithParams =
        await _appendQueryParams('/checking-account/restore');
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
      final jsonResponse = jsonDecode(response.body);
      throw Exception(
          jsonResponse['message'] ?? 'Ошибка при восстановлении документа');
    }
  }

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
    } catch (e) {
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

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 201) {
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
          message ??
              'Ошибка при массовом снятии проведения документов прихода!',
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

    final response = await _getRequest(path);
    ;

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

  Future<void> createMoneyOutcomeDocument({
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

      if (filters.containsKey('cash_register_id') &&
          filters['cash_register_id'] != null) {
        path += '&cash_register_id=${filters['cash_register_id']}';
      }

      if (filters.containsKey('supplier_id') &&
          filters['supplier_id'] != null) {
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
      debugPrint(
          'ApiService: getMoneyOutcomeDocuments - Generated path: $path');
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

  Future<bool> restoreMoneyOutcomeDocument(int documentId) async {
    final path = await _appendQueryParams('/checking-account/mass-restore');

    try {
      final response = await _postRequest(path, {
        'ids': [documentId],
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при восстановлении документа расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleApproveOneMoneyOutcomeDocument(
      int id, bool approve) async {
    final path = approve
        ? await _appendQueryParams('/checking-account/mass-approve')
        : await _appendQueryParams('/checking-account/mass-unapprove');

    try {
      final response = await _patchRequest(path, {
        'ids': [id],
      });

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 201) {
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
          message ??
              'Ошибка при массовом снятии проведения документов расхода!',
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
    DateTime? dateFrom,
    DateTime? dateTo,
    int? approved,
    int? deleted,
    int? leadId,
    int? cashRegisterId,
    int? supplierId,
    int? authorId,
    int? storageId,
  }) async {
    String url = '/client-return-documents'; // Заменили endpoint
    url += '?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (dateFrom != null) {
      url += '&date_from=${dateFrom.toIso8601String()}';
    }
    if (dateTo != null) {
      url += '&date_to=${dateTo.toIso8601String()}';
    }
    if (approved != null) {
      url += '&approved=$approved';
    }
    if (deleted != null) {
      url += '&deleted=$deleted';
    }
    if (leadId != null) {
      url += '&lead_id=$leadId';
    }
    if (cashRegisterId != null) {
      url += '&cash_register_id=$cashRegisterId';
    }
    if (supplierId != null) {
      url += '&supplier_id=$supplierId';
    }
    if (authorId != null) {
      url += '&author_id=$authorId';
    }
    if (storageId != null) {
      url += '&storage_id=$storageId';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getClientReturns - Generated path: $path');
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
        debugPrint('ApiService: getClientReturnById - Generated path: $path');
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
  Future<Map<String, dynamic>> deleteClientReturnDocument(
      int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams =
          await _appendQueryParams('/client-return-documents');
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
        debugPrint(
            'ApiService: deleteClientReturnDocument - Request body: $body');
        debugPrint(
            'ApiService: deleteClientReturnDocument - Request params: $pathWithParams');
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
        throw ApiException(
            message ?? 'Ошибка при удалении документа возврата от клиента',
            response.statusCode);
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

      final path =
          await _appendQueryParams('/client-return-documents/$documentId');
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
          message ??
              'Ошибка при массовом проведении документов возврата от клиента!',
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
          message ??
              'Ошибка при массовом снятии проведения документов возврата от клиента!',
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
          message ??
              'Ошибка при массовом удалении документов возврата от клиента!',
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
          message ??
              'Ошибка при массовом восстановлении документов возврата от клиента!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Восстановление документа возврата
  Future<Map<String, dynamic>> restoreClientReturnDocument(
      int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final pathWithParams =
          await _appendQueryParams('/client-return-documents/restore');
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
      debugPrint('ApiService: getWriteOffDocuments - Generated path: $path');
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
      debugPrint('ApiService: getWriteOffDocumentById - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при получении данных документа списания!',
            response.statusCode);
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
    required int articleId,
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
        'article_id': articleId,
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
        debugPrint('ApiService: deleteWriteOffDocument - Request body: $body');
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
        throw ApiException(message ?? 'Ошибка при удалении документа списания',
            response.statusCode);
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
    required int articleId,
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
        'article_id': articleId,
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
            message ?? 'Ошибка при обновлении документа списания!',
            response.statusCode);
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
            message ?? 'Ошибка при проведении документа', response.statusCode);
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
        throw ApiException(message ?? 'Ошибка при отмене проведения документа',
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

      final pathWithParams =
          await _appendQueryParams('/write-off-documents/restore');
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
        throw ApiException(message ?? 'Ошибка при восстановлении документа',
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
          message ??
              'Ошибка при массовом снятии проведения документов списания!',
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
      debugPrint('ApiService: getMovementDocuments - Generated path: $path');
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
      debugPrint('ApiService: getMovementDocumentById - Generated path: $path');
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
        debugPrint('ApiService: deleteMovementDocument - Request body: $body');
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
        throw ApiException(
            message ?? 'Ошибка при удалении документа', response.statusCode);
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
        throw ApiException(
            message ?? 'Ошибка обновления документа', response.statusCode);
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
        throw ApiException(
            message ?? 'Ошибка при проведении документа', response.statusCode);
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
        throw ApiException(message ?? 'Ошибка при отмене проведения документа',
            response.statusCode);
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

      final pathWithParams =
          await _appendQueryParams('/movement-documents/restore');
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
        throw ApiException(message ?? 'Ошибка при восстановлении документа',
            response.statusCode);
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
          message ??
              'Ошибка при массовом снятии проведения документов перемещения!',
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
          message ??
              'Ошибка при массовом восстановлении документов перемещения!',
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
    Map<String, dynamic>? filters,
    String? search,
  }) async {
    String path = '/dashboard/goods-report?';

    final categoryId = filters?['category_id'] as int?;
    final daysWithoutMovement = filters?['days_without_movement'] as int?;
    final goodId = filters?['good_id'] as int?;
    final sumFrom = filters?['sum_from'] as String?;
    final sumTo = filters?['sum_to'] as String?;

    if (categoryId != null) path += '&category_id=$categoryId';
    if (daysWithoutMovement != null)
      path += '&days_without_movement=$daysWithoutMovement';
    if (goodId != null) path += '&good_id=$goodId';
    if (sumFrom != null && sumFrom.isNotEmpty) path += '&sum_from=$sumFrom';
    if (sumTo != null && sumTo.isNotEmpty) path += '&sum_to=$sumTo';
    if (search != null && search.isNotEmpty) path += '&search=$search';
    path += '&page=$page&per_page=$perPage';

    path = await _appendQueryParams(path);
    if (kDebugMode) {
      debugPrint(
          'ApiService: getSalesDashboardGoodsReport - Generated path: $path');
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
      debugPrint('ApiService: getBatchRemainders - Generated path: $path');
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
    int? page,
    int? perPage,
    Map<String, dynamic>? filters,
    String? search,
  }) async {
    try {
      // Формируем параметры запроса
      Map<String, String> queryParams = {};

      if (page != null) queryParams['page'] = page.toString();
      if (perPage != null) queryParams['per_page'] = perPage.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (filters != null) {
        if (filters.containsKey('date_from') &&
            filters['date_from'] is DateTime &&
            filters['date_from'] != null) {
          debugPrint(
              "ApiService: filters['date_from']: ${filters['date_from']}");
          final dateFrom = filters['date_from'] as DateTime;
          queryParams['date_from'] = dateFrom.toIso8601String();
        }
        if (filters.containsKey('date_to') &&
            filters['date_to'] is DateTime &&
            filters['date_to'] != null) {
          debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
          final dateTo = filters['date_to'] as DateTime;
          queryParams['date_to'] = dateTo.toIso8601String();
        }
        if (filters.containsKey('lead_id') && filters['lead_id'] != null) {
          debugPrint("ApiService: filters['lead_id']: ${filters['lead_id']}");
          queryParams['lead_id'] = filters['lead_id'].toString();
        }
        if (filters.containsKey('supplier_id') &&
            filters['supplier_id'] != null) {
          debugPrint(
              "ApiService: filters['supplier_id']: ${filters['supplier_id']}");
          queryParams['supplier_id'] = filters['supplier_id'].toString();
        }
        if (filters.containsKey('sum_from') && filters['sum_from'] != null) {
          debugPrint("ApiService: filters['sum_from']: ${filters['sum_from']}");
          queryParams['sum_from'] = filters['sum_from'].toString();
        }
        if (filters.containsKey('sum_to') && filters['sum_to'] != null) {
          debugPrint("ApiService: filters['sum_to']: ${filters['sum_to']}");
          queryParams['sum_to'] = filters['sum_to'].toString();
        }
      }

      var path = await _appendQueryParams('/fin/dashboard/debtors-list');

      // Fix: Properly encode query parameters
      if (queryParams.isNotEmpty) {
        // Check if path already has query params (contains ?)
        final separator = path.contains('?') ? '&' : '?';
        final encodedParams = queryParams.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        path += '$separator$encodedParams';
      }
      if (kDebugMode) {
        debugPrint(
            'ApiService: getDebtorsList - Generated path: $path, filter: $filters');
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
    int? page,
    int? perPage,
    Map<String, dynamic>? filters,
    String? search,
  }) async {
    try {
      // Формируем параметры запроса
      Map<String, String> queryParams = {};

      if (page != null) queryParams['page'] = page.toString();
      if (perPage != null) queryParams['per_page'] = perPage.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (filters != null) {
        if (filters.containsKey('date_from') &&
            filters['date_from'] is DateTime &&
            filters['date_from'] != null) {
          debugPrint(
              "ApiService: filters['date_from']: ${filters['date_from']}");
          final dateFrom = filters['date_from'] as DateTime;
          queryParams['date_from'] = dateFrom.toIso8601String();
        }
        if (filters.containsKey('date_to') &&
            filters['date_to'] is DateTime &&
            filters['date_to'] != null) {
          debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
          final dateTo = filters['date_to'] as DateTime;
          queryParams['date_to'] = dateTo.toIso8601String();
        }
        if (filters.containsKey('lead_id') && filters['lead_id'] != null) {
          debugPrint("ApiService: filters['lead_id']: ${filters['lead_id']}");
          queryParams['lead_id'] = filters['lead_id'].toString();
        }
        if (filters.containsKey('supplier_id') &&
            filters['supplier_id'] != null) {
          debugPrint(
              "ApiService: filters['supplier_id']: ${filters['supplier_id']}");
          queryParams['supplier_id'] = filters['supplier_id'].toString();
        }
        if (filters.containsKey('sum_from') && filters['sum_from'] != null) {
          debugPrint("ApiService: filters['sum_from']: ${filters['sum_from']}");
          queryParams['sum_from'] = filters['sum_from'].toString();
        }
        if (filters.containsKey('sum_to') && filters['sum_to'] != null) {
          debugPrint("ApiService: filters['sum_to']: ${filters['sum_to']}");
          queryParams['sum_to'] = filters['sum_to'].toString();
        }
      }

      var path = await _appendQueryParams('/fin/dashboard/creditors-list');

      // Fix: Properly encode query parameters
      if (queryParams.isNotEmpty) {
        // Check if path already has query params (contains ?)
        final separator = path.contains('?') ? '&' : '?';
        final encodedParams = queryParams.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        path += '$separator$encodedParams';
      }
      if (kDebugMode) {
        debugPrint(
            'ApiService: getCreditorsList - Generated path: $path, filter: $filters');
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
        path +=
            '?${Uri.encodeQueryComponent(queryParams.entries.map((e) => '${e.key}=${e.value}').join('&'))}';
      }

      if (kDebugMode) {
        debugPrint('ApiService: getIlliquidGoods - Generated path: $path');
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
    String? search,
    Map<String, dynamic>? filters,
    int? page,
    int? perPage,
  }) async {
    // try{
    // Формируем параметры запроса

    debugPrint("ApiService: getSalesDashboardCashBalance filters: $filters");

    Map<String, String> queryParams = {};
    if (page != null) queryParams['page'] = page.toString();
    if (perPage != null) queryParams['per_page'] = perPage.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        debugPrint("ApiService: filters['date_from']: ${filters['date_from']}");
        final dateFrom = filters['date_from'] as DateTime;
        queryParams['date_from'] = dateFrom.toIso8601String();
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
        final dateTo = filters['date_to'] as DateTime;
        queryParams['date_to'] = dateTo.toIso8601String();
      }

      if (filters.containsKey('sum_from') && filters['sum_from'] != null) {
        debugPrint("ApiService: filters['sum_from']: ${filters['sum_from']}");
        final sumFrom = filters['sum_from'] as double;
        queryParams['sum_from'] = sumFrom.toString();
      }

      if (filters.containsKey('sum_to') && filters['sum_to'] != null) {
        debugPrint("ApiService: filters['sum_to']: ${filters['sum_to']}");
        final sumTo = filters['sum_to'] as double;
        queryParams['sum_to'] = sumTo.toString();
      }
    }

    var path = await _appendQueryParams('/fin/dashboard/cash-balance');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    if (kDebugMode) {
      debugPrint('ApiService: getCashBalance - Generated path: $path');
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
    final periods = [
      ExpensePeriodEnum.today,
      ExpensePeriodEnum.week,
      ExpensePeriodEnum.month,
      ExpensePeriodEnum.quarter,
      ExpensePeriodEnum.year
    ];

    // List to store results
    final List<AllExpensesData> allExpensesData = [];

    // Iterate through each period
    for (final period in periods) {
      // Form the query path for the current period
      final path = await _appendQueryParams(
          '/fin/dashboard/expense-structure?period=${period.name}');
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

  /// Загрузка данных expense structure для конкретного периода
  Future<AllExpensesData> getExpenseStructureForPeriod(
    ExpensePeriodEnum period,
  ) async {
    final path = await _appendQueryParams(
        '/fin/dashboard/expense-structure?period=${period.name}');

    debugPrint(
        "ApiService: getExpenseStructureForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final expenseDashboard = ExpenseDashboard.fromJson(data);

        return AllExpensesData(
          period: period,
          data: expenseDashboard,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching expense structure for period $period: $e");
      rethrow;
    }
  }

  Future<List<AllSalesDynamicsData>> getSalesDynamics() async {
    // Define all periods to fetch
    final periods = [
      SalesDynamicsTimePeriod.year,
      SalesDynamicsTimePeriod.previousYear,
    ];

    // List to store results
    final List<AllSalesDynamicsData> allSalesDynamicsData = [];

    // Iterate through each period
    for (final period in periods) {
      try {
        final periodData = await getSalesDynamicsForPeriod(period);
        allSalesDynamicsData.add(periodData);
      } catch (e) {
        debugPrint("Error fetching sales dynamics for period $period: $e");
        // Продолжаем загрузку других периодов даже при ошибке
      }
    }

    return allSalesDynamicsData;
  }

  /// Загрузка данных sales dynamics для конкретного периода
  Future<AllSalesDynamicsData> getSalesDynamicsForPeriod(
    SalesDynamicsTimePeriod period,
  ) async {
    // Формируем параметры в зависимости от периода
    String periodParam;
    switch (period) {
      case SalesDynamicsTimePeriod.year:
        periodParam = 'year';
        break;
      case SalesDynamicsTimePeriod.previousYear:
        periodParam = 'last_year';
        break;
    }

    var path = await _appendQueryParams(
        '/dashboard/sales-dynamics?period=$periodParam');

    debugPrint(
        "ApiService: getSalesDynamicsForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final salesResponse = SalesResponse.fromJson(data);

        return AllSalesDynamicsData(
          period: period,
          data: salesResponse,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching sales dynamics for period $period: $e");
      rethrow;
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
      final path = await _appendQueryParams(
          '/dashboard/net-profit?period=${period.name}');
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

  /// Загрузка данных net profit для конкретного периода
  Future<AllNetProfitData> getNetProfitDataForPeriod(
    NetProfitPeriod period,
  ) async {
    final path =
        await _appendQueryParams('/dashboard/net-profit?period=${period.name}');

    debugPrint(
        "ApiService: getNetProfitDataForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final netProfitDashboard = NetProfitDashboard.fromJson(data);

        return AllNetProfitData(
          period: period,
          data: netProfitDashboard,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching net profit for period $period: $e");
      rethrow;
    }
  }

  Future<List<AllOrdersData>> getOrderDashboard() async {
    // Define all periods to fetch
    final periods = [
      OrderTimePeriod.week,
      OrderTimePeriod.month,
      OrderTimePeriod.year
    ];

    // List to store results
    final List<AllOrdersData> allOrdersData = [];

    // Iterate through each period
    for (final period in periods) {
      // Form the query path for the current period
      final path =
          await _appendQueryParams('/order/dashboard?period=${period.name}');
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

  /// Загрузка данных order dashboard для конкретного периода
  Future<AllOrdersData> getOrderDashboardForPeriod(
    OrderTimePeriod period,
  ) async {
    final path =
        await _appendQueryParams('/order/dashboard?period=${period.name}');

    debugPrint(
        "ApiService: getOrderDashboardForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orderDashboardResponse = OrderDashboardResponse.fromJson(data);

        return AllOrdersData(
          period: period,
          data: orderDashboardResponse.result,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching order dashboard for period $period: $e");
      rethrow;
    }
  }

// API request function
  Future<List<AllProfitabilityData>> getProfitability() async {
    // Define all periods to fetch
    final periods = [
      ProfitabilityTimePeriod.last_year,
      ProfitabilityTimePeriod.year
    ];

    // List to store results
    final List<AllProfitabilityData> allProfitabilityData = [];

    // Iterate through each period
    for (final period in periods) {
      // Form the query path for the current period
      final path = await _appendQueryParams(
          '/dashboard/profitability?period=${period.name}');
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

  /// Загрузка данных profitability для конкретного периода
  Future<AllProfitabilityData> getProfitabilityForPeriod(
    ProfitabilityTimePeriod period,
  ) async {
    final path = await _appendQueryParams(
        '/dashboard/profitability?period=${period.name}');

    debugPrint(
        "ApiService: getProfitabilityForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profitabilityResponse = ProfitabilityDashboard.fromJson(data);

        return AllProfitabilityData(
          period: period,
          data: profitabilityResponse,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching profitability for period $period: $e");
      rethrow;
    }
  }

  Future<List<AllTopSellingData>> getTopSellingGoodsDashboard(
      {int perPage = 7}) async {
    // Define all periods to fetch
    final periods = [
      TopSellingTimePeriod.day,
      TopSellingTimePeriod.week,
      TopSellingTimePeriod.month,
      TopSellingTimePeriod.year,
    ];

    // List to store results
    final List<AllTopSellingData> allTopSellingData = [];

    // Iterate through each period
    for (final period in periods) {
      final query = ['per_page=$perPage', 'period=${period.name}'].join('&');

      final path =
          await _appendQueryParams('/dashboard/top-selling-goods?$query');
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

  /// Загрузка данных топ-продаж для конкретного периода
  Future<AllTopSellingData> getTopSellingGoodsForPeriod(
    TopSellingTimePeriod period, {
    int perPage = 7,
  }) async {
    final query = ['per_page=$perPage', 'period=${period.name}'].join('&');
    final path =
        await _appendQueryParams('/dashboard/top-selling-goods?$query');

    debugPrint(
        "ApiService: getTopSellingGoodsForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final topSellingResponse = TopSellingGoodsResponse.fromJson(data);

        return AllTopSellingData(
          period: period,
          data: topSellingResponse.result,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching data for period $period: $e");
      rethrow;
    }
  }

  Future<List<TopSellingCardModel>> getTopSellingCardsByFilter({
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    // try{
    // Формируем параметры запроса

    debugPrint("ApiService: getTopSellingCardsByFilter filters: $filters");

    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        debugPrint("ApiService: filters['date_from']: ${filters['date_from']}");
        final dateFrom = filters['date_from'] as DateTime;
        queryParams['date_from'] = dateFrom.toIso8601String();
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
        final dateTo = filters['date_to'] as DateTime;
        queryParams['date_to'] = dateTo.toIso8601String();
      }

      if (filters.containsKey('sum_from') && filters['sum_from'] != null) {
        debugPrint("ApiService: filters['sum_from']: ${filters['sum_from']}");
        final sumFrom = filters['sum_from'] as double;
        queryParams['sum_from'] = sumFrom.toString();
      }

      if (filters.containsKey('sum_to') && filters['sum_to'] != null) {
        debugPrint("ApiService: filters['sum_to']: ${filters['sum_to']}");
        final sumTo = filters['sum_to'] as double;
        queryParams['sum_to'] = sumTo.toString();
      }

      if (filters.containsKey('good_id') && filters['good_id'] != null) {
        debugPrint("ApiService: filters['good_id']: ${filters['good_id']}");
        final goodId = filters['good_id'] as int;
        queryParams['good_id'] = goodId.toString();
      }

      if (filters.containsKey('category_id') &&
          filters['category_id'] != null) {
        debugPrint(
            "ApiService: filters['category_id']: ${filters['category_id']}");
        final categoryId = filters['category_id'] as int;
        queryParams['category_id'] = categoryId.toString();
      }
    }

    String path = await _appendQueryParams('/dashboard/top-selling-goods');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> dataList = data['result']['data'] as List<dynamic>;

        return dataList
            .map((item) => TopSellingCardModel.fromJson(item))
            .toList();
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных по топ продаваемым товарам!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<SalesResponse> getSalesDynamicsByFilter(
    Map<String, dynamic>? filters,
    String? search,
  ) async {
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('period') && filters['period'] != null) {
        debugPrint("ApiService: filters['period']: ${filters['period']}");
        final period = filters['period'] as DateTime;
        queryParams['period'] = period.toIso8601String();
      }
      if (filters.containsKey('category_id') &&
          filters['category_id'] != null) {
        debugPrint(
            "ApiService: filters['category_id']: ${filters['category_id']}");
        final categoryId = filters['category_id'] as int;
        queryParams['category_id'] = categoryId.toString();
      }
      if (filters.containsKey('good_id') && filters['good_id'] != null) {
        debugPrint("ApiService: filters['good_id']: ${filters['good_id']}");
        final goodId = filters['good_id'] as int;
        queryParams['good_id'] = goodId.toString();
      }
    }
    // Формируем параметры запроса
    var path = await _appendQueryParams('/dashboard/sales-dynamics');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

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

  Future<NetProfitResponse> getNetProfitByFilter(
    Map<String, dynamic>? filters,
    String? search,
  ) async {
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('period') && filters['period'] != null) {
        debugPrint("ApiService: filters['period']: ${filters['period']}");
        final period = filters['period'] as DateTime;
        queryParams['period'] = period.toIso8601String();
      }
      if (filters.containsKey('category_id') &&
          filters['category_id'] != null) {
        debugPrint(
            "ApiService: filters['category_id']: ${filters['category_id']}");
        final categoryId = filters['category_id'] as int;
        queryParams['category_id'] = categoryId.toString();
      }
      if (filters.containsKey('good_id') && filters['good_id'] != null) {
        debugPrint("ApiService: filters['good_id']: ${filters['good_id']}");
        final goodId = filters['good_id'] as int;
        queryParams['good_id'] = goodId.toString();
      }
    }
    // Формируем параметры запроса
    var path = await _appendQueryParams('/dashboard/net-profit');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    debugPrint("ApiService: getNetProfit path: $path");

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return NetProfitResponse.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка',
        response.statusCode,
      );
    }
  }

  Future<ProfitabilityResponse> getProfitabilityByFilter(
    Map<String, dynamic>? filters,
    String? search,
  ) async {
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('period') && filters['period'] != null) {
        debugPrint("ApiService: filters['period']: ${filters['period']}");
        final period = filters['period'] as DateTime;
        queryParams['period'] = period.toIso8601String();
      }
      if (filters.containsKey('category_id') &&
          filters['category_id'] != null) {
        debugPrint(
            "ApiService: filters['category_id']: ${filters['category_id']}");
        final categoryId = filters['category_id'] as int;
        queryParams['category_id'] = categoryId.toString();
      }
      if (filters.containsKey('good_id') && filters['good_id'] != null) {
        debugPrint("ApiService: filters['good_id']: ${filters['good_id']}");
        final goodId = filters['good_id'] as int;
        queryParams['good_id'] = goodId.toString();
      }
    }
    // Формируем параметры запроса
    var path = await _appendQueryParams('/dashboard/profitability');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    debugPrint("ApiService: getProfitability path: $path");

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ProfitabilityResponse.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка',
        response.statusCode,
      );
    }
  }

  Future<DashboardExpenseResponse> getExpenseStructureByFilter(
    Map<String, dynamic>? filters,
    String? search,
  ) async {
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        debugPrint("ApiService: filters['date_from']: ${filters['date_from']}");
        final dateFrom = filters['date_from'] as DateTime;
        queryParams['date_from'] = dateFrom.toIso8601String();
      }
      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
        final dateTo = filters['date_to'] as DateTime;
        queryParams['date_to'] = dateTo.toIso8601String();
      }
      if (filters.containsKey('category_id') &&
          filters['category_id'] != null) {
        debugPrint(
            "ApiService: filters['category_id']: ${filters['category_id']}");
        final categoryId = filters['category_id'] as int;
        queryParams['category_id'] = categoryId.toString();
      }
      if (filters.containsKey('article_id') && filters['article_id'] != null) {
        debugPrint(
            "ApiService: filters['article_id']: ${filters['article_id']}");
        final articleId = filters['article_id'] as int;
        queryParams['article_id'] = articleId.toString();
      }
    }
    // Формируем параметры запроса
    var path = await _appendQueryParams('/fin/dashboard/expense-structure');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    debugPrint("ApiService: getExpenseStructure path: $path");

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DashboardExpenseResponse.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка',
        response.statusCode,
      );
    }
  }

  Future<OrderQuantityContent> getOrderByFilter(
    Map<String, dynamic>? filters,
    String? search,
  ) async {
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        debugPrint("ApiService: filters['date_from']: ${filters['date_from']}");
        final date_from = filters['date_from'] as DateTime;
        queryParams['date_from'] = date_from.toIso8601String();
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
        final date_to = filters['date_to'] as DateTime;
        queryParams['date_to'] = date_to.toIso8601String();
      }

      if (filters.containsKey('sum_from') && filters['sum_from'] != null) {
        debugPrint("ApiService: filters['sum_from']: ${filters['sum_from']}");
        final sumFrom = filters['sum_from'] as double;
        queryParams['sum_from'] = sumFrom.toString();
      }

      if (filters.containsKey('sum_to') && filters['sum_to'] != null) {
        debugPrint("ApiService: filters['sum_to']: ${filters['sum_to']}");
        final sumTo = filters['sum_to'] as double;
        queryParams['sum_to'] = sumTo.toString();
      }

      if (filters.containsKey('status_id') && filters['status_id'] != null) {
        debugPrint("ApiService: filters['status_id']: ${filters['status_id']}");
        final statusID = filters['status_id'] as int;
        queryParams['status_id'] = statusID.toString();
      }
    }
    // Формируем параметры запроса
    var path = await _appendQueryParams('/order/dashboard');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    debugPrint("ApiService: getOrderByFilter path: $path");

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return OrderQuantityContent.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка',
        response.statusCode,
      );
    }
  }

  // metod dlya polucheniya акт сверки
  Future<ActOfReconciliationResponse> getReconciliationAct({
    final String? search,
    final Map<String, dynamic>? filters,
  }) async {
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        debugPrint("ApiService: filters['date_from']: ${filters['date_from']}");
        final date_from = filters['date_from'] as DateTime;
        queryParams['date_from'] = date_from.toIso8601String();
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
        final date_to = filters['date_to'] as DateTime;
        queryParams['date_to'] = date_to.toIso8601String();
      }

      if (filters.containsKey('sum_from') && filters['sum_from'] != null) {
        debugPrint("ApiService: filters['sum_from']: ${filters['sum_from']}");
        final sumFrom = filters['sum_from'] as double;
        queryParams['sum_from'] = sumFrom.toString();
      }

      if (filters.containsKey('sum_to') && filters['sum_to'] != null) {
        debugPrint("ApiService: filters['sum_to']: ${filters['sum_to']}");
        final sumTo = filters['sum_to'] as double;
        queryParams['sum_to'] = sumTo.toString();
      }
    }

    var type = filters!['lead_id'] != null ? 'lead' : 'supplier';
    var id = filters['lead_id'] ?? filters['supplier_id'];

    var queryString = queryParams.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    var path = await _appendQueryParams(
      '/dashboard/act-of-reconciliation/$type/$id?$queryString',
    );

    debugPrint("ApiService: getReconciliationAct path: $path");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ActOfReconciliationResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении акта сверки!',
          response.statusCode,
        );
      }
    } catch (e) {
      throw e;
    }
  }

  // Метод для получения Категорий
  Future<List<CategoryDashboardWarehouse>>
      getCategoryDashboardWarehouse() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/category');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getCategoryDashboardWarehouse - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Полученные данные: $data'); // Для отладки, как в примере
      // Данные в "result", не прямой массив
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList
          .map((category) => CategoryDashboardWarehouse.fromJson(category))
          .toList();
    } else {
      throw Exception('Ошибка загрузки категорий');
    }
  }

// Метод для получения статусов заказов
  Future<List<OrderStatusWarehouse>> getOrderStatusWarehouse() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order-status');
    if (kDebugMode) {
      debugPrint('ApiService: getOrderStatusWarehouse - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Полученные данные: $data'); // Для отладки
      // Данные в "result", не прямой массив
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList
          .map((orderStatus) => OrderStatusWarehouse.fromJson(orderStatus))
          .toList();
    } else {
      throw Exception('Ошибка загрузки статусов заказов');
    }
  }

  Future<List<DashboardGoodsMovementHistory>>
      getDashboardGoodsMovementHistoryList(int goodId) async {
    final path =
        await _appendQueryParams('/dashboard/good-movement-history/$goodId');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getDashboardGoodsMovementHistoryList - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        debugPrint(
            'ApiService: Полученные данные истории движения товара $goodId: $data');
      }
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList
          .map((item) => DashboardGoodsMovementHistory.fromJson(item))
          .toList();
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка при получении истории перемещений товаров!',
        response.statusCode,
      );
    }
  }

  Future<dgrmodel.GoodDashboardWarehouseResponse> getGoodDashboardWarehousePage(
      int page) async {
    try {
      // Form path with page parameter
      String basePath = '/good?page=$page';

      // Add other query parameters (language, token, etc.)
      final path = await _appendQueryParams(basePath);

      if (kDebugMode) {
        debugPrint(
            'ApiService: getGoodDashboardWarehousePage - Loading page $page, path: $path');
      }

      // Execute GET request
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          debugPrint('ApiService: Received data: $data');
        }

        // Parse response
        final resultObj = data['result'] as Map<String, dynamic>?;

        if (resultObj != null) {
          // Parse data list
          final dataList = resultObj['data'] as List? ?? [];
          final goodsList = dataList
              .map((good) => dgrmodel.GoodDashboardWarehouse.fromJson(good))
              .toList();

          // Parse pagination
          if (resultObj['pagination'] != null) {
            final pagination = dgrmodel.Pagination.fromJson(
                resultObj['pagination'] as Map<String, dynamic>);

            if (kDebugMode) {
              debugPrint(
                  'ApiService: Page $page loaded successfully with ${goodsList.length} items');
              debugPrint(
                  'ApiService: Pagination - current: ${pagination.currentPage}, total pages: ${pagination.totalPages}');
            }

            return dgrmodel.GoodDashboardWarehouseResponse(
              data: goodsList,
              pagination: pagination,
            );
          } else {
            return dgrmodel.GoodDashboardWarehouseResponse(
              data: goodsList,
              pagination: null,
            );
          }
        } else {
          // If result is empty, return empty response
          return dgrmodel.GoodDashboardWarehouseResponse(
            data: [],
            pagination: null,
          );
        }
      } else {
        throw Exception(
            'Ошибка при получении данных со страницы $page! Статус: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: Error loading page $page: $e');
      }
      rethrow;
    }
  }

// Метод для получения Статей расхода
  Future<List<ExpenseArticleDashboardWarehouse>>
      getExpenseArticleDashboardWarehouse() async {
    final path = await _appendQueryParams('/article?type=expense');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getExpenseArticleDashboardWarehouse - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Полученные данные статей расхода: $data');

      // Navigate to nested data: result -> data
      final resultData = data['result'];
      if (resultData == null) {
        return [];
      }

      final dataList = resultData['data'] as List?;
      if (dataList == null) {
        return [];
      }

      return dataList
          .map((article) => ExpenseArticleDashboardWarehouse.fromJson(article))
          .toList();
    } else {
      throw Exception('Ошибка загрузки статей расхода');
    }
  }

  // used for getting all articles (income and expense)
  Future<List<ArticleGood>> getAllExpenseArticles() async {
    final path = await _appendQueryParams('/article?type=expense');

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['result']['data'] != null) {
          List<ArticleGood> articles = [];
          for (var item in data['result']['data']) {
            articles.add(ArticleGood.fromJson(item));
          }
          return articles;
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

// _______________________________SECTION FOR FIELD CONFIGURATION _______________________________

// В секции API__SCREEN__LEAD

// Метод для получения конфигурации полей (уже есть)
  Future<FieldConfigurationResponse> getFieldPositions({
    required String tableName,
  }) async {
    try {
      final path = await _appendQueryParams('/field-position?table=$tableName');

      if (kDebugMode) {
        debugPrint('ApiService: getFieldPositions - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FieldConfigurationResponse.fromJson(data);
      } else {
        throw Exception(
            'Ошибка загрузки конфигурации полей: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: getFieldPositions - Error: $e');
      }
      throw Exception('Ошибка загрузки конфигурации полей!');
    }
  }

  // not used
// Новый метод для сохранения конфигурации в кэш
  Future<void> cacheFieldConfiguration({
    required String tableName,
    required FieldConfigurationResponse configuration,
  }) async {
    // Кэширование конфигурации временно отключено.
    // try {
    //   final prefs = await SharedPreferences.getInstance();
    //   final organizationId = await getSelectedOrganization();
    //   final cacheKey = 'field_config_${tableName}_org_${organizationId}';
    //
    //   final jsonData = json.encode(configuration.toJson());
    //   await prefs.setString(cacheKey, jsonData);
    //
    //   // Сохраняем timestamp последнего обновления
    //   await prefs.setInt('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    //
    //   if (kDebugMode) {
    //     debugPrint('ApiService: Cached field configuration for $tableName');
    //   }
    // } catch (e) {
    //   if (kDebugMode) {
    //     debugPrint('ApiService: Error caching field configuration: $e');
    //   }
    // }
  }

  // not used
// Новый метод для получения конфигурации из кэша
  Future<FieldConfigurationResponse?> getCachedFieldConfiguration({
    required String tableName,
  }) async {
    // Кэширование конфигурации временно отключено, всегда возвращаем null.
    return null;
    // try {
    //   final prefs = await SharedPreferences.getInstance();
    //   final organizationId = await getSelectedOrganization();
    //   final cacheKey = 'field_config_${tableName}_org_${organizationId}';
    //
    //   final cachedData = prefs.getString(cacheKey);
    //
    //   if (cachedData != null) {
    //     final jsonData = json.decode(cachedData);
    //     final config = FieldConfigurationResponse.fromJson(jsonData);
    //
    //     if (kDebugMode) {
    //       debugPrint('ApiService: Loaded cached field configuration for $tableName');
    //     }
    //
    //     return config;
    //   }
    //
    //   return null;
    // } catch (e) {
    //   if (kDebugMode) {
    //     debugPrint('ApiService: Error loading cached field configuration: $e');
    //   }
    //   return null;
    // }
  }

  // not used
// Метод для загрузки и кэширования всех конфигураций
  Future<void> loadAndCacheAllFieldConfigurations() async {
    try {
      if (kDebugMode) {
        debugPrint('ApiService: Loading all field configurations');
      }

      final tables = ['leads', 'tasks', 'deals', 'orders'];

      for (final tableName in tables) {
        try {
          final config = await getFieldPositions(tableName: tableName);
          // not used as this method is not used
          await cacheFieldConfiguration(
              tableName: tableName, configuration: config);

          if (kDebugMode) {
            debugPrint(
                'ApiService: Successfully cached configuration for $tableName');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'ApiService: Error loading configuration for $tableName: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('ApiService: Finished loading all field configurations');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ApiService: Error in loadAndCacheAllFieldConfigurations: $e');
      }
    }
  }

  // not used
// Метод для очистки кэша конфигураций (при смене организации)
  Future<void> clearFieldConfigurationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final organizationId = await getSelectedOrganization();

      final tables = ['leads', 'tasks', 'deals', 'orders'];

      for (final tableName in tables) {
        final cacheKey = 'field_config_${tableName}_org_${organizationId}';
        await prefs.remove(cacheKey);
        await prefs.remove('${cacheKey}_timestamp');
      }

      if (kDebugMode) {
        debugPrint('ApiService: Cleared all field configuration cache');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: Error clearing field configuration cache: $e');
      }
    }
  }

  // not used
// Метод для очистки кэша конфигурации конкретной таблицы
  Future<void> clearFieldConfigurationCacheForTable(String tableName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final organizationId = await getSelectedOrganization();

      final cacheKey = 'field_config_${tableName}_org_$organizationId';
      await prefs.remove(cacheKey);
      await prefs.remove('${cacheKey}_timestamp');

      if (kDebugMode) {
        debugPrint(
            'ApiService: Cleared field configuration cache for $tableName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ApiService: Error clearing field configuration cache for $tableName: $e');
      }
    }
  }

// Метод для обновления позиций полей
  Future<Map<String, dynamic>> updateFieldPositions({
    required String tableName,
    required List<Map<String, dynamic>> updates,
  }) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/field-position?table=$tableName');

      if (kDebugMode) {
        debugPrint('ApiService: updateFieldPositions - Generated path: $path');
        debugPrint('ApiService: updateFieldPositions - Updates: $updates');
      }

      // Подготавливаем тело запроса
      final organizationId = await getSelectedOrganization();
      final salesFunnelId = await getSelectedSalesFunnel();

      final normalizedUpdates = updates.map((update) {
        if (update.containsKey('show_on_site')) {
          return {
            ...update,
            'show_to_site': update['show_on_site'],
          }..remove('show_on_site');
        }
        return update;
      }).toList();

      final body = {
        'updates': normalizedUpdates,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
      };

      final response = await _patchRequest(path, body);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('ApiService: Field positions updated successfully');
        }
        return {
          'success': true,
          'message': 'Field positions updated successfully',
        };
      } else {
        throw Exception(
            'Ошибка обновления позиций полей: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: updateFieldPositions - Error: $e');
      }
      throw Exception('Ошибка обновления позиций полей: $e');
    }
  }

  Future<dynamic> addNewField({
    required String tableName,
    required String fieldName,
    required String fieldType,
  }) async {
    final path = await _appendQueryParams('/field-position');
    final body = {
      "table": tableName,
      "field_name": fieldName,
      "type": fieldType
    };

    try {
      final response = await _postRequest(path, body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при добавлении нового поля',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // GET lead custom fields
  // lead/get/custom-fields?organization_id=1&sales_funnel_id=1
  // response.result is list of strings
  Future<List<String>> getLeadCustomFields() async {
    final path = await _appendQueryParams('/lead/get/custom-fields');

    if (kDebugMode) {
      debugPrint('ApiService: getLeadCustomFields - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList.map((field) => field.toString()).toList();
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка загрузки пользовательских полей лидов',
        response.statusCode,
      );
    }
  }

  // GET custom field values by key (we get key from getLeadCustomFields)
  // lead/get/custom-field-values?key=aa&organization_id=1&sales_funnel_id=1
  // response.result is list of strings
  Future<List<String>> getLeadCustomFieldValues(String key) async {
    final path =
        await _appendQueryParams('/lead/get/custom-field-values?key=$key');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getLeadCustomFieldValues - Generated path: $path');
    }
    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList.map((value) => value.toString()).toList();
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка загрузки значений пользовательского поля лидов',
        response.statusCode,
      );
    }
  }

  // GET deal custom fields
  // lead/get/custom-fields?organization_id=1&sales_funnel_id=1
  // response.result is list of strings
  Future<List<String>> getDealCustomFields() async {
    final path = await _appendQueryParams('/deal/get/custom-fields');

    if (kDebugMode) {
      debugPrint('ApiService: getLeadCustomFields - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList.map((field) => field.toString()).toList();
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка загрузки пользовательских полей лидов',
        response.statusCode,
      );
    }
  }

  // GET custom field values by key (we get key from getLeadCustomFields)
  // lead/get/custom-field-values?key=aa&organization_id=1&sales_funnel_id=1
  // response.result is list of strings
  Future<List<String>> getDealCustomFieldValues(String key) async {
    final path =
        await _appendQueryParams('/deal/get/custom-field-values?key=$key');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getLeadCustomFieldValues - Generated path: $path');
    }
    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList.map((value) => value.toString()).toList();
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка загрузки значений пользовательского поля лидов',
        response.statusCode,
      );
    }
  }
  //  ================================= TASK CUSTOM FIELDS ================================

  Future<List<String>> getTaskCustomFields() async {
    final path = await _appendQueryParams('/field-position?table=tasks');

    if (kDebugMode) {
      debugPrint('ApiService: getTaskCustomFields - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List<dynamic>?;
      final ls = resultList
              ?.where((e) => e['is_custom_field'] == true)
              .map((e) => e['field_name'] as String)
              .toList() ??
          <String>[];

      if (kDebugMode) {
        debugPrint(
            'ApiService: getTaskCustomFields - Response status: ${response.statusCode}');
        debugPrint('ApiService: getTaskCustomFields - Response ls: $ls');
      }

      return ls;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка загрузки пользовательских полей задач',
        response.statusCode,
      );
    }
  }

  // GET custom field values by key (we get key from getLeadCustomFields)
  // lead/get/custom-field-values?key=aa&organization_id=1&sales_funnel_id=1
  // response.result is list of strings
  Future<List<String>> getTaskCustomFieldValues(String key) async {
    final path =
        await _appendQueryParams('/task/get/custom-field-values?key=$key');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getTaskCustomFieldValues - Generated path: $path');
    }
    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList.map((value) => value.toString()).toList();
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка загрузки значений пользовательского поля задач',
        response.statusCode,
      );
    }
  }

// _______________________________END SECTION FOR FIELD CONFIGURATION _______________________________

// _______________________________START SECTION FOR OPENINGS (Первоначальный остаток) _______________________________

  //==================== OPENING GOOD SECTION ================
  /// Получить первоначальные остатки по товарам
  Future<GoodsOpeningsResponse> getGoodsOpenings({String? search}) async {
    String path = await _appendQueryParams('/good-initial-balance');

    path += '&is_service=0';

    // Добавляем параметр search, если он передан
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    if (kDebugMode) {
      debugPrint('ApiService: getGoodsOpenings - path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return GoodsOpeningsResponse.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка получения первоначальных остатков по товарам',
        response.statusCode,
      );
    }
  }

  /// Получить варианты товаров
  Future<GoodVariantsResponse> getOpeningsGoodVariants({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      String path = await _appendQueryParams(
          '/good/get/variant?page=$page&per_page=$perPage');

      path += '&is_service=0';

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GoodVariantsResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка получения вариантов товаров",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удалить первоначальный остаток товара
  Future<Map<String, dynamic>> deleteGoodsOpening(int id) async {
    try {
      String path = await _appendQueryParams('/good-initial-balance/$id');
      final response = await _deleteRequest(path);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? "Ошибка удаления остатка товара", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создать первоначальный остаток товара
  Future<Map<String, dynamic>> createGoodsOpening({
    required int goodVariantId,
    required int supplierId,
    required double price,
    required double quantity,
    required int unitId,
    required int storageId,
  }) async {
    try {
      String path = await _appendQueryParams('/good-initial-balance');

      final body = {
        "data": [
          {
            "good_variant_id": goodVariantId,
            "supplier_id": supplierId,
            "price": price,
            "quantity": quantity,
            "unit_id": unitId,
            "storage_id": storageId,
          }
        ],
      };

      if (kDebugMode) {
        debugPrint('ApiService: createGoodsOpening - path: $path');
        debugPrint('ApiService: createGoodsOpening - body: $body');
      }

      final response = await _postRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка создания остатка товара",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновить первоначальный остаток товара
  Future<Map<String, dynamic>> updateGoodsOpening({
    required int id,
    required int goodVariantId,
    required int supplierId,
    required double price,
    required double quantity,
    required int unitId,
    required int storageId,
  }) async {
    try {
      String path = await _appendQueryParams('/good-initial-balance/$id');

      final body = {
        "good_variant_id": goodVariantId,
        "supplier_id": supplierId,
        "price": price,
        "quantity": quantity,
        "unit_id": unitId,
        "storage_id": storageId,
      };

      if (kDebugMode) {
        debugPrint('ApiService: updateGoodsOpening - path: $path');
        debugPrint('ApiService: updateGoodsOpening - body: $body');
      }

      final response = await _patchRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка обновления остатка товара",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  //========= OPENING CLIENT SECTION ==========

  /// Получить первоначальные остатки по клиентам
  Future<ClientOpeningsResponse> getClientOpenings({String? search}) async {
    String path = await _appendQueryParams('/initial-balance/lead');

    // Добавляем параметр search, если он передан
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    if (kDebugMode) {
      debugPrint('ApiService: getClientOpenings - path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ClientOpeningsResponse.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка получения первоначальных остатков по клиентам',
        response.statusCode,
      );
    }
  }

  /// Получить список клиентов/лидов для диалога выбора
  Future<List<opening_lead.Lead>> getClientOpeningsForDialog(
      {String? search}) async {
    try {
      String path = await _appendQueryParams('/initial-balance/get/leads');
      if (search != null && search.trim().isNotEmpty) {
        path += '&search=${Uri.encodeComponent(search.trim())}';
      }
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Проверяем, является ли ответ массивом (API возвращает массив напрямую)
        if (data is List) {
          // Преобразуем массив в ожидаемую структуру
          return data
              .map<opening_lead.Lead>(
                  (item) => opening_lead.Lead.fromJson(item))
              .toList();
        } else {
          return [];
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка получения списка клиентов",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удалить первоначальный остаток клиента
  Future<Map<String, dynamic>> deleteClientOpening(int id) async {
    try {
      String path = await _appendQueryParams('/initial-balance/$id');
      final response = await _deleteRequest(path);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? "Ошибка удаления остатка клиента", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создать первоначальный остаток клиента
  Future<Map<String, dynamic>> createClientOpening({
    required int leadId,
    required double ourDuty,
    required double debtToUs,
  }) async {
    try {
      String path = await _appendQueryParams('/initial-balance');

      final body = {
        'data': [
          {
            "type": "lead",
            "counterparty_id": leadId,
            "our_duty": ourDuty,
            "debt_to_us": debtToUs,
          }
        ]
      };

      if (kDebugMode) {
        debugPrint('ApiService: createClientOpening - path: $path');
        debugPrint('ApiService: createClientOpening - body: $body');
      }

      final response = await _postRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка создания остатка клиента",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создать первоначальный остаток клиента
  Future<Map<String, dynamic>> updateClientOpening({
    required int id,
    required int leadId,
    required double ourDuty,
    required double debtToUs,
  }) async {
    try {
      String path = await _appendQueryParams('/initial-balance/$id');

      final body = {
        "type": "lead",
        "counterparty_id": leadId,
        "our_duty": ourDuty,
        "debt_to_us": debtToUs,
      };

      if (kDebugMode) {
        debugPrint('ApiService: createClientOpening - path: $path');
        debugPrint('ApiService: createClientOpening - body: $body');
      }

      final response = await _patchRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка создания остатка клиента",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  //========= OPENING SUPPLIER SECTION ==========

  /// Получить первоначальные остатки по поставщикам
  Future<SupplierOpeningsResponse> getSupplierOpenings({String? search}) async {
    String path = await _appendQueryParams('/initial-balance/supplier');

    // Добавляем параметр search, если он передан
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    if (kDebugMode) {
      debugPrint('ApiService: getSupplierOpenings - path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SupplierOpeningsResponse.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка получения первоначальных остатков по поставщикам',
        response.statusCode,
      );
    }
  }

  /// Создать первоначальный остаток поставщика
  Future<Map<String, dynamic>> createSupplierOpening({
    required int supplierId,
    required double ourDuty,
    required double debtToUs,
  }) async {
    try {
      String path = await _appendQueryParams('/initial-balance');

      final body = {
        'data': [
          {
            "type": "supplier",
            "counterparty_id": supplierId,
            "our_duty": ourDuty,
            "debt_to_us": debtToUs,
          }
        ]
      };

      if (kDebugMode) {
        debugPrint('ApiService: createSupplierOpening - path: $path');
        debugPrint('ApiService: createSupplierOpening - body: $body');
      }

      final response = await _postRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка создания остатка поставщика",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Редактировать начальный остаток поставщика
  Future<Map<String, dynamic>> editSupplierOpening({
    required int id,
    required int supplierId,
    required double ourDuty,
    required double debtToUs,
  }) async {
    try {
      String path = await _appendQueryParams('/initial-balance/$id');

      final body = {
        "type": "supplier",
        "counterparty_id": supplierId,
        "our_duty": ourDuty,
        "debt_to_us": debtToUs,
      };

      if (kDebugMode) {
        debugPrint('ApiService: editSupplierOpening - path: $path');
        debugPrint('ApiService: editSupplierOpening - body: $body');
      }

      final response = await _patchRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка редактирования остатка поставщика",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удалить первоначальный остаток поставщика
  Future<Map<String, dynamic>> deleteSupplierOpening(int id) async {
    try {
      String path = await _appendQueryParams('/initial-balance/$id');
      final response = await _deleteRequest(path);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? "Ошибка удаления остатка поставщика",
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получить список поставщиков для диалога выбора
  Future<opening_supplier.SuppliersForOpeningsResponse> getOpeningsSuppliers(
      {String? search}) async {
    try {
      String path = await _appendQueryParams('/initial-balance/get/suppliers');
      if (search != null && search.trim().isNotEmpty) {
        path += '&search=${Uri.encodeComponent(search.trim())}';
      }
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Проверяем, является ли ответ массивом (API возвращает массив напрямую)
        if (data is List) {
          // Преобразуем массив в ожидаемую структуру
          return opening_supplier.SuppliersForOpeningsResponse.fromJson({
            'result': data,
            'errors': null,
          });
        } else {
          // Если ответ уже в правильном формате (с полем result)
          return opening_supplier.SuppliersForOpeningsResponse.fromJson(data);
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка получения списка поставщиков",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ========== OPENING Cash Register =========
  /// Получить первоначальные остатки по кассам/складам
  Future<openings.CashRegisterOpeningsResponse> getCashRegisterOpenings(
      {String? search}) async {
    String path = await _appendQueryParams('/cash-register-initial-balance');

    // Добавляем параметр search, если он передан
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    if (kDebugMode) {
      debugPrint('🔵 ApiService: getCashRegisterOpenings - path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (kDebugMode) {
        debugPrint(
            '🔵 ApiService: getCashRegisterOpenings - statusCode: ${response.statusCode}');
        debugPrint(
            '🔵 ApiService: getCashRegisterOpenings - body length: ${response.body.length}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          debugPrint(
              '🔵 ApiService: getCashRegisterOpenings - JSON decoded successfully');
          debugPrint(
              '🔵 ApiService: getCashRegisterOpenings - JSON keys: ${data is Map ? (data as Map).keys.toList() : "not a map"}');
          if (data is Map && data["result"] != null) {
            final result = data["result"];
            debugPrint(
                '🔵 ApiService: getCashRegisterOpenings - result type: ${result.runtimeType}');
            if (result is Map) {
              debugPrint(
                  '🔵 ApiService: getCashRegisterOpenings - result keys: ${result.keys.toList()}');
              if (result["data"] != null) {
                debugPrint(
                    '🔵 ApiService: getCashRegisterOpenings - data type: ${result["data"].runtimeType}');
                if (result["data"] is List) {
                  debugPrint(
                      '🔵 ApiService: getCashRegisterOpenings - data length: ${(result["data"] as List).length}');
                  if ((result["data"] as List).isNotEmpty) {
                    debugPrint(
                        '🔵 ApiService: getCashRegisterOpenings - first item keys: ${(result["data"] as List)[0] is Map ? ((result["data"] as List)[0] as Map).keys.toList() : "not a map"}');
                  }
                }
              }
            } else if (result is List) {
              debugPrint(
                  '🔵 ApiService: getCashRegisterOpenings - result is List, length: ${result.length}');
            }
          }
        }

        final parsedResponse =
            openings.CashRegisterOpeningsResponse.fromJson(data);

        if (kDebugMode) {
          debugPrint(
              '🔵 ApiService: getCashRegisterOpenings - parsed successfully');
          debugPrint(
              '🔵 ApiService: getCashRegisterOpenings - result count: ${parsedResponse.result?.length ?? 0}');
        }

        return parsedResponse;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        if (kDebugMode) {
          debugPrint(
              '🔴 ApiService: getCashRegisterOpenings - error status: ${response.statusCode}, message: $message');
        }
        throw ApiException(
          message ??
              'Ошибка получения первоначальных остатков по кассам/складам',
          response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('🔴 ApiService: getCashRegisterOpenings - EXCEPTION: $e');
        debugPrint(
            '🔴 ApiService: getCashRegisterOpenings - STACK: $stackTrace');
      }
      rethrow;
    }
  }

  /// Получить список касс для выбора при создании остатка кассы
  Future<List<openings.CashRegister>> getCashRegisters({String? search}) async {
    try {
      String path =
          await _appendQueryParams('/initial-balance/get/cash-registers');
      if (search != null && search.trim().isNotEmpty) {
        path += '&search=${Uri.encodeComponent(search.trim())}';
      }

      if (kDebugMode) {
        debugPrint('ApiService: getCashRegisters - path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return data
              .map((json) => openings.CashRegister.fromJson(json))
              .toList();
        } else {
          throw Exception('Неожиданный формат ответа API');
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка получения списка касс',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: getCashRegisters - Error: $e');
      }
      rethrow;
    }
  }

  /// Создать первоначальный остаток кассы
  Future<Map<String, dynamic>> createCashRegisterOpening({
    required int cashRegisterId,
    required String sum,
  }) async {
    try {
      String path = await _appendQueryParams('/cash-register-initial-balance');

      final body = {
        'data': [
          {
            'cash_register_id': cashRegisterId,
            'sum': sum,
          }
        ]
      };

      if (kDebugMode) {
        debugPrint(
            'ApiService: createCashRegisterOpening - path: $path, body: $body');
      }

      final response = await _postRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка создания остатка кассы',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: createCashRegisterOpening - Error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCashRegisterOpening({
    required int id,
    required int cashRegisterId,
    required String sum,
  }) async {
    try {
      String path =
          await _appendQueryParams('/cash-register-initial-balance/$id');

      final body = {
        'cash_register_id': cashRegisterId,
        'sum': sum,
      };

      if (kDebugMode) {
        debugPrint(
            'ApiService: createCashRegisterOpening - path: $path, body: $body');
      }

      final response = await _patchRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка создания остатка кассы',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: createCashRegisterOpening - Error: $e');
      }
      rethrow;
    }
  }

  /// Удалить первоначальный остаток кассы
  Future<Map<String, dynamic>> deleteCashRegisterOpening(int id) async {
    try {
      String path =
          await _appendQueryParams('/cash-register-initial-balance/$id');
      final response = await _deleteRequest(path);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? "Ошибка удаления остатка кассы", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

// ======================================== END SECTION FOR OPENINGS ========================================

  Future<GoodVariantsResponse> getGoodVariantsForDropdown({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    String path = '/good/get/variant?page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search)}';
    }

    path += '&is_service=0';

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      debugPrint(
          'ApiService: getGoodVariantsForDropdown - Generated path: $path');
    }

    final response = await _getRequest(path);
    if (kDebugMode) {
      debugPrint(
          'ApiService: Ответ сервера: statusCode=${response.statusCode}');
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final variantsResponse = GoodVariantsResponse.fromJson(data);

      if (kDebugMode) {
        debugPrint(
            'ApiService: Успешно получено ${variantsResponse.result?.data?.length ?? 0} вариантов товаров');
        if (variantsResponse.result?.pagination != null) {
          debugPrint(
              'ApiService: Pagination - current: ${variantsResponse.result!.pagination!.currentPage}, total pages: ${variantsResponse.result!.pagination!.totalPages}');
        }
      }

      return variantsResponse;
    } else {
      if (kDebugMode) {
        debugPrint(
            'ApiService: Ошибка загрузки вариантов товаров: ${response.statusCode}');
      }
      throw Exception(
          'Ошибка загрузки вариантов товаров: ${response.statusCode}');
    }
  }

  // ======================================== LOCALIZATION API ========================================

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
