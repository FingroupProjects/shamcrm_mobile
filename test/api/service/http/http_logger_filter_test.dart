import 'package:crm_task_manager/api/service/http/http_log_model.dart';
import 'package:crm_task_manager/api/service/http/http_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpLogger.shouldIgnoreUrl', () {
    test('identifies firebase realtime database URLs', () {
      expect(
        HttpLogger.shouldIgnoreUrl(
          'https://ваше-имя-default-rtdb.firebaseio.com/something.json',
        ),
        isTrue,
      );
      expect(
        HttpLogger.shouldIgnoreUrl(
          'https://my-project-default-rtdb.firebaseio.com',
        ),
        isTrue,
      );
      expect(
        HttpLogger.shouldIgnoreUrl(
          'https://test-project.firebaseio.com',
        ),
        isTrue,
      );
      expect(
        HttpLogger.shouldIgnoreUrl(
          'https://my-db-default-rtdb.europe-west1.firebasedatabase.app',
        ),
        isTrue,
      );
      expect(
        HttpLogger.shouldIgnoreUrl(
          'https://firebaseinstallations.googleapis.com/v1/projects/shamcrm/installations',
        ),
        isTrue,
      );
      expect(
        HttpLogger.shouldIgnoreUrl(
          'https://firebaselogging-pa.googleapis.com/v1/firelog/legacy/log',
        ),
        isTrue,
      );
    });

    test('allows normal CRM API and WebSocket URLs', () {
      expect(
        HttpLogger.shouldIgnoreUrl(
          'https://fingroupcrm-new-back.shamcrm.com/api/v3/chat/getMyChats/lead',
        ),
        isFalse,
      );
      expect(
        HttpLogger.shouldIgnoreUrl(
          'wss://soketi.shamcrm.com/socket/presence-user',
        ),
        isFalse,
      );
      expect(
        HttpLogger.shouldIgnoreUrl(
          'https://fingroupcrm-new-back.shamcrm.com/add-fcm-token',
        ),
        isFalse,
      );
    });

    test('handles empty and null safely', () {
      expect(HttpLogger.shouldIgnoreUrl(null), isFalse);
      expect(HttpLogger.shouldIgnoreUrl(''), isFalse);
      expect(HttpLogger.shouldIgnoreUrl('   '), isFalse);
    });
  });

  group('HttpLogger filtering', () {
    final logger = HttpLogger();

    setUp(() {
      logger.clearLogs();
    });

    test('does not add ignored URLs to logs', () {
      logger.addLog(
        HttpLogModel(
          id: 'test_1',
          timestamp: DateTime.now(),
          method: 'GET',
          url: 'https://ваше-имя-default-rtdb.firebaseio.com/test.json',
        ),
      );

      expect(logger.logs.any((l) => l.id == 'test_1'), isFalse);
      expect(logger.getLogById('test_1'), isNull);
    });

    test('allows and keeps regular URLs', () {
      logger.addLog(
        HttpLogModel(
          id: 'test_2',
          timestamp: DateTime.now(),
          method: 'POST',
          url: 'https://fingroupcrm-new-back.shamcrm.com/api/v3/leads',
        ),
      );

      expect(logger.logs.any((l) => l.id == 'test_2'), isTrue);
      expect(logger.getLogById('test_2'), isNotNull);
    });
  });
}
