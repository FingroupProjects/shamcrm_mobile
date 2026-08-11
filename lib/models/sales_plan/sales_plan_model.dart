import 'package:crm_task_manager/utils/safe_converters.dart';

enum SalesPlanType {
  sum,
  count;

  static SalesPlanType fromString(String? value) {
    switch (value) {
      case 'sum':
        return SalesPlanType.sum;
      case 'count':
        return SalesPlanType.count;
      default:
        return SalesPlanType.count;
    }
  }

  String get apiValue => name;
}

enum SalesPlanObjectType {
  deals,
  leads,
  calls,
  tasks,
  notices;

  static SalesPlanObjectType fromString(String? value) {
    switch (value) {
      case 'deals':
        return SalesPlanObjectType.deals;
      case 'leads':
        return SalesPlanObjectType.leads;
      case 'calls':
        return SalesPlanObjectType.calls;
      case 'tasks':
        return SalesPlanObjectType.tasks;
      case 'notices':
        return SalesPlanObjectType.notices;
      default:
        return SalesPlanObjectType.deals;
    }
  }

  String get apiValue => name;
}

enum SalesPlanAggregation {
  count,
  sumField,
  avgField;

  static SalesPlanAggregation fromString(String? value) {
    switch (value) {
      case 'sum_field':
        return SalesPlanAggregation.sumField;
      case 'avg_field':
        return SalesPlanAggregation.avgField;
      case 'count':
      default:
        return SalesPlanAggregation.count;
    }
  }

  String get apiValue {
    switch (this) {
      case SalesPlanAggregation.count:
        return 'count';
      case SalesPlanAggregation.sumField:
        return 'sum_field';
      case SalesPlanAggregation.avgField:
        return 'avg_field';
    }
  }
}

enum SalesPlanPeriodType {
  day,
  week,
  month,
  quarter,
  year;

  static SalesPlanPeriodType fromString(String? value) {
    switch (value) {
      case 'day':
        return SalesPlanPeriodType.day;
      case 'week':
        return SalesPlanPeriodType.week;
      case 'quarter':
        return SalesPlanPeriodType.quarter;
      case 'year':
        return SalesPlanPeriodType.year;
      case 'month':
      default:
        return SalesPlanPeriodType.month;
    }
  }

  String get apiValue => name;
}

enum SalesPlanRecurrence {
  once,
  daily,
  monthly,
  quarterly,
  yearly;

  static SalesPlanRecurrence fromString(String? value) {
    switch (value) {
      case 'daily':
        return SalesPlanRecurrence.daily;
      case 'monthly':
        return SalesPlanRecurrence.monthly;
      case 'quarterly':
        return SalesPlanRecurrence.quarterly;
      case 'yearly':
        return SalesPlanRecurrence.yearly;
      case 'once':
      default:
        return SalesPlanRecurrence.once;
    }
  }

  String get apiValue => name;
}

enum SalesPlanStatus {
  active,
  completed,
  overachieved,
  overdue;

  static SalesPlanStatus fromString(String? value) {
    switch (value) {
      case 'completed':
        return SalesPlanStatus.completed;
      case 'overachieved':
        return SalesPlanStatus.overachieved;
      case 'overdue':
        return SalesPlanStatus.overdue;
      case 'active':
      default:
        return SalesPlanStatus.active;
    }
  }

  String get apiValue => name;
}

class SalesPlanUser {
  final int id;
  final String name;
  final String? lastname;
  final String? fullName;
  final double? actualValue;
  final double? percent;

  SalesPlanUser({
    required this.id,
    required this.name,
    this.lastname,
    this.fullName,
    this.actualValue,
    this.percent,
  });

  factory SalesPlanUser.fromJson(Map<String, dynamic> json) {
    final name = SafeConverters.toSafeString(json['name']);
    final lastname = SafeConverters.toStringOrNull(json['lastname']);
    final fullName = SafeConverters.toStringOrNull(json['full_name']) ??
        [name, lastname].where((e) => e != null && e.isNotEmpty).join(' ');
    return SalesPlanUser(
      id: SafeConverters.toInt(json['id']),
      name: name,
      lastname: lastname,
      fullName: fullName.isEmpty ? name : fullName,
      actualValue: SafeConverters.toDoubleOrNull(json['actual_value']),
      percent: SafeConverters.toDoubleOrNull(json['percent']),
    );
  }

  String get displayName =>
      (fullName != null && fullName!.isNotEmpty) ? fullName! : name;
}

/// Unwraps API envelopes: `{result:{data,pagination}}`, `{data,meta}`, etc.
Map<String, dynamic> unwrapSalesPlanPayload(Map<String, dynamic> json) {
  final result = json['result'];
  if (result is Map) {
    return Map<String, dynamic>.from(result);
  }
  return json;
}

List<dynamic>? extractSalesPlanList(Map<String, dynamic> json) {
  final payload = unwrapSalesPlanPayload(json);
  final data = payload['data'];
  if (data is List) return data;
  return null;
}

