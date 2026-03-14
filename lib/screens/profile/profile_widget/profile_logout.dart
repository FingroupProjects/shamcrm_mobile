import 'dart:io';

import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/api/service/secure_storage_service.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class LogoutButtonWidget extends StatelessWidget {
  const LogoutButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () async {
        try {
          final apiService = ApiService();
          final authService = AuthService();

          // Вызов API для выхода из аккаунта
          await apiService.logoutAccount();

          // Полная очистка SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          // Очистка локальных auth-данных и внутренних состояний API
          await authService.clearAllAuthData();
          await apiService.logout();
          await apiService.reset();

          // Небольшая задержка для завершения асинхронных операций
          await Future.delayed(const Duration(milliseconds: 300));

          _terminateApplication();
        } catch (e) {
          debugPrint('Ошибка при выходе: $e');
          _terminateApplication();
        }
      },
      child: _buildProfileOption(
        text: localizations!.exit,
      ),
    );
  }

  Widget _buildProfileOption({required String text}) {
    return ProfileSettingsTile(
      title: text,
      icon: Icons.logout_rounded,
      danger: true,
    );
  }

  void _terminateApplication() {
    if (Platform.isAndroid) {
      // SystemNavigator иногда только сворачивает задачу, поэтому завершаем процесс.
      exit(0);
    } else {
      // На iOS принудительное завершение не рекомендуется, оставляем системное закрытие.
      SystemNavigator.pop();
    }
  }
}
