import 'dart:async';
import 'package:crm_task_manager/utils/user_friendly_error.dart';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase_api.dart';
import 'package:crm_task_manager/api/service/secure_storage_service.dart';
import 'package:crm_task_manager/api/service/widget_service.dart';
import 'package:crm_task_manager/core/theme/app_theme.dart';
import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/bloc/My-Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_bloc.dart';
import 'package:crm_task_manager/bloc/auth_domain/domain_bloc.dart';
import 'package:crm_task_manager/bloc/advertising_campaign_list/advertising_campaign_bloc.dart';
import 'package:crm_task_manager/bloc/author/get_all_author_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/operator_bloc/operator_bloc.dart';
import 'package:crm_task_manager/bloc/cash_desk/cash_desk_bloc.dart';
import 'package:crm_task_manager/bloc/city_list/city_bloc.dart';
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
import 'package:crm_task_manager/bloc/lead_channel_list/lead_channel_bloc.dart';
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
import 'package:crm_task_manager/bloc/page_2_BLOC/document/manufacture/manufacture_bloc.dart';
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
import 'package:crm_task_manager/bloc/task_overdue_history/task_overdue_history_bloc.dart';
import 'package:crm_task_manager/bloc/task_status_add/task_bloc.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/bloc/user/create_cleant/create_client_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/firebase_options.dart';
import 'package:crm_task_manager/offline/core/core_outbox_executors.dart';
import 'package:crm_task_manager/offline/core/offline_bootstrap.dart';
import 'package:crm_task_manager/screens/auth/pin_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/auth/pin_setup_screen.dart';
import 'package:crm_task_manager/screens/auth/auth_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/languages/local_manager_lang.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/screens/sip/sip_call_overlay_host.dart';
import 'package:crm_task_manager/services/app_logout_service.dart';
import 'package:crm_task_manager/update_dialog.dart';
import 'package:crm_task_manager/widgets/native_internet_aware_wrapper_WITH_GAME.dart';
import 'package:crm_task_manager/widgets/native_internet_monitor_simple.dart';
import 'package:crm_task_manager/widgets/http_inspector_fab.dart';
import 'package:crm_task_manager/widgets/in_app_update_corner_indicator.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:new_version_plus/new_version_plus.dart';
import 'package:provider/provider.dart';
import 'bloc/cash_register_list/cash_register_list_bloc.dart';
import 'bloc/page_2_BLOC/document/incoming/incoming_document_history/incoming_document_history_bloc.dart';
import 'bloc/supplier_list/supplier_list_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = ApiService.navigatorKey;
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    ApiService.scaffoldMessengerKey;

const String _telegramCrashBotToken = String.fromEnvironment(
  'TELEGRAM_CRASH_BOT_TOKEN',
  defaultValue: '8926264073:AAEF31-5Bvhnr2Xdz6GIpG5u_KyFbWpA5KM',
);
const String _telegramCrashChatId = String.fromEnvironment(
  'TELEGRAM_CRASH_CHAT_ID',
  defaultValue: '6833674360',
);
const String _telegramCriticalThreadIdValue = String.fromEnvironment(
  'TELEGRAM_CRITICAL_THREAD_ID',
  defaultValue: '',
);
const String _telegramNormalThreadIdValue = String.fromEnvironment(
  'TELEGRAM_NORMAL_THREAD_ID',
  defaultValue: '',
);
const Duration _telegramCrashDuplicateWindow = Duration(seconds: 2);
const Duration _telegramRepeatEscalationWindow = Duration(minutes: 10);
const int _telegramRepeatEscalationThreshold = 3;

final Map<String, DateTime> _recentCrashReports = <String, DateTime>{};
final Map<String, _IssueRepeatStats> _recentIssueStats =
    <String, _IssueRepeatStats>{};

class _CrashSeverity {
  final String emoji;
  final String title;
  final int priority;

  const _CrashSeverity({
    required this.emoji,
    required this.title,
    required this.priority,
  });
}

class _IssueContext {
  final String severityKey;
  final String emoji;
  final String title;
  final int priority;
  final String screen;
  final String screenLabel;
  final String category;
  final String categoryLabel;
  final bool fatal;
  final int repeatCount;
  final int? threadId;

  const _IssueContext({
    required this.severityKey,
    required this.emoji,
    required this.title,
    required this.priority,
    required this.screen,
    required this.screenLabel,
    required this.category,
    required this.categoryLabel,
    required this.fatal,
    required this.repeatCount,
    required this.threadId,
  });
}

class _IssueRepeatStats {
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int count;

  const _IssueRepeatStats({
    required this.firstSeen,
    required this.lastSeen,
    required this.count,
  });

  _IssueRepeatStats next(DateTime now) {
    return _IssueRepeatStats(
      firstSeen: firstSeen,
      lastSeen: now,
      count: count + 1,
    );
  }

