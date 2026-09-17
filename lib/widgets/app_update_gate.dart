import 'dart:async';

import 'package:crm_task_manager/app/app_keys.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';

/// Shows the update dialog only after PIN / Face ID / fingerprint.
///
/// If we show it on the PIN screen, Face ID then opens Home and the
/// dialog is removed with the PIN route. The user never taps Later or
/// Update. This gate waits until Home is on screen, then keeps the
/// dialog until the user taps a button.
class AppUpdateGate {
  AppUpdateGate._();

  static bool _homeVisible = false;
  static bool _isShowing = false;
  static bool _consumedThisSession = false;

  // Home is ready. PIN / Face ID is already done.
  static void setHomeVisible(bool visible) {
    _homeVisible = visible;
  }

  // Call this from Home after the first frame.
  static Future<void> showAfterUnlock(BuildContext context) async {
    // Let the PIN fade and the Face ID sheet finish closing.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!_homeVisible || _isShowing || _consumedThisSession) return;

    try {
      final status = await NewVersionPlus().getVersionStatus();
      if (!_homeVisible || _consumedThisSession) return;
      if (status == null || status.canUpdate != true) return;

      final dialogContext =
          context.mounted ? context : navigatorKey.currentContext;
      if (dialogContext == null || !dialogContext.mounted) return;

      _isShowing = true;
      final localizations = AppLocalizations.of(dialogContext);
      await UpdateDialog.show(
        context: dialogContext,
        status: status,
        title: localizations?.translate('app_update_available_title') ??
            'Обновление',
        message: localizations?.translate('app_update_available_message') ??
            'Доступна новая версия приложения',
        updateButton:
            localizations?.translate('app_update_button') ?? 'Обновить',
        laterButton: localizations?.translate('later') ?? 'Позже',
        onLaterPressed: () {
          debugPrint('Пользователь отложил обновление');
        },
      );
      // Dialog closed only via Later or Update.
      _consumedThisSession = true;
    } catch (e) {
      debugPrint('AppUpdateGate: version check failed: $e');
    } finally {
      _isShowing = false;
    }
  }
}
