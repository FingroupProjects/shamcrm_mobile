import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase_api.dart';
import 'package:crm_task_manager/api/service/secure_storage_service.dart';
import 'package:crm_task_manager/bloc/My-Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_bloc.dart';
import 'package:crm_task_manager/bloc/auth_domain/domain_bloc.dart';
import 'package:crm_task_manager/bloc/author/get_all_author_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/operator_bloc/operator_bloc.dart';
import 'package:crm_task_manager/bloc/cash_desk/cash_desk_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_bloc.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_bloc.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_bloc.dart';
import 'package:crm_task_manager/bloc/chats/template_bloc/template_bloc.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/lead_chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/process_speed/ProcessSpeed_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/user_task/user_task_bloc.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_bloc.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_list_bloc.dart';
import 'package:crm_task_manager/bloc/deal_task/deal_task_bloc.dart';
import 'package:crm_task_manager/bloc/directory_bloc/directory_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/eventByID/event_byId_bloc.dart';
import 'package:crm_task_manager/bloc/expense/expense_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_bloc.dart';
import 'package:crm_task_manager/bloc/history_my-task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/income/income_bloc.dart';
import 'package:crm_task_manager/bloc/income_category_list/income_category_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_multi_list/lead_multi_bloc.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_bloc.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_bloc.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_bloc.dart';
import 'package:crm_task_manager/bloc/history_deal/deal_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead/history_bloc.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/my-task_status_add/task_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_bloc.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/cash_balance/sales_dashboard_cash_balance_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/creditors/sales_dashboard_creditors_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/debtors/sales_dashboard_debtors_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_return/client_return_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_sale/bloc/client_sale_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_sale/bloc/client_sale_document_history/bloc/client_sale_document_history_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/article_bloc/expense_article_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/units_bloc/units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/storage/bloc/storage_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/supplier_return/supplier_return_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/write_off/write_off_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_by_id/goodsById_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/lead_order.dart/lead_order_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bottom_sheet_bloc/variant_bottom_sheet_bloc.dart';
import 'package:crm_task_manager/bloc/permission/permession_bloc.dart';
import 'package:crm_task_manager/bloc/pricce_type/price_type_bloc.dart';
import 'package:crm_task_manager/bloc/profile/profile_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/bloc/role/role_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_bloc.dart';
import 'package:crm_task_manager/bloc/source_list/source_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_bloc.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/task_status_add/task_bloc.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/bloc/user/create_cleant/create_client_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/firebase_options.dart';
import 'package:crm_task_manager/screens/auth/pin_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/auth/pin_setup_screen.dart';
import 'package:crm_task_manager/screens/auth/auth_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/languages/local_manager_lang.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc/cash_register_list/cash_register_list_bloc.dart';
import 'bloc/page_2_BLOC/document/incoming/incoming_document_history/incoming_document_history_bloc.dart';
import 'bloc/supplier_list/supplier_list_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    //print("====================== MAIN START ======================");

    // ШАГ 1: Безопасная инициализация Firebase
    await _initializeFirebase();

    // ШАГ 2: Инициализация сервисов
    final apiService = ApiService();
    final authService = AuthService();

    // ШАГ 3: Глобальная проверка валидности данных
    final sessionValidation = await _validateApplicationSession(apiService);

    // ШАГ 4: Получение токена и PIN только если сессия валидна
    String? token;
    String? pin;
    bool isDomainChecked = false;

    if (sessionValidation.isValid) {
      token = await apiService.getToken();
      pin = await authService.getPin();
      isDomainChecked = await apiService.isDomainChecked();

      if (isDomainChecked) {
        await apiService.initialize();
      }
    } else {
      //print('main: Invalid session detected, clearing all data');
      await _clearAllApplicationData(apiService, authService);
    }

    // ШАГ 5: App Tracking Transparency
    await AppTrackingTransparency.requestTrackingAuthorization();

    // ШАГ 6: Firebase Messaging инициализация
    await _initializeFirebaseMessaging(apiService);

    // ШАГ 7: Получение initial message (только если Firebase готов)
    RemoteMessage? initialMessage;
    try {
      if (Firebase.apps.isNotEmpty) {
        initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          //print('main: Initial message получено: ${initialMessage.messageId}');
        }
      }
    } catch (e) {
      //print('main: Ошибка получения initial message: $e');
    }

    // ШАГ 8: UI настройки
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
      ),
    );

    // ШАГ 9: Языковые настройки
    final String? savedLanguageCode = await LanguageManager.getLanguage();
    final Locale savedLocale = savedLanguageCode != null
        ? Locale(savedLanguageCode)
        : const Locale('ru');

    // ШАГ 10: Запуск приложения
    runApp(MyApp(
      apiService: apiService,
      authService: authService,
      isDomainChecked: isDomainChecked && sessionValidation.isValid,
      token: sessionValidation.isValid ? token : null,
      pin: sessionValidation.isValid ? pin : null,
      initialLocale: savedLocale,
      initialMessage: initialMessage,
      sessionValid: sessionValidation.isValid,
    ));
  } catch (e, stackTrace) {
    //print('Критическая ошибка при запуске приложения: $e');
    //print('StackTrace: $stackTrace');

    // Показываем экран ошибки вместо краша
    runApp(ErrorApp(error: e.toString()));
  }
}