Map<String, dynamic> extractSalesPlanItem(Map<String, dynamic> json) {
  final payload = unwrapSalesPlanPayload(json);
  final data = payload['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is List && data.isNotEmpty && data.first is Map) {
    return Map<String, dynamic>.from(data.first as Map);
  }
  // Single-object detail may live directly under result.
  if (payload.containsKey('id') || payload.containsKey('name')) {
    return payload;
  }
  return payload;
}

Map<String, dynamic> extractSalesPlanPagination(Map<String, dynamic> json) {
  final payload = unwrapSalesPlanPayload(json);
  final pagination = payload['pagination'] ?? payload['meta'] ?? json['meta'];
  if (pagination is Map) return Map<String, dynamic>.from(pagination);
  return <String, dynamic>{};
}

class SalesPlanFilterItem {
  final String field;
  final String operator;
  final String value;
  final int? customFieldId;
  final int? directoryId;

  SalesPlanFilterItem({
    required this.field,
    this.operator = '=',
    required this.value,
    this.customFieldId,
    this.directoryId,
  });

  factory SalesPlanFilterItem.fromJson(Map<String, dynamic> json) {
    return SalesPlanFilterItem(
      field: SafeConverters.toSafeString(json['field']),
      operator: SafeConverters.toSafeString(json['operator'], defaultValue: '='),
      value: SafeConverters.toSafeString(json['value']),
      customFieldId: SafeConverters.toIntOrNull(json['custom_field_id']),
      directoryId: SafeConverters.toIntOrNull(json['directory_id']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'field': field,
      'operator': operator,
      'value': value,
    };
    if (customFieldId != null) map['custom_field_id'] = customFieldId;
    if (directoryId != null) map['directory_id'] = directoryId;
    return map;
  }
}

class SalesPlanCreator {
  final int id;
  final String name;

  SalesPlanCreator({required this.id, required this.name});

  factory SalesPlanCreator.fromJson(Map<String, dynamic> json) {
    return SalesPlanCreator(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
    );
  }
}

class SalesPlanChild {
  final int? id;
  final String name;
  final double? targetValue;
  final double? actualValue;
  final double? percent;

  SalesPlanChild({
    this.id,
    required this.name,
    this.targetValue,
    this.actualValue,
    this.percent,
  });

  factory SalesPlanChild.fromJson(Map<String, dynamic> json) {
    return SalesPlanChild(
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toSafeString(
        json['name'] ?? json['full_name'] ?? json['user_name'],
      ),
      targetValue: SafeConverters.toDoubleOrNull(json['target_value']),
      actualValue: SafeConverters.toDoubleOrNull(json['actual_value']),
      percent: SafeConverters.toDoubleOrNull(json['percent']),
    );
  }
}

class SalesPlan {
  final int id;
  final String name;
  final SalesPlanType planType;
  final SalesPlanObjectType objectType;
  final SalesPlanAggregation aggregation;
  final String? aggregationField;
  final double targetValue;
  final double actualValue;
  final double percent;
  final SalesPlanStatus status;
  final SalesPlanPeriodType periodType;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int? daysLeft;
  final int? daysTotal;
  final double? dailyAverage;
  final double? dailyNeed;
  final double? forecast;
  final double? forecastPercent;
  final SalesPlanRecurrence recurrence;
  final String? comment;
  final List<SalesPlanUser> users;
  final List<SalesPlanFilterItem> filters;
  final SalesPlanCreator? creator;
  final DateTime? createdAt;
  final List<SalesPlanChild> children;

  SalesPlan({
    required this.id,
    required this.name,
    required this.planType,
    required this.objectType,
    required this.aggregation,
    this.aggregationField,
    required this.targetValue,
    required this.actualValue,
    required this.percent,
    required this.status,
    required this.periodType,
    this.periodStart,
    this.periodEnd,
    this.daysLeft,
    this.daysTotal,
    this.dailyAverage,
    this.dailyNeed,
    this.forecast,
    this.forecastPercent,
    required this.recurrence,
    this.comment,
    this.users = const [],
    this.filters = const [],
    this.creator,
    this.createdAt,
    this.children = const [],
  });

