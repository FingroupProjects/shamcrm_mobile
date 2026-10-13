import 'package:crm_task_manager/custom_widget/calendar/calendar_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 12);

  test('будущий день считается как в календаре телефона', () {
    expect(
      relativeCalendarDistance(DateTime(2026, 12, 25), today, 'ru'),
      'Через 74 дня',
    );
    expect(
      relativeCalendarDistance(DateTime(2026, 10, 14), today, 'ru'),
      'Через 2 дня',
    );
    expect(
      relativeCalendarDistance(DateTime(2026, 11, 2), today, 'ru'),
      'Через 21 день',
    );
  });

  test('сегодня, завтра и прошедшие дни', () {
    expect(
      relativeCalendarDistance(today, today, 'ru'),
      'Сегодня',
    );
    expect(
      relativeCalendarDistance(DateTime(2026, 10, 13), today, 'ru'),
      'Завтра',
    );
    expect(
      relativeCalendarDistance(DateTime(2026, 10, 11), today, 'ru'),
      'Вчера',
    );
    expect(
      relativeCalendarDistance(DateTime(2026, 10, 7), today, 'ru'),
      '5 дней назад',
    );
  });
}
