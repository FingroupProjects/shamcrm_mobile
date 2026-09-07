import 'dart:io';

import 'package:crm_task_manager/api/service/http/dio_client.dart';
import 'package:crm_task_manager/services/chat_media_persistent_cache.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isTransientDioError', () {
    test('retries connection timeouts and resets', () {
      expect(
        isTransientDioError(
          DioException(
            requestOptions: RequestOptions(path: '/file'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        isTrue,
      );
      expect(
        isTransientDioError(
          DioException(
            requestOptions: RequestOptions(path: '/file'),
            type: DioExceptionType.connectionError,
            error: const SocketException('Connection reset by peer'),
          ),
        ),
        isTrue,
      );
    });

    test('does not retry client errors', () {
      expect(
        isTransientDioError(
          DioException(
            requestOptions: RequestOptions(path: '/file'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/file'),
              statusCode: 404,
            ),
          ),
        ),
        isFalse,
      );
    });
  });

  group('isLikelyHtmlOrJsonError', () {
    test('rejects html and json error bodies', () {
      expect(
        isLikelyHtmlOrJsonError('<html>Access denied</html>'.codeUnits),
        isTrue,
      );
      expect(
        isLikelyHtmlOrJsonError('  {"error":"unauthorized"}'.codeUnits),
        isTrue,
      );
    });

    test('keeps real media bytes', () {
      expect(isLikelyHtmlOrJsonError([0xFF, 0xD8, 0xFF, 0xE0]), isFalse);
      expect(isLikelyHtmlOrJsonError([0x89, 0x50, 0x4E, 0x47]), isFalse);
      expect(isLikelyHtmlOrJsonError([0x49, 0x44, 0x33, 0x04]), isFalse);
    });
  });
}
