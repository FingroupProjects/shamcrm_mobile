import 'dart:io';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class AuthErrorDialog {
  static Future<void> show(BuildContext context, {String? customMessage}) async {
    final localizations = AppLocalizations.of(context)!;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Нельзя закрыть нажатием вне диалога
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Отключаем кнопку "Назад"
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 16,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Иконка
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 40,
                      color: const Color(0xFF1E2E52),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Заголовок
                  Text(
                    customMessage ?? localizations.translate('session_expired_title') ?? 'Сессия истекла',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: Color(0xFF1E2E52),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Описание
                  Text(
                    localizations.translate('session_expired_description') ?? 
                    'Вы вышли из аккаунта.\nВойдите заново, чтобы продолжить работу.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Gilroy',
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Кнопка
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _performLogout(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2E52),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        localizations.translate('understand_and_exit') ?? 'Понятно, выйти',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _performLogout(BuildContext context) async {
    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1E2E52),
          ),
        ),
      );

      // Выполняем logout
      ApiService apiService = ApiService();
      await apiService.logoutAccount();
      
      // Очистка SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      await apiService.logout();
      
      // Перезапуск приложения
      Restart.restartApp();
      exit(0);
      
    } catch (e) {
      print('AuthErrorDialog: Error in logout: $e');
      // В случае ошибки всё равно перезапускаем приложение
      Restart.restartApp();
      exit(0);
    }
  }
}

// Утилита для быстрого вызова диалога
class AuthErrorHandler {
  static void handleAuthError(BuildContext context, {String? customMessage}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthErrorDialog.show(context, customMessage: customMessage);
    });
  }
}