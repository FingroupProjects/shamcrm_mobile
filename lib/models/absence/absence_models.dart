import 'dart:convert';

import 'package:crm_task_manager/utils/safe_converters.dart';

/// Заявка на отсутствие. Тип берём из поля `type`, а не из равенства дат.
class AbsenceRequest {
  const AbsenceRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.typeLabel,
    required this.dateFrom,
    required this.dateTo,
    required this.reason,
    required this.status,
    required this.statusLabel,
    this.timeFrom,
    this.timeTo,
    this.authorId,
    this.authorName,
    this.reviewedAt,
    this.rejectionReason,
    this.createdAt,
    this.limitWarning,
  });

  final int id;
  final int userId;
  final String userName;
  final String type;
  final String typeLabel;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String? timeFrom;
  final String? timeTo;
  final String reason;
  final String status;
  final String statusLabel;
  final int? authorId;
  final String? authorName;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final AbsenceLimitWarning? limitWarning;

  bool get isPending => status == 'pending';
  bool get isPartial => type == 'partial';

  factory AbsenceRequest.fromJson(Map<String, dynamic> json) {
    final source = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final user = source['user'] is Map
        ? Map<String, dynamic>.from(source['user'] as Map)
        : null;
    final warning = AbsenceLimitWarning.tryParse(source['limit_warning']);

    return AbsenceRequest(
      id: SafeConverters.toInt(source['id']),
      userId: SafeConverters.toInt(
        source['user_id'] ?? user?['id'],
      ),
      userName: _readUserName(source, user),
      type: SafeConverters.toSafeString(source['type']),
      typeLabel: SafeConverters.toSafeString(source['type_label']),
      dateFrom: parseAbsenceDate(source['date_from']) ?? DateTime(1970),
      dateTo: parseAbsenceDate(source['date_to']) ??
          parseAbsenceDate(source['date_from']) ??
          DateTime(1970),
      timeFrom: normalizeAbsenceTime(source['time_from']),
      timeTo: normalizeAbsenceTime(source['time_to']),
      reason: SafeConverters.toSafeString(source['reason']),
      status: SafeConverters.toSafeString(source['status']),
      statusLabel: SafeConverters.toSafeString(source['status_label']),
      authorId: SafeConverters.toIntOrNull(source['author_id']),
      authorName: SafeConverters.toStringOrNull(source['author_name']),
      reviewedAt: parseAbsenceDateTime(source['reviewed_at']),
      rejectionReason: SafeConverters.toStringOrNull(source['rejection_reason']),
      createdAt: parseAbsenceDateTime(source['created_at']),
      limitWarning: warning,
    );
  }
}

/// Предупреждение о лимите приходит с бэкенда. На клиенте лимит не считаем.
class AbsenceLimitWarning {
  const AbsenceLimitWarning({
    required this.message,
    this.approved,
    this.limit,
  });

  final String message;
  final int? approved;
  final int? limit;

  static AbsenceLimitWarning? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final message = SafeConverters.toSafeString(raw['message']).trim();
    if (message.isEmpty) return null;
    return AbsenceLimitWarning(
      message: message,
      approved: SafeConverters.toIntOrNull(raw['approved']),
      limit: SafeConverters.toIntOrNull(raw['limit']),
    );
  }
}

class AbsencePage {
  const AbsencePage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.total,
  });

  final List<AbsenceRequest> items;
  final int currentPage;
  final int totalPages;
  final int total;

  bool get hasMore => currentPage < totalPages;
}

class AbsenceStats {
  const AbsenceStats({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.cancelled,
  });

  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int cancelled;

  static const empty = AbsenceStats(
    total: 0,
    pending: 0,
    approved: 0,
    rejected: 0,
    cancelled: 0,
  );
}

/// Пустое значение лимита — это null (лимита нет). Ноль — тип одобрять нельзя.
class AbsenceSettings {
  const AbsenceSettings({this.fullDayLimit, this.partialLimit});

  final int? fullDayLimit;
  final int? partialLimit;
}

/// Кто что видит. Администратор свои заявки не подаёт.
class AbsenceAccess {
  const AbsenceAccess({
    required this.userId,
    this.canIndexPermission = false,
    this.canReadPermission = false,
    required this.canCreatePermission,
    required this.canReviewPermission,
    required this.canSettingsPermission,
    required this.isAdminRole,
    required this.isHeadOfDepartment,
  });

  final int? userId;
  /// Право `absence.index` из списка permissions. Без него раздела нет.
  final bool canIndexPermission;
  final bool canReadPermission;
  final bool canCreatePermission;
  final bool canReviewPermission;
  final bool canSettingsPermission;
  final bool isAdminRole;
  final bool isHeadOfDepartment;

