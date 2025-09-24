// error_interceptor.dart
import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class ErrorInterceptor {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static ApiService? _apiService;

  static void initialize(ApiService apiService) {
    _apiService = apiService;
  }

  // Глобальный обработчик ошибок для API вызовов
  static Future<T?> handleApiCall<T>(Future<T?> Function() apiCall, {
    bool redirectOnError = true,
    String? customErrorMessage,
  }) async {
    try {
      return await apiCall();
    } catch (e) {
      print('ErrorInterceptor: Caught API error: $e');
      
      if (redirectOnError && _shouldRedirectToAuth(e)) {
        await _forceRedirectToAuth();
        return null;
      }

      // Показываем пользователю понятное сообщение об ошибке
      _showErrorMessage(customErrorMessage ?? _getErrorMessage(e));
      rethrow; // Пробрасываем ошибку дальше для обработки в блоках
    }
  }

  // Определяем, нужно ли перенаправлять на авторизацию
  static bool _shouldRedirectToAuth(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('401') ||
           errorString.contains('неавторизованный доступ') ||
           errorString.contains('unauthorized') ||
           errorString.contains('session is invalid') ||
           errorString.contains('base url is not initialized') ||
           errorString.contains('токен') ||
           errorString.contains('token');
  }

  // Принудительное перенаправление на экран авторизации
  static Future<void> _forceRedirectToAuth() async {
    try {
      print('ErrorInterceptor: Forcing redirect to auth');
      
      if (_apiService != null) {
        await _apiService!.logout();
        await _apiService!.reset();
      }

      final context = _navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/local_auth',
          (route) => false,
        );
      }
    } catch (e) {
      print('ErrorInterceptor: Error in force redirect: $e');
    }
  }

  // Получаем понятное сообщение об ошибке
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socketexception') || 
        errorString.contains('timeoutexception')) {
      return 'Проблема с подключением к интернету';
    } else if (errorString.contains('401') || 
               errorString.contains('неавторизованный')) {
      return 'Необходима повторная авторизация';
    } else if (errorString.contains('404')) {
      return 'Запрашиваемые данные не найдены';
    } else if (errorString.contains('500')) {
      return 'Ошибка сервера, попробуйте позже';
    } else if (errorString.contains('formatexception')) {
      return 'Получены некорректные данные';
    } else {
      return 'Произошла ошибка, попробуйте еще раз';
    }
  }

  // Показываем сообщение об ошибке пользователю
  static void _showErrorMessage(String message) {
    final context = _navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  // Метод для проверки состояния приложения
  static Future<bool> checkAppHealth() async {
    try {
      if (_apiService == null) return false;
      
      final token = await _apiService!.getToken();
      if (token == null || token.isEmpty) return false;
      
      final domain = await _apiService!.getVerifiedDomain();
      if (domain == null || domain.isEmpty) {
        // Проверяем альтернативные источники домена
        final qrData = await _apiService!.getQrData();
        if (qrData['domain'] == null || qrData['domain']!.isEmpty) {
          final enteredDomains = await _apiService!.getEnteredDomain();
          if (enteredDomains['enteredDomain'] == null || 
              enteredDomains['enteredDomain']!.isEmpty) {
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      print('ErrorInterceptor: Health check failed: $e');
      return false;
    }
  }
}

// Расширение для ApiService для интеграции с ErrorInterceptor
extension ApiServiceErrorHandling on ApiService {
  
  // Безопасные операции без прямого вызова приватных методов
  // Вместо этого используем публичные методы или создаем обертки

  // Безопасная проверка сессии
  Future<bool> safeBoolOperation(Future<bool> Function() operation) async {
    try {
      final result = await ErrorInterceptor.handleApiCall(
        operation,
        redirectOnError: false,
      );
      return result ?? false;
    } catch (e) {
      print('ApiService: Safe bool operation failed: $e');
      return false;
    }
  }

  // Безопасное получение строковых данных
  Future<String?> safeStringOperation(Future<String?> Function() operation) async {
    try {
      return await ErrorInterceptor.handleApiCall(
        operation,
        redirectOnError: false,
      );
    } catch (e) {
      print('ApiService: Safe string operation failed: $e');
      return null;
    }
  }
}