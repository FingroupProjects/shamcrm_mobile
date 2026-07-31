import 'package:crm_task_manager/utils/utf16_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps valid UTF-16 including emoji unchanged', () {
    expect(sanitizeUtf16('Звонок 😀'), 'Звонок 😀');
  });

  test('replaces lone surrogate code units', () {
    expect(sanitizeUtf16('Лид\uD800'), 'Лид�');
    expect(sanitizeUtf16('\uDC00номер'), '�номер');
  });
}