  bool isWithinWindow(DateTime now) {
    return now.difference(lastSeen) <= _telegramRepeatEscalationWindow;
  }
}

void main() {
  runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      final apiService = ApiService();
      final authService = AuthService();

      await _requestTrackingAuthorizationIfNeeded();
      await _safeInitializeOfflineRuntime();
      await _safeInitializeFirebase();

      final sessionValidation = await _validateApplicationSession(apiService);

      String? token;
      String? pin;
      bool isDomainChecked = false;

      if (sessionValidation.isValid) {
        token = await apiService.getToken();
        pin = await authService.getPin();
        isDomainChecked = await apiService.isDomainChecked();

        if (isDomainChecked) {
          await _safeInitializeApiService(apiService);
          _safeRegisterOutboxExecutors(apiService);
        }
      } else {
        await _clearAllApplicationData(apiService, authService);
      }

      final initialMessage = await _safeLoadInitialMessage();
      await AppThemeController.instance.initialize();
      _safeConfigureSystemUi();
      final savedLocale = await _safeLoadLocale();
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
      await _recordFatalError(e, stackTrace, reason: 'startup');
      debugPrint('main: startup error: $e');
      debugPrint('main: startup stackTrace: $stackTrace');
      runApp(ErrorApp(error: e.toString()));
    }
  }, (error, stackTrace) async {
    await _recordFatalError(error, stackTrace, reason: 'zone');
  });
}

Future<void> _requestTrackingAuthorizationIfNeeded() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }

  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  } catch (e, stackTrace) {
    debugPrint('main: tracking authorization error: $e');
    debugPrint('main: tracking authorization stackTrace: $stackTrace');
    await _recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.tracking_authorization',
      screenHint: 'ios',
    );
  }
}

Future<void> _safeInitializeOfflineRuntime() async {
  try {
    await OfflineBootstrap.initialize().timeout(const Duration(seconds: 8));
  } catch (e, stackTrace) {
    debugPrint('main: OfflineBootstrap initialize error: $e');
    debugPrint('main: OfflineBootstrap stackTrace: $stackTrace');
    await _recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.offline_runtime',
      screenHint: 'startup',
    );
  }
}

Future<void> _safeInitializeFirebase() async {
  try {
    await _initializeFirebase().timeout(const Duration(seconds: 8));
    await _initializeCrashlytics();
    FirebaseApi.ensureBackgroundHandlerRegistered();
  } catch (e, stackTrace) {
    debugPrint('main: Firebase initialize error: $e');
    debugPrint('main: Firebase initialize stackTrace: $stackTrace');
    await _recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.firebase',
      screenHint: 'startup',
    );
  }
}

Future<void> _safeInitializeApiService(ApiService apiService) async {
  try {
    await apiService.initialize().timeout(const Duration(seconds: 6));
  } catch (e, stackTrace) {
    debugPrint('main: ApiService initialize error: $e');
    debugPrint('main: ApiService initialize stackTrace: $stackTrace');
    await _recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.api_service',
      screenHint: 'startup',
    );
  }
}

Future<void> _safeRegisterOutboxExecutors(ApiService apiService) async {
  try {
    CoreOutboxExecutors.register(apiService);
  } catch (e, stackTrace) {
    debugPrint('main: CoreOutboxExecutors register error: $e');
    debugPrint('main: CoreOutboxExecutors register stackTrace: $stackTrace');
    await _recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.outbox_executors',
      screenHint: 'startup',
    );
  }
}

Future<RemoteMessage?> _safeLoadInitialMessage() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      return await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(const Duration(seconds: 3));
    }
  } catch (e, stackTrace) {
    debugPrint('main: initial message error: $e');
    debugPrint('main: initial message stackTrace: $stackTrace');
    await _recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.initial_message',
      screenHint: 'startup',
    );
  }

  return null;
}

Future<void> _safeConfigureSystemUi() async {
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('main: System UI configuration error: $e');
    debugPrint('main: System UI configuration stackTrace: $stackTrace');
    await _recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.system_ui',
      screenHint: 'startup',
    );
  }
}

Future<Locale> _safeLoadLocale() async {
  try {
    final String? savedLanguageCode =
        await LanguageManager.getLanguage().timeout(const Duration(seconds: 2));
    if (savedLanguageCode != null && savedLanguageCode.isNotEmpty) {
      return Locale(savedLanguageCode);
    }
  } catch (e, stackTrace) {
    debugPrint('main: locale load error: $e');
    debugPrint('main: locale load stackTrace: $stackTrace');
    await _recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.locale',
      screenHint: 'startup',
    );
  }

  return const Locale('ru');
}

Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      try {
        Firebase.app();
      } catch (e) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    try {
      Firebase.app();
    } catch (e) {
      //print('Firebase: Предупреждение: $e');
    }
  } catch (e) {
    final errorString = e.toString();

    if (errorString.contains('already exists') ||
        errorString.contains('duplicate app')) {
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        Firebase.app();
      } catch (checkError) {
        //print('Firebase: app НЕ доступен: $checkError');
      }
    }
  }
}

