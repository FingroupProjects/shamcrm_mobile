import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/storage/secure_storage_service.dart';
import 'package:crm_task_manager/app/bootstrap/app_bootstrap.dart';
import 'package:crm_task_manager/app/crash_reporting/crash_reporter.dart';
import 'package:crm_task_manager/app/error_app.dart';
import 'package:crm_task_manager/app/my_app.dart';
import 'package:crm_task_manager/app/session/session_validation.dart';
import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/utils/section_tab_memory.dart';
import 'package:flutter/material.dart';

// Compatibility re-exports for existing `import '.../main.dart'` usages.
export 'package:crm_task_manager/app/app_keys.dart';
export 'package:crm_task_manager/app/my_app.dart';

// Разработка проекта shamCRM  начата в августе 2024 года.
// Разработано компанией Softtech Group.
// Разработчик: Авезов Д. И.

void main() {
  runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      // Новый запуск и Reload не должны открывать прошлую колонку.
      await SectionTabMemory.clearAll();

      final apiService = ApiService();
      final authService = AuthService();

      // На белом экране с логотипом читаем только локальные данные.
      // От них зависит первый экран: PIN, установка PIN или авторизация.
      // Firebase, база, пуш и обои стартуют уже после runApp.
      final sessionFuture = validateApplicationSession(apiService);
      final localeFuture = safeLoadLocale();
      final themeFuture = AppThemeController.instance.initialize();

      final sessionValidation = await sessionFuture;
      String? token;
      String? pin;
      var isDomainChecked = false;

      if (sessionValidation.isValid) {
        final sessionParts = await Future.wait<Object?>([
          apiService.getToken(),
          authService.getPin(),
          apiService.isDomainChecked(),
        ]);
        token = sessionParts[0] as String?;
        pin = sessionParts[1] as String?;
        isDomainChecked = sessionParts[2] as bool;
      }

      final savedLocale = await localeFuture;
      await themeFuture;
      unawaited(safeConfigureSystemUi());

      final domainReady = isDomainChecked && sessionValidation.isValid;
      runApp(MyApp(
        apiService: apiService,
        authService: authService,
        isDomainChecked: domainReady,
        token: sessionValidation.isValid ? token : null,
        pin: sessionValidation.isValid ? pin : null,
        initialLocale: savedLocale,
        // Пуш, которым открыли приложение, доставится в фоне.
        initialMessage: null,
        sessionValid: sessionValidation.isValid,
      ));

      unawaited(startDeferredStartup(
        apiService: apiService,
        authService: authService,
        sessionValid: sessionValidation.isValid,
        isDomainChecked: domainReady,
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