  factory SalesPlan.fromJson(Map<String, dynamic> json) {
    final usersJson = json['users'];
    final filtersJson = json['filters'];
    final childrenJson = json['children'] ?? json['hierarchy'] ?? json['child_plans'];

    final users = SafeConverters.toList(usersJson)
        .map((e) => SalesPlanUser.fromJson(SafeConverters.toMap(e)))
        .toList();

    List<SalesPlanChild> children = SafeConverters.toList(childrenJson)
        .map((e) => SalesPlanChild.fromJson(SafeConverters.toMap(e)))
        .toList();

    if (children.isEmpty && users.any((u) => u.percent != null || u.actualValue != null)) {
      children = users
          .map((u) => SalesPlanChild(
                id: u.id,
                name: u.displayName,
                actualValue: u.actualValue,
                percent: u.percent,
              ))
          .toList();
    }

    return SalesPlan(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      planType: SalesPlanType.fromString(SafeConverters.toStringOrNull(json['plan_type'])),
      objectType: SalesPlanObjectType.fromString(SafeConverters.toStringOrNull(json['object_type'])),
      aggregation: SalesPlanAggregation.fromString(SafeConverters.toStringOrNull(json['aggregation'])),
      aggregationField: SafeConverters.toStringOrNull(json['aggregation_field']),
      targetValue: SafeConverters.toDoubleOrNull(json['target_value']) ?? 0,
      actualValue: SafeConverters.toDoubleOrNull(json['actual_value']) ?? 0,
      percent: SafeConverters.toDoubleOrNull(json['percent']) ?? 0,
      status: SalesPlanStatus.fromString(SafeConverters.toStringOrNull(json['status'])),
      periodType: SalesPlanPeriodType.fromString(SafeConverters.toStringOrNull(json['period_type'])),
      periodStart: SafeConverters.toDateTimeOrNull(json['period_start']),
      periodEnd: SafeConverters.toDateTimeOrNull(json['period_end']),
      daysLeft: SafeConverters.toIntOrNull(json['days_left']),
      daysTotal: SafeConverters.toIntOrNull(json['days_total']),
      dailyAverage: SafeConverters.toDoubleOrNull(json['daily_average']),
      dailyNeed: SafeConverters.toDoubleOrNull(json['daily_need']),
      forecast: SafeConverters.toDoubleOrNull(json['forecast']),
      forecastPercent: SafeConverters.toDoubleOrNull(json['forecast_percent']),
      recurrence: SalesPlanRecurrence.fromString(SafeConverters.toStringOrNull(json['recurrence'])),
      comment: SafeConverters.toStringOrNull(json['comment']),
      users: users,
      filters: SafeConverters.toList(filtersJson)
          .map((e) => SalesPlanFilterItem.fromJson(SafeConverters.toMap(e)))
          .toList(),
      creator: SafeConverters.toMapOrNull(json['creator']) != null
          ? SalesPlanCreator.fromJson(SafeConverters.toMap(json['creator']))
          : null,
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      children: children,
    );
  }

  String get ownersLabel {
    if (users.isEmpty) return '—';
    if (users.length == 1) return users.first.displayName;
    return '${users.first.displayName} +${users.length - 1}';
  }

  bool get isDailyRecurring =>
      periodType == SalesPlanPeriodType.day &&
      recurrence == SalesPlanRecurrence.daily;
}

class SalesPlanListResponse {
  final List<SalesPlan> data;
  final int currentPage;
  final int perPage;
  final int total;

  SalesPlanListResponse({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
  });

  factory SalesPlanListResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = extractSalesPlanList(json);
    final meta = extractSalesPlanPagination(json);
    return SalesPlanListResponse(
      data: dataJson != null
          ? SafeConverters.toList(dataJson)
              .map((e) => SalesPlan.fromJson(SafeConverters.toMap(e)))
              .toList()
          : const [],
      currentPage: SafeConverters.toInt(meta['current_page'], defaultValue: 1),
      perPage: SafeConverters.toInt(meta['per_page'], defaultValue: 20),
      total: SafeConverters.toInt(meta['total']),
    );
  }
}

class SalesPlanCreateRequest {
  final String name;
  final SalesPlanType planType;
  final SalesPlanObjectType objectType;
  final SalesPlanAggregation aggregation;
  final String? aggregationField;
  final double targetValue;
  final SalesPlanPeriodType periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final SalesPlanRecurrence recurrence;
  final List<int> userIds;
  final String? comment;
  final List<SalesPlanFilterItem> filters;
  final int? organizationId;
  final int? salesFunnelId;

  SalesPlanCreateRequest({
    required this.name,
    required this.planType,
    required this.objectType,
    required this.aggregation,
    this.aggregationField,
    required this.targetValue,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.recurrence,
    required this.userIds,
    this.comment,
    this.filters = const [],
    this.organizationId,
    this.salesFunnelId,
  });

  Map<String, dynamic> toJson({bool includeOrg = true}) {
    final map = <String, dynamic>{
      'name': name,
      'plan_type': planType.apiValue,
      'object_type': objectType.apiValue,
      'aggregation': aggregation.apiValue,
      'target_value': targetValue,
      'period_type': periodType.apiValue,
      'period_start': _formatDate(periodStart),
      'period_end': _formatDate(periodEnd),
      'recurrence': recurrence.apiValue,
      'user_ids': userIds,
      'filters': filters.map((e) => e.toJson()).toList(),
    };
    if (aggregationField != null && aggregationField!.isNotEmpty) {
      map['aggregation_field'] = aggregationField;
    }
    if (comment != null && comment!.isNotEmpty) {
      map['comment'] = comment;
    }
    if (includeOrg) {
      if (organizationId != null) map['organization_id'] = organizationId;
      if (salesFunnelId != null) map['sales_funnel_id'] = salesFunnelId;
    }
    return map;
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
