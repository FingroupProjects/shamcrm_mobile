import 'dart:async';
import 'package:flutter/foundation.dart';
import 'http_log_model.dart';

/// Singleton сервис для хранения и управления HTTP логами
class HttpLogger {
  static final HttpLogger _instance = HttpLogger._internal();
  factory HttpLogger() => _instance;
  HttpLogger._internal();

  // Максимальное количество логов в памяти
  static const int _maxLogs = 1000;

  // Список всех логов
  final List<HttpLogModel> _logs = [];

  // Stream controller для real-time обновлений
  final _logsController = StreamController<List<HttpLogModel>>.broadcast();

  /// Stream для подписки на обновления логов
  Stream<List<HttpLogModel>> get logsStream => _logsController.stream;

  /// Список шаблонов URL, которые исключаются из логирования (например, Firebase RTDB)
  static const List<String> _ignoredUrlPatterns = [
    'firebaseio.com',
    'firebasedatabase.app',
    'default-rtdb',
  ];

  /// Проверяет, нужно ли исключить данный URL из логирования
  static bool shouldIgnoreUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final lower = url.toLowerCase();
    for (final pattern in _ignoredUrlPatterns) {
      if (lower.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Получить все логи
  List<HttpLogModel> get logs =>
      List.unmodifiable(_logs.where((log) => !shouldIgnoreUrl(log.url)));

  /// Добавить новый лог
  void addLog(HttpLogModel log) {
    if (!kDebugMode) return; // Работает только в DEBUG режиме
    if (shouldIgnoreUrl(log.url)) return;

    _logs.insert(0, log); // Добавляем в начало списка (новые сверху)

    // Ограничиваем количество логов
    if (_logs.length > _maxLogs) {
      _logs.removeRange(_maxLogs, _logs.length);
    }

    // Уведомляем подписчиков
    _logsController.add(logs);

    if (kDebugMode) {
      debugPrint(
          'HttpLogger: Added log ${log.method} ${log.shortUrl} - Status: ${log.statusCode}');
    }
  }

  /// Обновить существующий лог (например, добавить response данные)
  void updateLog(String id, HttpLogModel updatedLog) {
    if (!kDebugMode) return;
    if (shouldIgnoreUrl(updatedLog.url)) {
      _logs.removeWhere((log) => log.id == id);
      _logsController.add(logs);
      return;
    }

    final index = _logs.indexWhere((log) => log.id == id);
    if (index != -1) {
      _logs[index] = updatedLog;
      _logsController.add(logs);
    }
  }

  /// Очистить все логи
  void clearLogs() {
    _logs.clear();
    _logsController.add(logs);
    if (kDebugMode) {
      debugPrint('HttpLogger: All logs cleared');
    }
  }

  /// Получить лог по ID
  HttpLogModel? getLogById(String id) {
    try {
      final log = _logs.firstWhere((log) => log.id == id);
      if (shouldIgnoreUrl(log.url)) return null;
      return log;
    } catch (e) {
      return null;
    }
  }

  /// Фильтровать логи по тексту (URL или метод)
  List<HttpLogModel> filterLogs(String query) {
    final activeLogs = _logs.where((log) => !shouldIgnoreUrl(log.url));
    if (query.isEmpty) return activeLogs.toList();

    final lowerQuery = query.toLowerCase();
    return activeLogs.where((log) {
      return log.url.toLowerCase().contains(lowerQuery) ||
          log.method.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Dispose (очистка ресурсов)
  void dispose() {
    _logsController.close();
  }
}
