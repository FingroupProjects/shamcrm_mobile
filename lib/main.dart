import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/storage/secure_storage_service.dart';
import 'package:crm_task_manager/app/bootstrap/app_bootstrap.dart';
import 'package:crm_task_manager/app/crash_reporting/crash_reporter.dart';
import 'package:crm_task_manager/app/error_app.dart';
import 'package:crm_task_manager/app/my_app.dart';
import 'package:crm_task_manager/app/session/session_validation.dart';
import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:flutter/material.dart';

// Compatibility re-exports for existing `import '.../main.dart'` usages.
export 'package:crm_task_manager/app/app_keys.dart';
export 'package:crm_task_manager/app/my_app.dart';

// Разработка проекта shamCRM начата в августе 2024 года.
// Разработано компанией Softtech Group.
// Разработчик: Авезов Д. И.

void main() {
  runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      
      final apiService = ApiService();
      final authService = AuthService();
      await requestTrackingAuthorizationIfNeeded();
      await safeInitializeOfflineRuntime();
      await safeInitializeFirebase();

      final sessionValidation = await validateApplicationSession(apiService);
      
      String? token;
      String? pin;
      bool isDomainChecked = false;

      if (sessionValidation.isValid) {
        token = await apiService.getToken();
        pin = await authService.getPin();
        isDomainChecked = await apiService.isDomainChecked();

        if (isDomainChecked) {
          await safeInitializeApiService(apiService);
          safeRegisterOutboxExecutors(apiService);
        }
      } else {
        await clearAllApplicationData(apiService, authService);
      }

      final initialMessage = await safeLoadInitialMessage();
      await AppThemeController.instance.initialize();
      await AppThemeController.instance.precacheBackground();
      safeConfigureSystemUi();
      final savedLocale = await safeLoadLocale();
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
      await recordFatalError(e, stackTrace, reason: 'startup');
      debugPrint('main: startup error: $e');
      debugPrint('main: startup stackTrace: $stackTrace');
      runApp(ErrorApp(error: e.toString()));
    }
  }, (error, stackTrace) async {
    await recordFatalError(error, stackTrace, reason: 'zone');
  });
}
// The following function is used to clear all application data in case of session validation failure.

