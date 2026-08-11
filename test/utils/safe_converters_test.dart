import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeConverters', () {
    test('toInt converts string/double/null', () {
      expect(SafeConverters.toInt('42'), 42);
      expect(SafeConverters.toInt(3.9), 3);
      expect(SafeConverters.toInt(null), 0);
      expect(SafeConverters.toInt('abc', defaultValue: -1), -1);
      expect(SafeConverters.toIntOrNull(''), isNull);
    });

    test('toSafeString converts int/null', () {
      expect(SafeConverters.toSafeString(10), '10');
      expect(SafeConverters.toSafeString(null), '');
      expect(SafeConverters.toStringOrNull(null), isNull);
    });

    test('toDouble converts string with comma', () {
      expect(SafeConverters.toDouble('12,5'), 12.5);
      expect(SafeConverters.toDouble(null), 0.0);
    });

    test('toBool converts 0/1 and strings', () {
      expect(SafeConverters.toBool(1), isTrue);
      expect(SafeConverters.toBool('false'), isFalse);
      expect(SafeConverters.toBool(null), isFalse);
    });

    test('toMap/toList tolerate wrong types', () {
      expect(SafeConverters.toMap(null), isEmpty);
      expect(SafeConverters.toMapOrNull('x'), isNull);
      expect(SafeConverters.toList(null), isEmpty);
      expect(SafeConverters.toList([1, 2]).length, 2);
    });
  });
}
