import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'http_log_model.dart';
import 'http_logger.dart';

class LoggedDioClient {
  LoggedDioClient._();

  static Dio create() {
    final dio = Dio();

    if (!kDebugMode) {
      return dio;
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final logId = DateTime.now().millisecondsSinceEpoch.toString();
          options.extra['http_log_id'] = logId;
          options.extra['http_log_start'] = DateTime.now();

          HttpLogger().addLog(
            HttpLogModel(
              id: logId,
              timestamp: DateTime.now(),
              method: options.method.toUpperCase(),
              url: options.uri.toString(),
              requestHeaders: _stringifyHeaders(options.headers),
              requestBody: _stringifyBody(options.data),
            ),
          );

          handler.next(options);
        },
        onResponse: (response, handler) {
          final logId = response.requestOptions.extra['http_log_id'] as String?;
          final startTime =
              response.requestOptions.extra['http_log_start'] as DateTime?;
          if (logId != null) {
            final existingLog = HttpLogger().getLogById(logId);
            if (existingLog != null) {
              HttpLogger().updateLog(
                logId,
                existingLog.copyWith(
                  statusCode: response.statusCode,
                  responseHeaders: _stringifyHeaders(response.headers.map),
                  responseBody: _stringifyBody(response.data),
                  duration: startTime == null
                      ? null
                      : DateTime.now().difference(startTime),
                ),
              );
            }
          }
          handler.next(response);
        },
        onError: (error, handler) {
          final logId = error.requestOptions.extra['http_log_id'] as String?;
          final startTime =
              error.requestOptions.extra['http_log_start'] as DateTime?;
          if (logId != null) {
            final existingLog = HttpLogger().getLogById(logId);
            if (existingLog != null) {
              HttpLogger().updateLog(
                logId,
                existingLog.copyWith(
                  statusCode: error.response?.statusCode,
                  responseHeaders: error.response == null
                      ? null
                      : _stringifyHeaders(error.response!.headers.map),
                  responseBody: error.response == null
                      ? null
                      : _stringifyBody(error.response!.data),
                  duration: startTime == null
                      ? null
                      : DateTime.now().difference(startTime),
                  error: error.message,
                ),
              );
            }
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static Map<String, String> _stringifyHeaders(Map<dynamic, dynamic> headers) {
    final result = <String, String>{};
    headers.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        result[key.toString()] = value.join(', ');
      } else {
        result[key.toString()] = value.toString();
      }
    });
    return result;
  }

  static String? _stringifyBody(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    try {
      return json.encode(data);
    } catch (_) {
      return data.toString();
    }
  }
}
