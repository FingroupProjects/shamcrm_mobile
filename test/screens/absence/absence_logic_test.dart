import 'package:crm_task_manager/models/absence/absence_models.dart';
import 'package:crm_task_manager/screens/absence/absence_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 13);

  AbsenceDraft draft({
    DateTime? from,
    DateTime? to,
    String? timeFrom,
    String? timeTo,
    String reason = 'Приём у врача',
  }) {
    return AbsenceDraft(
      dateFrom: from,
      dateTo: to,
      timeFrom: timeFrom,
      timeTo: timeTo,
      reason: reason,
    );
  }

  test('requires both dates, a reason, and a future day', () {
    final missing = validateAbsenceDraft(
      draft(reason: '   '),
      today: today,
    );
    expect(missing['date_from'], 'absence_err_dates');
    expect(missing['reason'], 'absence_err_reason');

    final past = validateAbsenceDraft(
      draft(
        from: DateTime(2026, 10, 12),
        to: DateTime(2026, 10, 12),
      ),
      today: today,
    );
    expect(past['date_from'], 'absence_err_past');

    final order = validateAbsenceDraft(
      draft(
        from: DateTime(2026, 10, 20),
        to: DateTime(2026, 10, 18),
      ),
      today: today,
    );
    expect(order['date_to'], 'absence_err_date_order');
  });

  test('time is optional, but only as a pair and with a later end', () {
    final oneSide = validateAbsenceDraft(
      draft(
        from: DateTime(2026, 10, 20),
        to: DateTime(2026, 10, 22),
        timeFrom: '10:00',
      ),
      today: today,
    );
    expect(oneSide['time_from'], 'absence_err_time_pair');

    final order = validateAbsenceDraft(
      draft(
        from: DateTime(2026, 10, 20),
        to: DateTime(2026, 10, 20),
        timeFrom: '12:00',
        timeTo: '10:00',
      ),
      today: today,
    );
    expect(order['time_to'], 'absence_err_time_order');

    final ok = validateAbsenceDraft(
      draft(
        from: DateTime(2026, 10, 20),
        to: DateTime(2026, 10, 22),
        timeFrom: '10:00',
        timeTo: '12:00',
      ),
      today: today,
    );
    expect(ok.isEmpty, isTrue);
  });

  test('time can cover a date range, and an empty end date is that one day', () {
    final body = absenceRequestBody(
      draft(
        from: DateTime(2026, 10, 20),
        to: DateTime(2026, 10, 29),
        timeFrom: '10:00',
        timeTo: '11:00',
      ),
    );
    expect(body['date_from'], '2026-10-20');
    expect(body['date_to'], '2026-10-29');
    expect(body['time_from'], '10:00');
    expect(body['time_to'], '11:00');

    final oneDay = absenceRequestBody(
      draft(
        from: DateTime(2026, 10, 20),
        timeFrom: '10:00',
        timeTo: '11:00',
      ),
    );
    expect(oneDay['date_to'], '2026-10-20');
    expect(oneDay['time_from'], '10:00');

    final fullPeriod = absenceRequestBody(
      draft(
        from: DateTime(2026, 10, 20),
        to: DateTime(2026, 10, 22),
      ),
    );
    expect(fullPeriod.containsKey('time_from'), isFalse);
    expect(fullPeriod['date_to'], '2026-10-22');
    expect(
      absenceUntimedSpanKey(DateTime(2026, 10, 20), DateTime(2026, 10, 20)),
      'absence_all_day',
    );
    expect(
      absenceUntimedSpanKey(DateTime(2026, 10, 20), DateTime(2026, 10, 29)),
      'absence_whole_period',
    );
  });

  test('time list covers the whole day from 00:00 to 24:00', () {
    final options = absenceTimeOptions();
    expect(options.first, '00:00');
    expect(options.last, '24:00');
    expect(options.contains('09:30'), isTrue);
    expect(options.contains('23:30'), isTrue);
    expect(absenceTimeIsAfter('23:00', '24:00'), isTrue);
  });

  test('empty limit is null and zero stays zero', () {
    expect(
      absenceSettingsBody(fullDay: '', partial: '0'),
      {'full_day_limit': null, 'partial_limit': 0},
    );
    expect(
      () => absenceSettingsBody(fullDay: '-1', partial: '1'),
      throwsFormatException,
    );
  });

  test('type comes from the API field, not from equal dates', () {
    final partialRange = AbsenceRequest.fromJson({
      'id': 1,
      'user_id': 7,
      'type': 'partial',
      'type_label': 'Отпрос',
      'date_from': '2026-10-20',
      'date_to': '2026-10-22',
      'status': 'pending',
      'status_label': 'На рассмотрении',
      'reason': 'Врач',
    });
    final fullDay = AbsenceRequest.fromJson({
      'id': 2,
      'user_id': 7,
      'type': 'full_day',
      'date_from': '2026-10-20',
      'date_to': '2026-10-20',
      'time_from': null,
      'status': 'cancelled',
      'reason': 'Семейные обстоятельства',
    });
    expect(partialRange.type, 'partial');
    expect(partialRange.isPartial, isTrue);
    expect(fullDay.type, 'full_day');
    expect(fullDay.timeFrom, isNull);
    expect(formatAbsencePeriod(fullDay.dateFrom, fullDay.dateTo), '20.10.2026');
    expect(
      formatAbsencePeriod(partialRange.dateFrom, partialRange.dateTo),
      '20.10.2026 — 22.10.2026',
    );
    expect(absenceDayCount(partialRange.dateFrom, partialRange.dateTo), 3);
  });

  test('own pending request can be edited only when it has not started', () {
    final employee = AbsenceAccess(
      userId: 7,
      canCreatePermission: true,
      canReviewPermission: false,
      canSettingsPermission: false,
      isAdminRole: false,
      isHeadOfDepartment: false,
    );
    final admin = AbsenceAccess(
      userId: 1,
      canCreatePermission: false,
      canReviewPermission: true,
      canSettingsPermission: true,
      isAdminRole: true,
      isHeadOfDepartment: false,
    );
    final pending = AbsenceRequest.fromJson({
      'id': 3,
      'user_id': 7,
      'type': 'full_day',
      'date_from': '2026-10-20',
      'date_to': '2026-10-20',
      'status': 'pending',
      'reason': 'Банк',
    });
    final past = AbsenceRequest.fromJson({
      'id': 4,
      'user_id': 7,
      'type': 'full_day',
      'date_from': '2026-10-01',
      'date_to': '2026-10-01',
      'status': 'pending',
      'reason': 'Банк',
    });
    expect(
      canEditAbsence(access: employee, request: pending),
      isTrue,
    );
    expect(
      canEditAbsence(access: employee, request: past),
      isTrue,
    );
    expect(
      canEditAbsence(access: admin, request: pending),
      isFalse,
    );
  });

  test('a manager cannot decide their own request, an admin can', () {
    final head = AbsenceAccess(
      userId: 9,
      canCreatePermission: true,
      canReviewPermission: true,
      canSettingsPermission: false,
      isAdminRole: false,
      isHeadOfDepartment: true,
    );
    final admin = AbsenceAccess(
      userId: 1,
      canCreatePermission: false,
      canReviewPermission: false,
      canSettingsPermission: false,
      isAdminRole: true,
      isHeadOfDepartment: false,
    );
    final own = AbsenceRequest.fromJson({
      'id': 5,
      'user_id': 9,
      'type': 'partial',
      'date_from': '2026-10-20',
      'date_to': '2026-10-20',
      'status': 'pending',
      'reason': 'Врач',
    });
    expect(canDecideAbsence(access: head, request: own), isFalse);
    expect(canDecideAbsence(access: admin, request: own), isTrue);
    expect(head.showMenu, isFalse);
    expect(admin.showMenu, isFalse);
    expect(head.canSubmit, isTrue);
    expect(head.showMy, isTrue);
    expect(admin.canSubmit, isFalse);
    expect(admin.showMy, isFalse);
    expect(admin.showTeam, isTrue);
    expect(admin.showSettings, isTrue);
    expect(head.showTeam, isTrue);
  });

  test('stats keep by_status separate from the filtered total', () {
    final stats = parseAbsenceStats({
      'result': {
        'total': 1,
        'by_status': {
          'pending': 4,
          'approved': 2,
          'rejected': 1,
          'cancelled': 3,
        },
      },
    });
    expect(stats.total, 1);
    expect(stats.pending, 4);
    expect(stats.cancelled, 3);
  });

  test('422 field errors and limit warning are parsed, not calculated', () {
    final error = absenceErrorFromBody(
      statusCode: 422,
      body: '{"errors":{"reason":["Укажите причину"],"date_from":["Ошибка"]}}',
    );
    expect(error.fieldErrors['reason'], 'Укажите причину');
    expect(error.fieldErrors['date_from'], 'Ошибка');

    final request = AbsenceRequest.fromJson({
      'id': 8,
      'user_id': 7,
      'type': 'full_day',
      'date_from': '2026-10-20',
      'date_to': '2026-10-20',
      'status': 'pending',
      'reason': 'Врач',
      'limit_warning': {
        'approved': 2,
        'limit': 2,
        'message': 'Лимит на месяц уже выбран: одобрено 2 из 2',
      },
    });
    expect(
      request.limitWarning?.message,
      'Лимит на месяц уже выбран: одобрено 2 из 2',
    );
    expect(
      AbsenceLimitWarning.tryParse({'approved': 1, 'limit': 2, 'message': ''}),
      isNull,
    );
  });

  test('list path sends the absence period and skips empty filters', () {
    final path = absenceListPath(
      mine: false,
      page: 2,
      filters: AbsenceFilters(
        userIds: const [1, 2, 5],
        status: 'pending',
        dateFrom: DateTime(2026, 10, 1),
        dateTo: DateTime(2026, 10, 31),
      ),
    );
    expect(path.contains('/absence-requests?'), isTrue);
    expect(path.contains('user_ids=1%2C2%2C5'), isTrue);
    expect(path.contains('status=pending'), isTrue);
    expect(path.contains('date_from=2026-10-01'), isTrue);
    expect(path.contains('page=2'), isTrue);

    expect(
      absenceListPath(mine: true, page: 1, filters: AbsenceFilters.empty),
      '/absence-requests/mine?page=1&per_page=20',
    );
  });

  test('head of department can be nested in the user payload', () {
    expect(
      absenceJsonIsHead({
        'result': {
          'departments': [
            {
              'name': 'Продажи',
              'pivot': {'head_of_department': 1},
            },
          ],
        },
      }),
      isTrue,
    );
    expect(absenceJsonIsHead({'departments': []}), isFalse);

    const withoutIndex = AbsenceAccess(
      userId: 4,
      canCreatePermission: true,
      canReviewPermission: false,
      canSettingsPermission: false,
      isAdminRole: false,
      isHeadOfDepartment: false,
    );
    const withIndex = AbsenceAccess(
      userId: 4,
      canIndexPermission: true,
      canCreatePermission: true,
      canReviewPermission: false,
      canSettingsPermission: false,
      isAdminRole: false,
      isHeadOfDepartment: false,
    );
    // Кнопка раздела только у absence.index. Остальные права её не открывают.
    expect(withoutIndex.showMenu, isFalse);
    expect(withIndex.showMenu, isTrue);
    expect(withIndex.showTeam, isFalse);
    expect(AbsenceAccess.none.showMenu, isFalse);
  });
}
