import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase/firebase_api.dart';
import 'package:crm_task_manager/app/crash_reporting/crash_reporter.dart';
import 'package:crm_task_manager/firebase_options.dart';
import 'package:crm_task_manager/offline/core/core_outbox_executors.dart';
import 'package:crm_task_manager/offline/core/offline_bootstrap.dart';
import 'package:crm_task_manager/screens/profile/languages/local_manager_lang.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> requestTrackingAuthorizationIfNeeded() async {
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
    await recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.tracking_authorization',
      screenHint: 'ios',
    );
  }
}

Future<void> safeInitializeOfflineRuntime() async {
  try {
    await OfflineBootstrap.initialize().timeout(const Duration(seconds: 8));
  } catch (e, stackTrace) {
    debugPrint('main: OfflineBootstrap initialize error: $e');
    debugPrint('main: OfflineBootstrap stackTrace: $stackTrace');
    await recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.offline_runtime',
      screenHint: 'startup',
    );
  }
}

Future<void> safeInitializeFirebase() async {
  try {
    await initializeFirebase().timeout(const Duration(seconds: 8));
    await initializeCrashlytics();
    FirebaseApi.ensureBackgroundHandlerRegistered();
  } catch (e, stackTrace) {
    debugPrint('main: Firebase initialize error: $e');
    debugPrint('main: Firebase initialize stackTrace: $stackTrace');
    await recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.firebase',
      screenHint: 'startup',
    );
  }
}

Future<void> safeInitializeApiService(ApiService apiService) async {
  try {
    await apiService.initialize().timeout(const Duration(seconds: 6));
  } catch (e, stackTrace) {
    debugPrint('main: ApiService initialize error: $e');
    debugPrint('main: ApiService initialize stackTrace: $stackTrace');
    await recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.api_service',
      screenHint: 'startup',
    );
  }
}

Future<void> safeRegisterOutboxExecutors(ApiService apiService) async {
  try {
    CoreOutboxExecutors.register(apiService);
  } catch (e, stackTrace) {
    debugPrint('main: CoreOutboxExecutors register error: $e');
    debugPrint('main: CoreOutboxExecutors register stackTrace: $stackTrace');
    await recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.outbox_executors',
      screenHint: 'startup',
    );
  }
}

Future<RemoteMessage?> safeLoadInitialMessage() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      return await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(const Duration(seconds: 3));
    }
  } catch (e, stackTrace) {
    debugPrint('main: initial message error: $e');
    debugPrint('main: initial message stackTrace: $stackTrace');
    await recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.initial_message',
      screenHint: 'startup',
    );
  }

  return null;
}

Future<void> safeConfigureSystemUi() async {
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
    await recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.system_ui',
      screenHint: 'startup',
    );
  }
}

Future<Locale> safeLoadLocale() async {
  try {
    final String? savedLanguageCode =
        await LanguageManager.getLanguage().timeout(const Duration(seconds: 2));
    if (savedLanguageCode != null && savedLanguageCode.isNotEmpty) {
      return Locale(savedLanguageCode);
    }
  } catch (e, stackTrace) {
    debugPrint('main: locale load error: $e');
    debugPrint('main: locale load stackTrace: $stackTrace');
    await recordNonFatalError(
      e,
      stackTrace,
      reason: 'startup.locale',
      screenHint: 'startup',
    );
  }

  return const Locale('ru');
}

Future<void> initializeFirebase() async {
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
      // Firebase app warning
    }
  } catch (e) {
    final errorString = e.toString();

    if (errorString.contains('already exists') ||
        errorString.contains('duplicate app')) {
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        Firebase.app();
      } catch (checkError) {
        // Firebase app not available
      }
    }
  }
}
