import 'package:crm_task_manager/models/absence/absence_models.dart';

/// Черновик формы. Время необязательно, но только оба поля сразу.
class AbsenceDraft {
  const AbsenceDraft({
    this.dateFrom,
    this.dateTo,
    this.timeFrom,
    this.timeTo,
    this.reason = '',
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? timeFrom;
  final String? timeTo;
  final String reason;

  bool sameAs(AbsenceDraft other) {
    return _sameDate(dateFrom, other.dateFrom) &&
        _sameDate(dateTo, other.dateTo) &&
        _blank(timeFrom) == _blank(other.timeFrom) &&
        _blank(timeTo) == _blank(other.timeTo) &&
        reason.trim() == other.reason.trim();
  }
}

class AbsenceFormErrors {
  const AbsenceFormErrors([this.fields = const {}]);

  final Map<String, String> fields;

  bool get isEmpty => fields.isEmpty;

  String? operator [](String key) => fields[key];
}

/// Тексты ошибок — ключи локализации. Они дублируют проверки бэкенда.
AbsenceFormErrors validateAbsenceDraft(
  AbsenceDraft draft, {
  required DateTime today,
  bool allowPast = false,
}) {
  final errors = <String, String>{};
  final from = draft.dateFrom == null ? null : dateOnly(draft.dateFrom!);
  var to = draft.dateTo == null ? null : dateOnly(draft.dateTo!);
  final timeFrom = _blank(draft.timeFrom);
  final timeTo = _blank(draft.timeTo);
  final bothTimes = timeFrom != null && timeTo != null;

  // Если время указано, заявка всегда на один день.
  if (bothTimes) to = from;

  if (from == null || to == null) {
    errors['date_from'] = 'absence_err_dates';
  } else if (to.isBefore(from)) {
    errors['date_to'] = 'absence_err_date_order';
  } else if (!allowPast && from.isBefore(dateOnly(today))) {
    errors['date_from'] = 'absence_err_past';
  }

  if (draft.reason.trim().isEmpty) {
    errors['reason'] = 'absence_err_reason';
  }

  if ((timeFrom == null) != (timeTo == null)) {
    errors['time_from'] = 'absence_err_time_pair';
  } else if (bothTimes && !absenceTimeIsAfter(timeFrom, timeTo)) {
    errors['time_to'] = 'absence_err_time_order';
  }

  return AbsenceFormErrors(errors);
}

/// Тело POST/PUT. Пустое время не отправляем: бэкенд сам ставит full_day.
Map<String, dynamic> absenceRequestBody(AbsenceDraft draft) {
  final from = draft.dateFrom!;
  final timeFrom = _blank(draft.timeFrom);
  final timeTo = _blank(draft.timeTo);
  final bothTimes = timeFrom != null && timeTo != null;
  final to = bothTimes ? from : draft.dateTo!;
  final body = <String, dynamic>{
    'date_from': formatAbsenceApiDate(from),
    'date_to': formatAbsenceApiDate(to),
    'reason': draft.reason.trim(),
  };
  if (bothTimes) {
    body['time_from'] = timeFrom;
    body['time_to'] = timeTo;
  }
  return body;
}

/// Пустая строка уходит как null. Ноль остаётся нулём.
Map<String, dynamic> absenceSettingsBody({
  required String fullDay,
  required String partial,
}) {
  return {
    'full_day_limit': _parseLimit(fullDay),
    'partial_limit': _parseLimit(partial),
  };
}

int? _parseLimit(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final value = int.tryParse(text);
  if (value == null || value < 0) {
    throw const FormatException('absence_err_limits');
  }
  return value;
}

/// Полные сутки: компании работают в разное время, поэтому не режем день.
/// Шаг 30 минут, последняя точка — 24:00.
List<String> absenceTimeOptions({String? extra}) {
  final options = <String>[];
  for (var minutes = 0; minutes <= 24 * 60; minutes += 30) {
    if (minutes == 24 * 60) {
      options.add('24:00');
      break;
    }
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    options.add('$hour:$minute');
  }
  final normalized = normalizeAbsenceTime(extra);
  if (normalized != null && !options.contains(normalized)) {
    options
      ..add(normalized)
      ..sort();
  }
  return options;
}

bool absenceTimeIsAfter(String from, String to) {
  final start = _minutes(from);
  final end = _minutes(to);
  if (start == null || end == null) return false;
  return end > start;
}

int? _minutes(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}

String formatAbsencePeriod(DateTime from, DateTime to) {
  final start = formatAbsenceDisplayDate(from);
  final end = formatAbsenceDisplayDate(to);
  if (start == end) return start;
  return '$start — $end';
}

int absenceDayCount(DateTime from, DateTime to) {
  final days = dateOnly(to).difference(dateOnly(from)).inDays + 1;
  return days < 1 ? 1 : days;
}

String formatAbsenceClock(String? from, String? to) {
  final start = normalizeAbsenceTime(from);
  final end = normalizeAbsenceTime(to);
  if (start == null || end == null) return '';
  return '$start–$end';
}

/// Свои pending с датой начала не в прошлом. Администратор чужие и свои не правит.
bool canEditAbsence({
  required AbsenceAccess access,
  required AbsenceRequest request,
}) {
  if (access.userId == null || request.userId != access.userId) return false;
  return request.isPending;
}

/// Руководитель не рассматривает свою заявку. Администратор решает любую.
bool canDecideAbsence({
  required AbsenceAccess access,
  required AbsenceRequest request,
}) {
  if (!request.isPending) return false;
  if (access.isAdmin) return true;
  if (access.userId == null) return false;
  return request.userId != access.userId;
}

String absenceListPath({
  required bool mine,
  required int page,
  required AbsenceFilters filters,
  int perPage = 20,
}) {
  return _absencePath(
    mine ? '/absence-requests/mine' : '/absence-requests',
    page: page,
    perPage: perPage,
    filters: filters,
    includeUsers: !mine,
  );
}

String absenceStatsPath(AbsenceFilters filters) {
  return _absencePath(
    '/absence-requests/stats',
    filters: filters,
    includeUsers: true,
  );
}

String absenceExportPath(AbsenceFilters filters) {
  return _absencePath(
    '/absence-requests/export',
    filters: filters,
    includeUsers: true,
  );
}

String _absencePath(
  String path, {
  int? page,
  int? perPage,
  required AbsenceFilters filters,
  required bool includeUsers,
}) {
  final params = <String, String>{};
  if (page != null) params['page'] = '$page';
  if (perPage != null) params['per_page'] = '$perPage';
  final status = filters.status?.trim();
  if (status != null && status.isNotEmpty) params['status'] = status;
  if (filters.dateFrom != null) {
    params['date_from'] = formatAbsenceApiDate(filters.dateFrom!);
  }
  if (filters.dateTo != null) {
    params['date_to'] = formatAbsenceApiDate(filters.dateTo!);
  }
  if (includeUsers && filters.userIds.isNotEmpty) {
    params['user_ids'] = filters.userIds.join(',');
  }
  if (params.isEmpty) return path;
  final query = params.entries
      .map((entry) =>
          '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
      .join('&');
  return '$path?$query';
}

/// `head_of_department` может лежать на отделе или во вложенном pivot.
bool absenceJsonIsHead(dynamic node) {
  if (node is Map) {
    for (final entry in node.entries) {
      final key = entry.key.toString().toLowerCase();
      if (_headKeys.contains(key) && _isTruthy(entry.value)) return true;
    }
    for (final value in node.values) {
      if (absenceJsonIsHead(value)) return true;
    }
  } else if (node is List) {
    for (final item in node) {
      if (absenceJsonIsHead(item)) return true;
    }
  }
  return false;
}

const _headKeys = {
  'head_of_department',
  'is_head_of_department',
  'is_head',
};

bool _isTruthy(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  if (value is String) {
    final text = value.trim().toLowerCase();
    return text == '1' || text == 'true' || text == 'yes';
  }
  return false;
}

String? _blank(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return normalizeAbsenceTime(text) ?? text;
}

bool _sameDate(DateTime? a, DateTime? b) {
  if (a == null || b == null) return a == null && b == null;
  return dateOnly(a) == dateOnly(b);
}

String absenceStatusLabelKey(String status) {
  switch (status) {
    case 'pending':
      return 'absence_status_pending';
    case 'approved':
      return 'absence_status_approved';
    case 'rejected':
      return 'absence_status_rejected';
    case 'cancelled':
      return 'absence_status_cancelled';
    default:
      return '';
  }
}

String absenceTypeLabelKey(String type) {
  switch (type) {
    case 'partial':
      return 'absence_type_partial';
    case 'full_day':
      return 'absence_type_full_day';
    default:
      return '';
  }
}