Future<void> _initializeCrashlytics() async {
  if (Firebase.apps.isEmpty) return;

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    unawaited(
      _reportIssue(
        source: 'flutter_error',
        error: errorDetails.exception,
        stackTrace: errorDetails.stack,
        fatal: true,
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    unawaited(
      _reportIssue(
        source: 'platform_dispatcher',
        error: error,
        stackTrace: stack,
        fatal: true,
      ),
    );
    return true;
  };

  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
}

Future<void> _reportIssue({
  required String source,
  required Object error,
  required StackTrace? stackTrace,
  required bool fatal,
  String? screenHint,
  String? categoryHint,
}) async {
  if (_telegramCrashBotToken.isEmpty || _telegramCrashChatId.isEmpty) {
    return;
  }

  final severity = _classifyIssueSeverity(
    source: source,
    error: error,
    stackTrace: stackTrace,
    fatal: fatal,
  );
  final screen = screenHint ??
      _detectIssueScreen(
        source: source,
        error: error,
        stackTrace: stackTrace,
      );
  final category = categoryHint ??
      _detectIssueCategory(
        source: source,
        error: error,
        stackTrace: stackTrace,
        fatal: fatal,
      );
  final issueContext = _buildIssueContext(
    severity: severity,
    screen: screen,
    category: category,
    fatal: fatal,
  );
  final fingerprint = '$source|$error|${stackTrace?.toString() ?? ''}';
  final now = DateTime.now();
  _recentCrashReports.removeWhere(
    (_, time) => now.difference(time) > const Duration(minutes: 1),
  );

  _recentIssueStats.removeWhere(
    (_, stats) =>
        now.difference(stats.lastSeen) > _telegramRepeatEscalationWindow,
  );

  final lastReportedAt = _recentCrashReports[fingerprint];
  if (lastReportedAt != null &&
      now.difference(lastReportedAt) < _telegramCrashDuplicateWindow) {
    return;
  }
  _recentCrashReports[fingerprint] = now;

  final repeatStats = _registerIssueOccurrence(fingerprint, now);
  final escalatedByRepeat = _shouldEscalateByRepeat(
    fatal: fatal,
    stats: repeatStats,
  );
  final formattedIssue = escalatedByRepeat
      ? _promoteRepeatIssue(issueContext, repeatStats.count)
      : issueContext;

  final stackText = stackTrace?.toString().trim();
  final message = _buildTelegramHtmlMessage(
    issue: formattedIssue,
    source: source,
    error: error,
    stackText: stackText,
    now: now,
    repeatCount: repeatStats.count,
    escalatedByRepeat: escalatedByRepeat,
  );

  try {
    final body = <String, String>{
      'chat_id': _telegramCrashChatId,
      'text': message,
      'disable_web_page_preview': 'true',
      'parse_mode': 'HTML',
    };

    if (formattedIssue.threadId != null) {
      body['message_thread_id'] = formattedIssue.threadId.toString();
    }

    await http
        .post(
          Uri.parse(
            'https://api.telegram.org/bot$_telegramCrashBotToken/sendMessage',
          ),
          body: body,
        )
        .timeout(const Duration(seconds: 5));
  } catch (e, stackTrace) {
    debugPrint('main: Telegram crash notify error: $e');
    debugPrint('main: Telegram crash notify stackTrace: $stackTrace');
  }
}

_IssueRepeatStats _registerIssueOccurrence(String fingerprint, DateTime now) {
  final current = _recentIssueStats[fingerprint];
  if (current == null || !current.isWithinWindow(now)) {
    final fresh = _IssueRepeatStats(
      firstSeen: now,
      lastSeen: now,
      count: 1,
    );
    _recentIssueStats[fingerprint] = fresh;
    return fresh;
  }

  final updated = current.next(now);
  _recentIssueStats[fingerprint] = updated;
  return updated;
}

bool _shouldEscalateByRepeat({
  required bool fatal,
  required _IssueRepeatStats stats,
}) {
  return !fatal &&
      stats.count >= _telegramRepeatEscalationThreshold &&
      stats.isWithinWindow(DateTime.now());
}

_IssueContext _promoteRepeatIssue(_IssueContext issue, int repeatCount) {
  return _IssueContext(
    severityKey: 'critical',
    emoji: '🔥',
    title: 'Repeated issue',
    priority: 1,
    screen: issue.screen,
    screenLabel: issue.screenLabel,
    category: issue.category,
    categoryLabel: issue.categoryLabel,
    fatal: issue.fatal,
    repeatCount: repeatCount,
    threadId: int.tryParse(_telegramCriticalThreadIdValue),
  );
}

String _buildTelegramHtmlMessage({
  required _IssueContext issue,
  required String source,
  required Object error,
  required String? stackText,
  required DateTime now,
  required int repeatCount,
  required bool escalatedByRepeat,
}) {
  final badge = _severityBadgeFor(issue.severityKey);
  final buffer = StringBuffer()
    ..writeln(
      '${badge.emoji} <b>${_escapeTelegramHtml(badge.label)}</b> <i>${_escapeTelegramHtml(issue.title)}</i>',
    )
    ..writeln(
      '<b>${_escapeTelegramHtml(issue.screenLabel)}</b> · <code>${_escapeTelegramHtml(issue.categoryLabel)}</code> · <b>${_escapeTelegramHtml(issue.severityKey.toUpperCase())}</b>',
    )
    ..writeln(
      '<b>Source:</b> <code>${_escapeTelegramHtml(source)}</code>',
    )
    ..writeln(
      '<b>Time:</b> <code>${_escapeTelegramHtml(now.toIso8601String())}</code>',
    )
    ..writeln(
      '<b>Error:</b> <code>${_escapeTelegramHtml(error.toString())}</code>',
    );

  if (repeatCount > 1) {
    buffer.writeln(
      '<b>Repeat:</b> <code>${repeatCount}x</code> in <code>10m</code>',
    );
  }

  if (escalatedByRepeat) {
    buffer.writeln('<b>Escalated:</b> repeated non-fatal issue');
  }

  if (stackText != null && stackText.trim().isNotEmpty) {
    buffer
      ..writeln('<b>Stack:</b>')
      ..writeln(
        '<pre>${_escapeTelegramHtml(_shortStackPreview(stackText))}</pre>',
      );
  }

  return _truncateTelegramMessage(buffer.toString());
}

_SeverityBadge _severityBadgeFor(String severityKey) {
  switch (severityKey) {
    case 'critical':
      return const _SeverityBadge(emoji: '🔥', label: 'CRITICAL');
    case 'high':
      return const _SeverityBadge(emoji: '⚡', label: 'HIGH');
    case 'normal':
      return const _SeverityBadge(emoji: '🟡', label: 'NORMAL');
    default:
      return const _SeverityBadge(emoji: 'ℹ️', label: 'INFO');
  }
}

class _SeverityBadge {
  final String emoji;
  final String label;

  const _SeverityBadge({
    required this.emoji,
    required this.label,
  });
}

String _escapeTelegramHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

_IssueContext _buildIssueContext({
  required _CrashSeverity severity,
  required String screen,
  required String category,
  required bool fatal,
}) {
  final threadId = fatal
      ? int.tryParse(_telegramCriticalThreadIdValue)
      : int.tryParse(_telegramNormalThreadIdValue);

  return _IssueContext(
    severityKey: severity.priority == 1
        ? 'critical'
        : severity.priority == 2
            ? 'high'
            : 'normal',
    emoji: severity.emoji,
    title: severity.title,
    priority: severity.priority,
    screen: screen,
    screenLabel: _screenLabelFor(screen),
    category: category,
    categoryLabel: _categoryLabelFor(category),
    fatal: fatal,
    repeatCount: 1,
    threadId: threadId,
  );
}

_CrashSeverity _classifyIssueSeverity({
  required String source,
  required Object error,
  required StackTrace? stackTrace,
  required bool fatal,
}) {
  final errorText =
      '${error.toString()}\n${stackTrace?.toString() ?? ''}'.toLowerCase();

  if (fatal) {
    return const _CrashSeverity(
      emoji: '🔥',
      title: 'Critical crash',
      priority: 1,
    );
  }

  final criticalPatterns = <String>[
    'missingpluginexception',
    'lateinitializationerror',
    'null check operator used on a null value',
    'setstate() called after dispose()',
    'typeerror',
    'rangeerror',
    'renderflex overflowed',
    'bad state: no element',
    'no such method',
  ];

  if (criticalPatterns.any(errorText.contains)) {
    return const _CrashSeverity(
      emoji: '🔥',
      title: 'Critical issue',
      priority: 1,
    );
  }

  final highPatterns = <String>[
    'exception',
    'fluttererror',
    'assertionerror',
    'socketexception',
    'timeoutexception',
  ];

  if (highPatterns.any(errorText.contains) || source == 'flutter_error') {
    return const _CrashSeverity(
      emoji: '⚡',
      title: 'High priority issue',
      priority: 2,
    );
  }

  return const _CrashSeverity(
    emoji: '🟡',
    title: 'Normal issue',
    priority: 3,
  );
}

String _detectIssueScreen({
  required String source,
  required Object error,
  required StackTrace? stackTrace,
}) {
  final haystack =
      '${source.toLowerCase()}\n${error.toString().toLowerCase()}\n${stackTrace?.toString().toLowerCase() ?? ''}';

  final mappings = <String, String>{
    'lib/screens/auth/': 'auth',
    'lib/screens/home_screen.dart': 'home',
    'lib/screens/chats/': 'chat',
    'lib/screens/task/': 'task',
    'lib/screens/lead/': 'lead',
    'lib/screens/deal/': 'deal',
    'lib/screens/dashboard/': 'dashboard',
    'lib/screens/profile/': 'profile',
    'lib/page_2/': 'page_2',
    'lib/api/service/firebase_api.dart': 'firebase',
    'missingpluginexception': 'native',
    'platform_dispatcher': 'system',
    'flutter_error': 'flutter',
  };

  for (final entry in mappings.entries) {
    if (haystack.contains(entry.key)) {
      return entry.value;
    }
  }

  return 'unknown';
}

String _detectIssueCategory({
  required String source,
  required Object error,
  required StackTrace? stackTrace,
  required bool fatal,
}) {
  final text =
      '${source.toLowerCase()}\n${error.toString().toLowerCase()}\n${stackTrace?.toString().toLowerCase() ?? ''}';

  if (fatal) {
    return 'crash';
  }

  if (text.contains('timeout')) {
    return 'timeout';
  }
  if (text.contains('socket') || text.contains('network')) {
    return 'network';
  }
  if (text.contains('permission')) {
    return 'permission';
  }
  if (text.contains('missingpluginexception')) {
    return 'native_bridge';
  }
  if (text.contains('lateinitializationerror')) {
    return 'initialization';
  }
  if (text.contains('assertionerror')) {
    return 'assertion';
  }
  if (text.contains('rangeerror')) {
    return 'data_bounds';
  }

  return 'general';
}

String _screenLabelFor(String screen) {
  switch (screen) {
    case 'auth':
      return 'Auth';
    case 'home':
      return 'Home';
    case 'chat':
      return 'Chat';
    case 'task':
      return 'Task';
    case 'lead':
      return 'Lead';
    case 'deal':
      return 'Deal';
    case 'dashboard':
      return 'Dashboard';
    case 'profile':
      return 'Profile';
    case 'page_2':
      return 'Page 2';
    case 'firebase':
      return 'Firebase';
    case 'native':
      return 'Native';
    case 'ios':
      return 'iOS';
    case 'system':
      return 'System';
    case 'flutter':
      return 'Flutter';
    case 'startup':
      return 'Startup';
    default:
      return 'General';
  }
}

String _categoryLabelFor(String category) {
  switch (category) {
    case 'crash':
      return 'Crash';
    case 'fatal_crash':
      return 'Fatal crash';
    case 'non_fatal':
      return 'Non-fatal';
    case 'network':
      return 'Network';
    case 'timeout':
      return 'Timeout';
    case 'permission':
      return 'Permission';
    case 'native_bridge':
      return 'Native bridge';
    case 'initialization':
      return 'Init';
    case 'assertion':
      return 'Assertion';
    case 'data_bounds':
      return 'Bounds';
    case 'general':
      return 'General';
    default:
      return category;
  }
}

String _shortStackPreview(String stackText) {
  final lines = stackText
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .take(6)
      .toList();

  if (lines.isEmpty) {
    return stackText;
  }

  return lines.join('\n');
}

String _truncateTelegramMessage(String message) {
  const maxLength = 3900;
  if (message.length <= maxLength) {
    return message;
  }
  return '${message.substring(0, maxLength)}\n\n... truncated';
}

Future<void> _recordNonFatalError(
  Object error,
  StackTrace stackTrace, {
  required String reason,
  String? screenHint,
}) async {
  try {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseCrashlytics.instance.setCustomKey('error_source', reason);
      await FirebaseCrashlytics.instance.setCustomKey(
        'issue_severity',
        'normal',
      );
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: false,
      );
    }
    await _reportIssue(
      source: reason,
      error: error,
      stackTrace: stackTrace,
      fatal: false,
      screenHint: screenHint,
      categoryHint: 'non_fatal',
    );
  } catch (_) {}
}