  bool get isAdmin => isAdminRole || canSettingsPermission;

  /// Чужие заявки: право review, руководитель отдела или администратор.
  bool get showTeam =>
      canReviewPermission || isHeadOfDepartment || isAdmin;

  /// Создать может тот, у кого есть право, кроме роли администратора.
  bool get canSubmit => !isAdminRole && (canCreatePermission || isHeadOfDepartment);

  /// «Мои заявки» нет у администратора. Есть у сотрудника и тимлида со своими правами.
  bool get showMy =>
      !isAdminRole &&
      (canCreatePermission || canReadPermission || isHeadOfDepartment);

  /// Кнопка в меню и вход в раздел. Только `absence.index`, не роль и не другие права.
  bool get showMenu => canIndexPermission;

  bool get showSettings => isAdmin;

  static const none = AbsenceAccess(
    userId: null,
    canCreatePermission: false,
    canReviewPermission: false,
    canSettingsPermission: false,
    isAdminRole: false,
    isHeadOfDepartment: false,
  );
}

class AbsenceApiException implements Exception {
  const AbsenceApiException({
    required this.statusCode,
    required this.message,
    this.fieldErrors = const {},
    this.network = false,
  });

  final int statusCode;
  final String message;
  final Map<String, String> fieldErrors;
  final bool network;

  bool get isUnavailable => statusCode == 403 || statusCode == 404;

  @override
  String toString() => message;
}

/// Фильтры списка. Даты фильтруют период отсутствия, не дату подачи.
class AbsenceFilters {
  const AbsenceFilters({
    this.userIds = const [],
    this.userNames = const {},
    this.status,
    this.dateFrom,
    this.dateTo,
  });

  final List<int> userIds;
  final Map<int, String> userNames;
  final String? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  static const empty = AbsenceFilters();

  int get activeCount {
    var count = 0;
    if (userIds.isNotEmpty) count++;
    if (status != null && status!.isNotEmpty) count++;
    if (dateFrom != null) count++;
    if (dateTo != null) count++;
    return count;
  }

  bool get hasAny => activeCount > 0;

