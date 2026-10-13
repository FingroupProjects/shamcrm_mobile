import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drops a bare Exception prefix from a server message', () {
    expect(
      friendlyError(Exception('Текущий пароль неверен.')),
      'Текущий пароль неверен.',
    );
    expect(
      friendlyError('Exception: Текущий пароль неверен.'),
      'Текущий пароль неверен.',
    );
  });

  test('drops a doubled Exception prefix', () {
    expect(
      friendlyError(Exception('Exception: Текущий пароль неверен.')),
      'Текущий пароль неверен.',
    );
  });
}
