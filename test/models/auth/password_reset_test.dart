import 'package:crm_task_manager/models/auth/password_reset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forgot-password result is user card plus code', () {
    final challenge = parseForgotPasswordResult(
      [
        {
          'id': 8,
          'email': 'dilshodjon@fingroup.tj',
          'login': 'D_Avezov',
        },
        8762,
      ],
    );

    expect(challenge.userId, 8);
    expect(challenge.code, '8762');
    expect(challenge.email, 'dilshodjon@fingroup.tj');
    expect(passwordCodesMatch('8762', challenge.code), isTrue);
    expect(passwordCodesMatch('0000', challenge.code), isFalse);
  });

  test('string code and fallback email still parse', () {
    final challenge = parseForgotPasswordResult(
      [
        {'id': '15'},
        '4410',
      ],
      fallbackEmail: 'user@example.com',
    );

    expect(challenge.userId, 15);
    expect(challenge.code, '4410');
    expect(challenge.email, 'user@example.com');
  });

  test('broken forgot-password payload is rejected', () {
    expect(
      () => parseForgotPasswordResult({'code': 1}),
      throwsFormatException,
    );
    expect(
      () => parseForgotPasswordResult([
        {'email': 'a@b.c'},
        10,
      ]),
      throwsFormatException,
    );
  });

  test('success response is result Success with empty errors', () {
    expect(
      passwordApiSucceeded(200, {'result': 'Success', 'errors': null}),
      isTrue,
    );
    expect(
      passwordApiSucceeded(422, {
        'message': 'The given data was invalid.',
        'errors': {
          'current_password': ['Неверный текущий пароль'],
        },
      }),
      isFalse,
    );
    expect(
      passwordApiErrorText({
        'message': 'The given data was invalid.',
        'errors': {
          'current_password': ['Неверный текущий пароль'],
        },
      }),
      'Неверный текущий пароль',
    );
    expect(
      passwordApiErrorText({'errors': null}, fallback: 'password_change_error'),
      'password_change_error',
    );
  });
}