  AbsenceFilters copyWith({
    List<int>? userIds,
    Map<int, String>? userNames,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearStatus = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return AbsenceFilters(
      userIds: userIds ?? this.userIds,
      userNames: userNames ?? this.userNames,
      status: clearStatus ? null : (status ?? this.status),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }
}

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime? parseAbsenceDate(dynamic raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  if (text.isEmpty) return null;
  final datePart = text.split(' ').first.split('T').first;
  final parts = datePart.split('-');
  if (parts.length == 3) {
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }
  final parsed = DateTime.tryParse(text.replaceFirst(' ', 'T'));
  if (parsed == null) return null;
  return dateOnly(parsed);
}

DateTime? parseAbsenceDateTime(dynamic raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst(' ', 'T'));
}

String? normalizeAbsenceTime(dynamic raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  final parts = text.split(':');
  if (parts.length < 2) return text;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return text;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String formatAbsenceApiDate(DateTime value) {
  final day = dateOnly(value);
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}

String formatAbsenceDisplayDate(DateTime value) {
  final day = dateOnly(value);
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '$date.$month.${day.year}';
}

String formatAbsenceDisplayDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${formatAbsenceDisplayDate(value)} $hour:$minute';
}

String _readUserName(Map<String, dynamic> source, Map<String, dynamic>? user) {
  final direct = SafeConverters.toStringOrNull(source['user_name']);
  if (direct != null && direct.trim().isNotEmpty) return direct.trim();
  if (user == null) return '';
  final full = SafeConverters.toStringOrNull(user['full_name']) ??
      SafeConverters.toStringOrNull(user['fullname']);
  if (full != null && full.trim().isNotEmpty) return full.trim();
  final name = SafeConverters.toSafeString(user['name']);
  final lastName = SafeConverters.toSafeString(
    user['lastname'] ?? user['last_name'],
  );
  return '$name $lastName'.trim();
}

AbsencePage parseAbsencePage(dynamic decoded) {
  final root = decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  final result = root['result'];
  List<dynamic> items = const [];
  Map<String, dynamic> pagination = {};

  if (result is Map && result['data'] is List) {
    items = List<dynamic>.from(result['data'] as List);
    final rawPagination = result['pagination'];
    pagination = rawPagination is Map
        ? Map<String, dynamic>.from(rawPagination)
        : Map<String, dynamic>.from(result);
  } else if (result is List) {
    items = List<dynamic>.from(result);
  } else if (root['data'] is List) {
    items = List<dynamic>.from(root['data'] as List);
    if (root['pagination'] is Map) {
      pagination = Map<String, dynamic>.from(root['pagination'] as Map);
    }
  }

  final requests = <AbsenceRequest>[];
  for (final item in items) {
    if (item is Map) {
      requests.add(AbsenceRequest.fromJson(Map<String, dynamic>.from(item)));
    }
  }

  final current = SafeConverters.toInt(
    pagination['current_page'],
    defaultValue: 1,
  );
  final perPage = SafeConverters.toInt(pagination['per_page'], defaultValue: 20);
  final total = SafeConverters.toInt(pagination['total']);
  var pages = SafeConverters.toInt(pagination['total_pages']);
  if (pages < 1) {
    pages = perPage <= 0 ? 1 : (total / perPage).ceil();
  }
  if (pages < 1) pages = 1;

  return AbsencePage(
    items: requests,
    currentPage: current < 1 ? 1 : current,
    totalPages: pages,
    total: total,
  );
}

/// `total` учитывает все фильтры, включая статус.
/// `by_status` от фильтра статуса не зависит — это считает бэкенд.
AbsenceStats parseAbsenceStats(dynamic decoded) {
  final root = decoded is Map
      ? Map<String, dynamic>.from(decoded)
      : <String, dynamic>{};
  final result = root['result'];
  final source = result is Map
      ? Map<String, dynamic>.from(result)
      : root;
  final byStatus = source['by_status'] is Map
      ? Map<String, dynamic>.from(source['by_status'] as Map)
      : source;

  return AbsenceStats(
    total: SafeConverters.toInt(source['total']),
    pending: SafeConverters.toInt(byStatus['pending'] ?? source['pending']),
    approved: SafeConverters.toInt(byStatus['approved'] ?? source['approved']),
    rejected: SafeConverters.toInt(byStatus['rejected'] ?? source['rejected']),
    cancelled:
        SafeConverters.toInt(byStatus['cancelled'] ?? source['cancelled']),
  );
}

AbsenceSettings parseAbsenceSettings(dynamic decoded) {
  final root = decoded is Map
      ? Map<String, dynamic>.from(decoded)
      : <String, dynamic>{};
  final result = root['result'];
  final source = result is Map
      ? Map<String, dynamic>.from(result)
      : root;
  return AbsenceSettings(
    fullDayLimit: _nullableLimit(source, 'full_day_limit'),
    partialLimit: _nullableLimit(source, 'partial_limit'),
  );
}

int? _nullableLimit(Map<String, dynamic> source, String key) {
  if (!source.containsKey(key) || source[key] == null) return null;
  return SafeConverters.toIntOrNull(source[key]);
}

AbsenceRequest? parseAbsenceRequestPayload(dynamic decoded) {
  if (decoded is! Map) return null;
  final root = Map<String, dynamic>.from(decoded);
  final result = root['result'];
  if (result is Map && (result['id'] != null || result['data'] is Map)) {
    return AbsenceRequest.fromJson(Map<String, dynamic>.from(result));
  }
  if (root['id'] != null) {
    return AbsenceRequest.fromJson(root);
  }
  return null;
}

AbsenceApiException absenceErrorFromBody({
  required int statusCode,
  required String body,
}) {
  dynamic decoded;
  try {
    decoded = body.trim().isEmpty ? null : jsonDecode(body);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) {
    return AbsenceApiException(
      statusCode: statusCode,
      message: body.trim(),
    );
  }
  return absenceErrorFromDecoded(statusCode: statusCode, decoded: decoded);
}

AbsenceApiException absenceErrorFromDecoded({
  required int statusCode,
  required dynamic decoded,
}) {
  var message = '';
  final fields = <String, String>{};
  if (decoded is Map) {
    final errors = decoded['errors'];
    if (errors is Map) {
      errors.forEach((key, value) {
        final text = _flattenError(value);
        if (text.isEmpty) return;
        fields[key.toString()] = text;
      });
      message = fields.values.join('\n');
    } else {
      message = _flattenError(errors);
    }
    if (message.isEmpty) {
      message = _flattenError(decoded['message'] ?? decoded['error']);
    }
  } else if (decoded is String) {
    message = decoded.trim();
  }

  return AbsenceApiException(
    statusCode: statusCode,
    message: message,
    fieldErrors: fields,
  );
}

String _flattenError(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is List) {
    return value.map(_flattenError).where((item) => item.isNotEmpty).join('\n');
  }
  if (value is Map) {
    return value.values
        .map(_flattenError)
        .where((item) => item.isNotEmpty)
        .join('\n');
  }
  return value.toString().trim();
}
