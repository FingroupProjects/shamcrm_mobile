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

  /// Получить все логи
  List<HttpLogModel> get logs => List.unmodifiable(_logs);

  /// Добавить новый лог
  void addLog(HttpLogModel log) {
    if (!kDebugMode) return; // Работает только в DEBUG режиме

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
      return _logs.firstWhere((log) => log.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Фильтровать логи по тексту (URL или метод)
  List<HttpLogModel> filterLogs(String query) {
    if (query.isEmpty) return logs;

    final lowerQuery = query.toLowerCase();
    return _logs.where((log) {
      return log.url.toLowerCase().contains(lowerQuery) ||
          log.method.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Dispose (очистка ресурсов)
  void dispose() {
    _logsController.close();
  }
}