Future<void> _recordFatalError(
  Object error,
  StackTrace stackTrace, {
  required String reason,
}) async {
  try {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseCrashlytics.instance.setCustomKey('error_source', reason);
      await FirebaseCrashlytics.instance.setCustomKey(
        'issue_severity',
        'critical',
      );
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: true,
      );
    }
    await _reportIssue(
      source: reason,
      error: error,
      stackTrace: stackTrace,
      fatal: true,
      categoryHint: 'fatal_crash',
    );
  } catch (_) {}
}

// // ✅ НОВЫЙ МЕТОД: Обработка initial message
// Future<void> _handleInitialMessage(RemoteMessage message) async {
//   debugPrint('_handleInitialMessage: ${message.data}');

//   // Ждем инициализации приложения
//   await Future.delayed(Duration(seconds: 2));

//   try {
//     await FirebaseApi().handleMessage(message);
//   } catch (e) {
//     debugPrint('_handleInitialMessage: Error: $e');
//   }
// }

// Future<void> getFCMTokens(ApiService apiService) async {
//   try {
//     if (Firebase.apps.isEmpty) return;

//     try {
//       Firebase.app();
//     } catch (e) {
//       return;
//     }

//     final String? fcmToken = await FirebaseMessaging.instance.getToken();

//     if (fcmToken != null && fcmToken.isNotEmpty) {
//       try {
//         await apiService.sendDeviceToken(fcmToken);
//       } catch (e) {
//         //print('FCM Token: Ошибка отправки: $e');
//       }
//     }

