import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import 'http_log_model.dart';
import 'http_logger.dart';

bool isTransientDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    case DioExceptionType.unknown:
      final cause = error.error;
      if (cause is SocketException || cause is HttpException) {
        return true;
      }
      final message = '${error.message} ${cause ?? ''}'.toLowerCase();
      return message.contains('connection') ||
          message.contains('broken pipe') ||
          message.contains('reset') ||
          message.contains('closed') ||
          message.contains('timed out');
    default:
      return false;
  }
}

class LoggedDioClient {
  LoggedDioClient._();

  static Dio? _shared;
  static DateTime? _lastUsedAt;

  static Dio create({
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(minutes: 2),
    Duration sendTimeout = const Duration(minutes: 2),
    bool enableRetry = false,
  }) {
    return _build(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      enableRetry: enableRetry,
    );
  }

  static Dio shared() {
    _shared ??= _build(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 25),
      enableRetry: true,
    );
    _lastUsedAt = DateTime.now();
    return _shared!;
  }

  static Future<void> reset() async {
    final current = _shared;
    _shared = null;
    _lastUsedAt = null;
    if (current == null) return;
    try {
      current.close(force: true);
    } catch (error) {
      debugPrint('LoggedDioClient reset error: $error');
    }
  }

  static Future<void> resetIfIdle({
    Duration idleFor = const Duration(seconds: 30),
  }) async {
    final lastUsedAt = _lastUsedAt;
    if (lastUsedAt == null) return;
    if (DateTime.now().difference(lastUsedAt) < idleFor) return;
    await reset();
  }

  static Dio _build({
    required Duration connectTimeout,
    required Duration receiveTimeout,
    required Duration sendTimeout,
    required bool enableRetry,
  }) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        followRedirects: true,
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.idleTimeout = const Duration(seconds: 8);
        client.connectionTimeout = connectTimeout;
        client.maxConnectionsPerHost = 6;
        return client;
      },
    );

    if (enableRetry) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) async {
            final request = error.requestOptions;
            final retryCount = (request.extra['retry_count'] as int?) ?? 0;
            final method = request.method.toUpperCase();
            final canRetry = (method == 'GET' || method == 'HEAD') &&
                retryCount < 1 &&
                isTransientDioError(error);

            if (!canRetry) {
              handler.next(error);
              return;
            }

            request.extra['retry_count'] = retryCount + 1;
            await Future<void>.delayed(const Duration(milliseconds: 250));
            try {
              final response = await dio.fetch(request);
              handler.resolve(response);
            } catch (retryError) {
              if (retryError is DioException) {
                handler.next(retryError);
              } else {
                handler.next(error);
              }
            }
          },
        ),
      );
    }

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