// =============================================================================
// БЕЗОПАСНАЯ ИНИЦИАЛИЗАЦИЯ FIREBASE
// =============================================================================

Future<void> _initializeFirebase() async {
  try {
    //print('Firebase: Проверка состояния инициализации');
    
    // Проверка 1: Проверяем список приложений
    if (Firebase.apps.isEmpty) {
      //print('Firebase: Начинаем первичную инициализацию');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      //print('Firebase: Первичная инициализация завершена успешно');
      
      // Даём время полностью инициализироваться
      await Future.delayed(const Duration(milliseconds: 500));
      
    } else {
      //print('Firebase: Приложение уже существует (apps.length = ${Firebase.apps.length})');
      
      // Проверка 2: Убеждаемся что default app доступен
      try {
        final app = Firebase.app();
        //print('Firebase: Default app доступен и готов (name: ${app.name})');
      } catch (e) {
        //print('Firebase: Default app существует но недоступен: $e');
        // Даём время на инициализацию
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    // Финальная проверка готовности
    try {
      final app = Firebase.app();
      //print('Firebase: Финальная проверка пройдена (name: ${app.name})');
    } catch (e) {
      //print('Firebase: Предупреждение - default app может быть не готов: $e');
    }
    
  } catch (e) {
    final errorString = e.toString();
    
    // Обрабатываем специфичные ошибки
    if (errorString.contains('already exists') || 
        errorString.contains('duplicate app')) {
      //print('Firebase: Приложение уже было инициализировано (это нормально)');
      
      // Даём время на полную инициализацию
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Проверяем доступность
      try {
        Firebase.app();
        //print('Firebase: После ошибки "already exists" - app доступен');
      } catch (checkError) {
        //print('Firebase: После ошибки "already exists" - app НЕ доступен: $checkError');
      }
      
    } else {
      // Это реальная критическая ошибка
      //print('Firebase: КРИТИЧЕСКАЯ ОШИБКА инициализации: $e');
      // НЕ пробрасываем ошибку - даём приложению запуститься без Firebase
    }
  }
}

// =============================================================================
// БЕЗОПАСНАЯ ИНИЦИАЛИЗАЦИЯ FIREBASE MESSAGING
// =============================================================================

Future<void> _initializeFirebaseMessaging(ApiService apiService) async {
  try {
    //print('Firebase Messaging: Начало инициализации');
    
    // Проверка 1: Firebase инициализирован?
    if (Firebase.apps.isEmpty) {
      //print('Firebase Messaging: Firebase не инициализирован, пропуск');
      return;
    }

    // Проверка 2: Default app доступен?
    try {
      final app = Firebase.app();
      //print('Firebase Messaging: Default app доступен (${app.name})');
    } catch (e) {
      //print('Firebase Messaging: Default app недоступен: $e');
      return;
    }

    // Проверка 3: Дополнительное время на готовность
    await Future.delayed(const Duration(milliseconds: 500));

    // Запрос разрешений
    //print('Firebase Messaging: Запрос разрешений');
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    //print('Firebase Messaging: Разрешения получены (status: ${settings.authorizationStatus})');

    // Получение FCM токена
    await getFCMTokens(apiService);

    // Инициализация FirebaseApi
    try {
      FirebaseApi firebaseApi = FirebaseApi();
      await firebaseApi.initNotifications();
      //print('Firebase Messaging: FirebaseApi инициализирован успешно');
    } catch (e) {
      //print('Firebase Messaging: Ошибка инициализации FirebaseApi: $e');
    }

    //print('Firebase Messaging: Инициализация завершена успешно');
    
  } catch (e) {
    final errorString = e.toString();
    
    if (errorString.contains('already exists') || 
        errorString.contains('duplicate')) {
      //print('Firebase Messaging: Сервис уже инициализирован (нормально)');
    } else {
      //print('Firebase Messaging: Ошибка инициализации: $e');
    }
    // НЕ пробрасываем ошибку - приложение должно работать
  }
}

// =============================================================================
// ПОЛУЧЕНИЕ FCM ТОКЕНА
// =============================================================================

// В main.dart - ИЗМЕНЯЕМ функцию getFCMTokens
Future<void> getFCMTokens(ApiService apiService) async {
  try {
    //print('FCM Token: Начало получения');
    
    // Проверка Firebase
    if (Firebase.apps.isEmpty) {
      //print('FCM Token: Firebase не инициализирован');
      return;
    }

    // Проверка доступности
    try {
      Firebase.app();
    } catch (e) {
      //print('FCM Token: Default app недоступен: $e');
      return;
    }

    // Получение токена
    final String? fcmToken = await FirebaseMessaging.instance.getToken();
    
    if (fcmToken != null && fcmToken.isNotEmpty) {
      //print('FCM Token: Успешно получен (${fcmToken.substring(0, 20)}...)');
      //print('FCM Token: Полный токен: $fcmToken');
      
      // ✅ ОТПРАВЛЯЕМ ТОКЕН НА СЕРВЕР
      try {
        await apiService.sendDeviceToken(fcmToken);
        //print('FCM Token: Успешно отправлен на сервер');
      } catch (e) {
        //print('FCM Token: Ошибка отправки на сервер: $e');
      }
      
    } else {
      //print('FCM Token: Токен не получен (null или пустой)');
    }
    
  } catch (e) {
    //print('FCM Token: Ошибка получения: $e');
  }
}

// =============================================================================
// ВАЛИДАЦИЯ СЕССИИ
// =============================================================================

class SessionValidationResult {
  final bool isValid;
  final String? errorMessage;

  SessionValidationResult({required this.isValid, this.errorMessage});
}

Future<SessionValidationResult> _validateApplicationSession(
    ApiService apiService) async {
  try {
    //print('main: Validating application session');

    final token = await apiService.getToken();
    if (token == null || token.isEmpty) {
      //print('main: No token found');
      return SessionValidationResult(isValid: false, errorMessage: 'No token');
    }

    String? domain = await apiService.getVerifiedDomain();
    if (domain == null || domain.isEmpty) {
      Map<String, String?> qrData = await apiService.getQrData();
      String? qrDomain = qrData['domain'];
      String? qrMainDomain = qrData['mainDomain'];

      if (qrDomain == null ||
          qrDomain.isEmpty ||
          qrMainDomain == null ||
          qrMainDomain.isEmpty) {
        Map<String, String?> domains = await apiService.getEnteredDomain();
        String? enteredDomain = domains['enteredDomain'];
        String? enteredMainDomain = domains['enteredMainDomain'];

        if (enteredDomain == null ||
            enteredDomain.isEmpty ||
            enteredMainDomain == null ||
            enteredMainDomain.isEmpty) {
          //print('main: No valid domain configuration found');
          return SessionValidationResult(
              isValid: false, errorMessage: 'No domain');
        }
      }
    }

    final organizationId = await apiService.getSelectedOrganization();
    if (organizationId == null || organizationId.isEmpty) {
      //print('main: No organization selected');
    }

    //print('main: Session validation successful');
    return SessionValidationResult(isValid: true);
  } catch (e) {
    //print('main: Error validating session: $e');
    return SessionValidationResult(isValid: false, errorMessage: e.toString());
  }
}

// =============================================================================
// ОЧИСТКА ДАННЫХ
// =============================================================================

Future<void> _clearAllApplicationData(
    ApiService apiService, AuthService authService) async {
  try {
    //print('main: Clearing all application data');

    await apiService.logout();
    await apiService.reset();
    await authService.clearPin();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    //print('main: All application data cleared');
  } catch (e) {
    //print('main: Error clearing application data: $e');
  }
}

// =============================================================================
// ЭКРАН ОШИБКИ
// =============================================================================

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                SizedBox(height: 20),
                Text(
                  'Ошибка запуска приложения',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Пожалуйста, перезапустите приложение',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  child: Text('Закрыть'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MARK: MYAPP
// =============================================================================

class MyApp extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;
  final bool isDomainChecked;
  final String? token;
  final String? pin;
  final Locale initialLocale;
  final RemoteMessage? initialMessage;
  final bool sessionValid;

  const MyApp({
    required this.apiService,
    required this.authService,
    required this.isDomainChecked,
    this.token,
    this.pin,
    required this.initialLocale,
    this.initialMessage,
    required this.sessionValid,
  });

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  RemoteMessage? _initialMessage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _initialMessage = widget.initialMessage;
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      //print('MyApp: Инициализация приложения');
      
      // Если initial message уже был передан из main, используем его
      if (_initialMessage != null) {
        //print('MyApp: Initial message уже получено из main');
      } else {
        // Пытаемся получить initial message если Firebase готов
        if (Firebase.apps.isNotEmpty) {
          try {
            Firebase.app(); // Проверка доступности
            
            // Небольшая задержка для готовности
            await Future.delayed(const Duration(milliseconds: 300));
            
            FirebaseApi firebaseApi = FirebaseApi();
            _initialMessage = firebaseApi.getInitialMessage();
            
            if (_initialMessage != null) {
              //print('MyApp: Initial message получено в MyApp');
            } else {
              //print('MyApp: Initial message отсутствует');
            }
          } catch (e) {
            //print('MyApp: Ошибка получения initial message: $e');
          }
        } else {
          //print('MyApp: Firebase не инициализирован, пропуск initial message');
        }
      }

      setState(() {
        _isInitialized = true;
      });
      
      //print('MyApp: Инициализация завершена успешно');
      
    } catch (e) {
      //print('MyApp: Ошибка инициализации: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
                // SizedBox(height: 20),
                // Text('Инициализация...'),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: widget.apiService),
        Provider<AuthService>.value(value: widget.authService),
        BlocProvider(create: (context) => DomainBloc(widget.apiService)),
        BlocProvider(create: (context) => LoginBloc(widget.apiService)),
        BlocProvider(create: (context) => LeadBloc(widget.apiService)),
        BlocProvider(create: (context) => HistoryBloc(widget.apiService)),
        BlocProvider(create: (context) => NotesBloc(widget.apiService)),
        BlocProvider(create: (context) => GetAllManagerBloc()),
        BlocProvider(create: (context) => GetAllRegionBloc()),
        BlocProvider(create: (context) => GetAllSourceBloc()),
        BlocProvider(create: (context) => GetAllLeadBloc()),
        BlocProvider(create: (context) => GetAllCashRegisterBloc()),
        BlocProvider(create: (context) => GetAllIncomeCategoryBloc()),
        BlocProvider(create: (context) => GetAllSupplierBloc()),
        BlocProvider(create: (context) => GetAllRegionBloc()),
        BlocProvider(create: (context) => GetAllLeadMultiBloc()),
        BlocProvider(create: (context) => DealBloc(widget.apiService)),
        BlocProvider(create: (context) => TaskBloc(widget.apiService)),
        BlocProvider(create: (context) => MyTaskBloc(widget.apiService)),
        BlocProvider(create: (context) => GetTaskProjectBloc()),
        BlocProvider(create: (context) => GetAllProjectBloc()),
        BlocProvider(create: (context) => UserTaskBloc(widget.apiService)),
        BlocProvider(create: (context) => HistoryBlocTask(widget.apiService)),
        BlocProvider(create: (context) => HistoryLeadsBloc(widget.apiService)),
        BlocProvider(create: (context) => HistoryBlocMyTask(widget.apiService)),
        BlocProvider(create: (context) => RoleBloc(widget.apiService)),
        BlocProvider(create: (context) => TaskStatusNameBloc(widget.apiService)),
        BlocProvider(create: (context) => MyTaskMyStatusNameBloc(widget.apiService)),
        BlocProvider(create: (context) => LeadByIdBloc(widget.apiService)),
        BlocProvider(create: (context) => DealByIdBloc(widget.apiService)),
        BlocProvider(create: (context) => TaskByIdBloc(widget.apiService)),
        BlocProvider(create: (context) => MyTaskByIdBloc(widget.apiService)),
        BlocProvider(create: (context) => DealHistoryBloc(widget.apiService)),
        BlocProvider(create: (context) => GetAllClientBloc(apiService: widget.apiService)),
        BlocProvider(create: (context) => GetAllAuthorBloc(apiService: widget.apiService)),
        BlocProvider(create: (context) => CreateClientBloc()),
        BlocProvider(create: (context) => GroupChatBloc(widget.apiService)),
        BlocProvider(create: (context) => DeleteMessageBloc(ApiService())),
        BlocProvider(create: (context) => ListenSenderTextCubit()),
        BlocProvider(create: (context) => ListenSenderVoiceCubit()),
        BlocProvider(create: (context) => ListenSenderFileCubit()),
        BlocProvider(create: (context) => ChatsBloc(ApiService()), ),
        BlocProvider(create: (context) => TaskStatusBloc(ApiService())),
        BlocProvider(create: (context) => MyTaskStatusBloc(ApiService())),
        BlocProvider(create: (context) => OrganizationBloc(ApiService())),
        BlocProvider(create: (context) => NotificationBloc(ApiService())),
        BlocProvider(create: (context) => ChatsBloc(ApiService()),),
        BlocProvider(create: (context) => TaskStatusBloc(ApiService())),
        BlocProvider(create: (context) => DashboardChartBloc(ApiService())),
        BlocProvider(create: (context) => DashboardChartBlocManager(ApiService())),
        BlocProvider(create: (context) => DashboardConversionBloc(ApiService())),
        BlocProvider(create: (context) => DashboardConversionBlocManager(ApiService())),
        BlocProvider(create: (context) => UserBlocManager(ApiService())),
        BlocProvider(create: (context) => DealStatsBloc(ApiService())),
        BlocProvider(create: (context) => DealStatsManagerBloc(ApiService())),
        BlocProvider(create: (context) => DashboardTaskChartBloc(ApiService())),
        BlocProvider(create: (context) => DashboardTaskChartBlocManager(ApiService())),
        BlocProvider(create: (context) => LeadDealsBloc(ApiService())),
        BlocProvider(create: (context) => DealTasksBloc(ApiService())),
        BlocProvider(create: (context) => ProcessSpeedBlocManager(ApiService())),
        BlocProvider(create: (context) => ContactPersonBloc(ApiService())),
        BlocProvider(create: (context) => LeadToChatBloc(widget.apiService)),
        BlocProvider(create: (context) => ChatProfileBloc(ApiService())),
        BlocProvider(create: (context) => TaskProfileBloc(ApiService())),
        BlocProvider(create: (context) => PermissionsBloc(ApiService())),
        BlocProvider(create: (context) => ForgotPinBloc(apiService: ApiService())),
        BlocProvider(create: (context) => SourceLeadBloc(widget.apiService)),
        BlocProvider(create: (context) => LeadToCBloc(apiService: widget.apiService)),
        BlocProvider(create: (context) => Data1CBloc(apiService: widget.apiService)),
        BlocProvider(create: (context) => ProfileBloc(apiService: widget.apiService)),
        BlocProvider(create: (context) => ProcessSpeedBloc(widget.apiService)),
        BlocProvider(create: (context) => TaskCompletionBloc(widget.apiService)),
        BlocProvider(create: (context) => TaskAddFromDealBloc(apiService: ApiService())),
        BlocProvider(create: (context) => EventBloc(widget.apiService)),
        BlocProvider(create: (context) => NoticeBloc(widget.apiService)),
        BlocProvider(create: (context) => GetAllSubjectBloc()),
        BlocProvider(create: (context) => GetAllDealNameBloc()),
        BlocProvider(create: (context) => CategoryBloc(widget.apiService)),
        BlocProvider(create: (context) => CategoryByIdBloc(widget.apiService)),
        BlocProvider(create: (context) => OrderBloc(widget.apiService)),
        BlocProvider(create: (context) => GoodsBloc(widget.apiService)),
        BlocProvider(create: (context) => GoodsByIdBloc(widget.apiService)),
        BlocProvider(create: (context) => BranchBloc(widget.apiService)),
        BlocProvider(create: (context) => DeliveryAddressBloc(widget.apiService)),
        BlocProvider(create: (context) => LeadOrderBloc(widget.apiService)),
        BlocProvider(create: (context) => CalendarBloc(widget.apiService)),
        BlocProvider(create: (context) => OrderHistoryBloc(widget.apiService)),
        BlocProvider(create: (context) => GetDirectoryBloc()),
        BlocProvider(create: (context) => OrderByLeadBloc(widget.apiService)),
        BlocProvider(create: (context) => PriceTypeBloc(widget.apiService)),
        BlocProvider(create: (context) => LabelBloc(widget.apiService)),
        BlocProvider(create: (context) => VariantBloc(widget.apiService)),
        BlocProvider(create: (context) => VariantBottomSheetBloc(widget.apiService)),
        BlocProvider(create: (context) => CallCenterBloc(ApiService()), ),
        BlocProvider(create: (context) => SalesFunnelBloc(ApiService())),
        BlocProvider(create: (context) => OperatorBloc(ApiService())),
        BlocProvider(create: (context) => TemplateBloc(ApiService())),
        BlocProvider(create: (context) => LeadStatusForFilterBloc(widget.apiService)),
        BlocProvider(create: (context) => IncomingBloc(widget.apiService)),
        BlocProvider<StorageBloc>(create: (context) => StorageBloc(widget.apiService),),
        BlocProvider<UnitsBloc>(create: (context) => UnitsBloc(widget.apiService), ),
        BlocProvider<ExpenseArticleBloc>( create: (context) => ExpenseArticleBloc(widget.apiService),),
        BlocProvider<SupplierBloc>( create: (context) => SupplierBloc(widget.apiService), ),
        BlocProvider<ClientSaleBloc>(  create: (context) => ClientSaleBloc(widget.apiService), ),
        BlocProvider<ClientSaleDocumentHistoryBloc>(  create: (context) => ClientSaleDocumentHistoryBloc(widget.apiService),),
        BlocProvider<IncomingDocumentHistoryBloc>(  create: (context) => IncomingDocumentHistoryBloc(context.read<ApiService>()),),
        // TODO fix bloc providers warehouse folder
        BlocProvider(create: (context) => ClientReturnBloc(widget.apiService)),
        BlocProvider(create: (context) => SupplierBloc(widget.apiService)),
        BlocProvider(create: (context) => MeasureUnitsBloc(widget.apiService)),
        BlocProvider(create: (context) => WareHouseBloc(widget.apiService)),
        BlocProvider(create: (context) => PriceTypeScreenBloc(widget.apiService)),
        BlocProvider(create: (context) => SupplierReturnBloc(widget.apiService)),
        BlocProvider(create: (context) => WriteOffBloc(widget.apiService)),
        BlocProvider(create: (context) => MovementBloc(widget.apiService)),
        BlocProvider(create: (context) => CashDeskBloc()),
        BlocProvider(create: (context) => ExpenseBloc()),
        BlocProvider(create: (context) => IncomeBloc()),
        BlocProvider(create: (context) => CategoryDashboardWarehouseBloc(widget.apiService)),
        BlocProvider(create: (context) => GoodDashboardWarehouseBloc(widget.apiService)),
        BlocProvider(create: (context) => SalesDashboardBloc()),
        BlocProvider(create: (context) => SalesDashboardGoodsBloc()),
        BlocProvider(create: (context) => SalesDashboardCashBalanceBloc()),
        BlocProvider(create: (context) => SalesDashboardCreditorsBloc()),
        BlocProvider(create: (context) => SalesDashboardDebtorsBloc()),
        BlocProvider(create: (context) => FieldConfigurationBloc(widget.apiService)),
     ],
      child: MaterialApp(
        locale: _locale ?? const Locale('ru'),
        color: Colors.white,
        debugShowCheckedModeBanner: false,
        title: 'shamCRM',
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
        ),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('ru', ''),
          const Locale('en', ''),
          const Locale('uz', ''),
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        home: Builder(
          builder: (context) {
            if (!widget.sessionValid) {
              return AuthScreen();
            }

            if (widget.token == null) {
              return AuthScreen();
            } else if (widget.pin == null) {
              return PinSetupScreen();
            } else {
              return PinScreen(
                initialMessage: _initialMessage,
              );
            }
          },
        ),
        routes: {
          '/local_auth': (context) => AuthScreen(),
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/chats': (context) => ChatsScreen(),
          '/pin_setup': (context) => PinSetupScreen(),
          '/pin_screen': (context) => PinScreen(),
          '/profile': (context) => ProfileScreen(),
        },
      ),
    );
  }
}