//   } catch (e) {
//     //print('FCM Token: Ошибка: $e');
//   }
// }

class SessionValidationResult {
  final bool isValid;
  final String? errorMessage;

  SessionValidationResult({required this.isValid, this.errorMessage});
}

Future<SessionValidationResult> _validateApplicationSession(
    ApiService apiService) async {
  try {
    final token = await apiService.getToken();
    if (token == null || token.isEmpty) {
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
          return SessionValidationResult(
              isValid: false, errorMessage: 'No domain');
        }
      }
    }

    final organizationId = await apiService.getSelectedOrganization();
    if (organizationId == null || organizationId.isEmpty) {
      //print('main: No organization selected');
    }

    return SessionValidationResult(isValid: true);
  } catch (e) {
    return SessionValidationResult(
        isValid: false, errorMessage: friendlyError(e));
  }
}

Future<void> _clearAllApplicationData(
    ApiService apiService, AuthService authService) async {
  await AppLogoutService.logoutAndReset(
    restartApp: false,
    navigateToAuth: false,
    notifyServer: false,
  );
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

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
                Icon(Icons.error_outline, size: 80, color: Colors.red),
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
    super.key,
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
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  bool _platformServicesInitialized = false;
  bool _deferredStartupInitialized = false;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlatformServices();
    });
  }

  Future<void> _initializePlatformServices() async {
    if (_platformServicesInitialized) {
      return;
    }
    _platformServicesInitialized = true;

    WidgetService.initialize();
    await NativeInternetMonitor().initialize();
    _initializeDeferredStartup();
  }

  Future<void> _initializeDeferredStartup() async {
    if (_deferredStartupInitialized) {
      return;
    }
    _deferredStartupInitialized = true;

    if (widget.isDomainChecked && widget.sessionValid) {
      unawaited(widget.apiService.ensureSelectedSalesFunnelInitialized());
    }
  }

//1
  Future<void> checkForNewVersion(BuildContext context) async {
    try {
      final newVersionPlus = NewVersionPlus();
      final status = await newVersionPlus.getVersionStatus();
      debugPrint(
          "APP_VERSION: Current: ${status?.localVersion}, Store: ${status?.storeVersion}, CanUpdate: ${status?.canUpdate}");

      if (!mounted ||
          !context.mounted ||
          status == null ||
          status.canUpdate == false) {
        return;
      }

      final localizations = AppLocalizations.of(context);

      await UpdateDialog.show(
        context: context,
        status: status,
        title: localizations?.translate('app_update_available_title') ??
            'Обновление',
        message: localizations?.translate('app_update_available_message') ??
            'Доступна новая версия приложения',
        updateButton:
            localizations?.translate('app_update_button') ?? 'Обновить',
        laterButton:
            localizations?.translate('later') ?? 'Позже', // ← Добавь перевод
        onLaterPressed: () {
          // Опционально: можно сохранить, что пользователь отложил обновление
          // Например: SharedPreferences.setBool('update_later_shown', true);
          debugPrint('Пользователь отложил обновление');
        },
      );
    } catch (e) {
      // print('MyApp: Error checking version: $e');
    }
  }

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppThemeController>.value(
          value: AppThemeController.instance,
        ),
        Provider<ApiService>.value(value: widget.apiService),
        Provider<AuthService>.value(value: widget.authService),
        BlocProvider(create: (context) => DomainBloc(widget.apiService)),
        BlocProvider(create: (context) => LoginBloc(widget.apiService)),
        BlocProvider(create: (context) => LeadBloc(widget.apiService)),
        BlocProvider(create: (context) => HistoryBloc(widget.apiService)),
        BlocProvider(create: (context) => NotesBloc(widget.apiService)),
        BlocProvider(create: (context) => GetAllManagerBloc()),
        BlocProvider(create: (context) => GetAllRegionBloc()),
        BlocProvider(create: (context) => GetAllCityBloc()),
        BlocProvider(create: (context) => GetAllSourceBloc()),
        BlocProvider(create: (context) => GetAllLeadChannelBloc()),
        BlocProvider(create: (context) => GetAllAdvertisingCampaignBloc()),
        BlocProvider(
            create: (context) => GetAllLeadBloc(apiService: widget.apiService)),
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
        BlocProvider(
            create: (context) => TaskOverdueHistoryBloc(widget.apiService)),
        BlocProvider(create: (context) => HistoryLeadsBloc(widget.apiService)),
        BlocProvider(create: (context) => HistoryBlocMyTask(widget.apiService)),
        BlocProvider(create: (context) => RoleBloc(widget.apiService)),
        BlocProvider(
            create: (context) => TaskStatusNameBloc(widget.apiService)),
        BlocProvider(
            create: (context) => MyTaskMyStatusNameBloc(widget.apiService)),
        BlocProvider(create: (context) => LeadByIdBloc(widget.apiService)),
        BlocProvider(create: (context) => DealByIdBloc(widget.apiService)),
        BlocProvider(create: (context) => TaskByIdBloc(widget.apiService)),
        BlocProvider(create: (context) => MyTaskByIdBloc(widget.apiService)),
        BlocProvider(create: (context) => DealHistoryBloc(widget.apiService)),
        BlocProvider(
            create: (context) =>
                GetAllClientBloc(apiService: widget.apiService)),
        BlocProvider(
            create: (context) =>
                GetAllAuthorBloc(apiService: widget.apiService)),
        BlocProvider(create: (context) => CreateClientBloc()),
        BlocProvider(create: (context) => GroupChatBloc(widget.apiService)),
        BlocProvider(create: (context) => DeleteMessageBloc(ApiService())),
        BlocProvider(create: (context) => ListenSenderTextCubit()),
        BlocProvider(create: (context) => ListenSenderVoiceCubit()),
        BlocProvider(create: (context) => ListenSenderFileCubit()),
        BlocProvider(
          create: (context) => ChatsBloc(widget.apiService),
        ),
        BlocProvider(create: (context) => TaskStatusBloc(ApiService())),
        BlocProvider(create: (context) => MyTaskStatusBloc(ApiService())),
        BlocProvider(create: (context) => OrganizationBloc(ApiService())),
        BlocProvider(create: (context) => NotificationBloc(ApiService())),
        BlocProvider(
          create: (context) => ChatsBloc(widget.apiService),
        ),
        BlocProvider(create: (context) => TaskStatusBloc(ApiService())),
        BlocProvider(create: (context) => DashboardChartBloc(ApiService())),
        BlocProvider(
            create: (context) => DashboardChartBlocManager(ApiService())),
        BlocProvider(
            create: (context) => DashboardConversionBloc(ApiService())),
        BlocProvider(
            create: (context) => DashboardConversionBlocManager(ApiService())),
        BlocProvider(create: (context) => UserBlocManager(ApiService())),
        BlocProvider(create: (context) => DealStatsBloc(ApiService())),
        BlocProvider(create: (context) => DealStatsManagerBloc(ApiService())),
        BlocProvider(create: (context) => DashboardTaskChartBloc(ApiService())),
        BlocProvider(
            create: (context) => DashboardTaskChartBlocManager(ApiService())),
        BlocProvider(create: (context) => LeadDealsBloc(ApiService())),
        BlocProvider(create: (context) => DealTasksBloc(ApiService())),
        BlocProvider(
            create: (context) => ProcessSpeedBlocManager(ApiService())),
        BlocProvider(create: (context) => ContactPersonBloc(ApiService())),
        BlocProvider(create: (context) => LeadToChatBloc(widget.apiService)),
        BlocProvider(create: (context) => ChatProfileBloc(ApiService())),
        BlocProvider(create: (context) => TaskProfileBloc(ApiService())),
        BlocProvider(create: (context) => PermissionsBloc(ApiService())),
        BlocProvider(
            create: (context) => ForgotPinBloc(apiService: ApiService())),
        BlocProvider(create: (context) => SourceLeadBloc(widget.apiService)),
        BlocProvider(
            create: (context) => LeadToCBloc(apiService: widget.apiService)),
        BlocProvider(
            create: (context) => Data1CBloc(apiService: widget.apiService)),
        BlocProvider(
            create: (context) => ProfileBloc(apiService: widget.apiService)),
        BlocProvider(create: (context) => ProcessSpeedBloc(widget.apiService)),
        BlocProvider(
            create: (context) => TaskCompletionBloc(widget.apiService)),
        BlocProvider(
            create: (context) => TaskAddFromDealBloc(apiService: ApiService())),
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
        BlocProvider(
            create: (context) => DeliveryAddressBloc(widget.apiService)),
        BlocProvider(create: (context) => LeadOrderBloc(widget.apiService)),
        BlocProvider(create: (context) => CalendarBloc(widget.apiService)),
        BlocProvider(create: (context) => OrderHistoryBloc(widget.apiService)),
        BlocProvider(create: (context) => GetDirectoryBloc()),
        BlocProvider(create: (context) => OrderByLeadBloc(widget.apiService)),
        BlocProvider(create: (context) => PriceTypeBloc(widget.apiService)),
        BlocProvider(create: (context) => LabelBloc(widget.apiService)),
        BlocProvider(create: (context) => VariantBloc(widget.apiService)),
        BlocProvider(
            create: (context) => VariantBottomSheetBloc(widget.apiService)),
        BlocProvider(
          create: (context) => CallCenterBloc(ApiService()),
        ),
        BlocProvider(create: (context) => SalesFunnelBloc(ApiService())),
        BlocProvider(create: (context) => OperatorBloc(ApiService())),
        BlocProvider(create: (context) => TemplateBloc(ApiService())),
        BlocProvider(
            create: (context) => LeadStatusForFilterBloc(widget.apiService)),
        BlocProvider(create: (context) => IncomingBloc(widget.apiService)),
        BlocProvider<StorageBloc>(
          create: (context) => StorageBloc(widget.apiService),
        ),
        BlocProvider<UnitsBloc>(
          create: (context) => UnitsBloc(widget.apiService),
        ),
        BlocProvider<ExpenseArticleBloc>(
          create: (context) => ExpenseArticleBloc(widget.apiService),
        ),
        BlocProvider<SupplierBloc>(
          create: (context) => SupplierBloc(widget.apiService),
        ),
        BlocProvider<ClientSaleBloc>(
          create: (context) => ClientSaleBloc(widget.apiService),
        ),
        BlocProvider<ClientSaleDocumentHistoryBloc>(
          create: (context) => ClientSaleDocumentHistoryBloc(widget.apiService),
        ),
        BlocProvider<IncomingDocumentHistoryBloc>(
          create: (context) =>
              IncomingDocumentHistoryBloc(context.read<ApiService>()),
        ),
        BlocProvider(create: (context) => ClientReturnBloc(widget.apiService)),
        BlocProvider(create: (context) => SupplierBloc(widget.apiService)),
        BlocProvider(create: (context) => MeasureUnitsBloc(widget.apiService)),
        BlocProvider(create: (context) => WareHouseBloc(widget.apiService)),
        BlocProvider(
            create: (context) => PriceTypeScreenBloc(widget.apiService)),
        BlocProvider(
            create: (context) => SupplierReturnBloc(widget.apiService)),
        BlocProvider(create: (context) => WriteOffBloc(widget.apiService)),
        BlocProvider(create: (context) => MovementBloc(widget.apiService)),
        BlocProvider(create: (context) => ManufactureBloc(widget.apiService)),
        BlocProvider(create: (context) => CashDeskBloc()),
        BlocProvider(create: (context) => ExpenseBloc()),
        BlocProvider(create: (context) => IncomeBloc()),
        BlocProvider(
            create: (context) =>
                CategoryDashboardWarehouseBloc(widget.apiService)),
        BlocProvider(
            create: (context) => GoodDashboardWarehouseBloc(widget.apiService)),
        BlocProvider(create: (context) => SalesDashboardBloc()),
        BlocProvider(create: (context) => SalesDashboardGoodsBloc()),
        BlocProvider(create: (context) => SalesDashboardCashBalanceBloc()),
        BlocProvider(create: (context) => SalesDashboardCreditorsBloc()),
        BlocProvider(create: (context) => SalesDashboardDebtorsBloc()),
        BlocProvider(
            create: (context) => FieldConfigurationBloc(widget.apiService)),
      ],
      child: Consumer<AppThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            locale: _locale ?? const Locale('ru'),
            color: Colors.white,
            debugShowCheckedModeBanner: false,
            title: 'shamCRM',
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: scaffoldMessengerKey,
            theme: AppTheme.light(themeController.lightPalette),
            darkTheme: AppTheme.dark(themeController.darkPalette),
            themeMode: themeController.themeMode,
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
            builder: (context, child) {
              final colors = context.appColors;
              final themeController = context.watch<AppThemeController>();
              final appChild = Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: colors.backgroundPrimary),
                  AppBackgroundOverlay(
                    preset: themeController.backgroundPreset,
                    imagePath: themeController.backgroundImagePath,
                  ),
                  NativeInternetAwareWrapper(
                    child: child ?? const SizedBox.shrink(),
                  ),
                  const InAppUpdateCornerIndicator(),
                  if (kDebugMode) const HttpInspectorFab(),
                ],
              );
              return appChild;
            },
            home: Builder(
              builder: (context) {
                if (!widget.sessionValid) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (mounted) {
                      await checkForNewVersion(context);
                    }
                  });
                  return AuthScreen();
                }

                if (widget.token == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (mounted) {
                      await checkForNewVersion(context);
                    }
                  });
                  return AuthScreen();
                } else if (widget.pin == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (mounted) {
                      await checkForNewVersion(context);
                    }
                  });
                  return PinSetupScreen();
                } else {
                  return PinScreen(
                    initialMessage: widget.initialMessage,
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
          );
        },
      ),
    );
  }
}
