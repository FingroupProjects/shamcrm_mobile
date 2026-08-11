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
    final name = json['name']?.toString() ?? '';
    final lastname = json['lastname']?.toString();
    final fullName = json['full_name']?.toString() ??
        [name, lastname].where((e) => e != null && e.isNotEmpty).join(' ');
    return SalesPlanUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: name,
      lastname: lastname,
      fullName: fullName.isEmpty ? name : fullName,
      actualValue: _toDouble(json['actual_value']),
      percent: _toDouble(json['percent']),
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
      field: json['field']?.toString() ?? '',
      operator: json['operator']?.toString() ?? '=',
      value: json['value']?.toString() ?? '',
      customFieldId: json['custom_field_id'] is int
          ? json['custom_field_id'] as int
          : int.tryParse('${json['custom_field_id'] ?? ''}'),
      directoryId: json['directory_id'] is int
          ? json['directory_id'] as int
          : int.tryParse('${json['directory_id'] ?? ''}'),
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
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
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
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id'] ?? ''}'),
      name: json['name']?.toString() ??
          json['full_name']?.toString() ??
          json['user_name']?.toString() ??
          '',
      targetValue: _toDouble(json['target_value']),
      actualValue: _toDouble(json['actual_value']),
      percent: _toDouble(json['percent']),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
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

    final users = usersJson is List
        ? usersJson
            .whereType<Map>()
            .map((e) => SalesPlanUser.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <SalesPlanUser>[];

    List<SalesPlanChild> children = childrenJson is List
        ? childrenJson
            .whereType<Map>()
            .map((e) => SalesPlanChild.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <SalesPlanChild>[];

    // Backend often returns per-user fact/% inside users[] instead of children[].
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
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      planType: SalesPlanType.fromString(json['plan_type']?.toString()),
      objectType: SalesPlanObjectType.fromString(json['object_type']?.toString()),
      aggregation: SalesPlanAggregation.fromString(json['aggregation']?.toString()),
      aggregationField: json['aggregation_field']?.toString(),
      targetValue: _toDouble(json['target_value']) ?? 0,
      actualValue: _toDouble(json['actual_value']) ?? 0,
      percent: _toDouble(json['percent']) ?? 0,
      status: SalesPlanStatus.fromString(json['status']?.toString()),
      periodType: SalesPlanPeriodType.fromString(json['period_type']?.toString()),
      periodStart: _parseDate(json['period_start']),
      periodEnd: _parseDate(json['period_end']),
      daysLeft: json['days_left'] is int
          ? json['days_left'] as int
          : int.tryParse('${json['days_left'] ?? ''}'),
      daysTotal: json['days_total'] is int
          ? json['days_total'] as int
          : int.tryParse('${json['days_total'] ?? ''}'),
      dailyAverage: _toDouble(json['daily_average']),
      dailyNeed: _toDouble(json['daily_need']),
      forecast: _toDouble(json['forecast']),
      forecastPercent: _toDouble(json['forecast_percent']),
      recurrence: SalesPlanRecurrence.fromString(json['recurrence']?.toString()),
      comment: json['comment']?.toString(),
      users: users,
      filters: filtersJson is List
          ? filtersJson
              .whereType<Map>()
              .map((e) =>
                  SalesPlanFilterItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      creator: json['creator'] is Map
          ? SalesPlanCreator.fromJson(Map<String, dynamic>.from(json['creator']))
          : null,
      createdAt: _parseDate(json['created_at']),
      children: children,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
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
          ? dataJson
              .whereType<Map>()
              .map((e) => SalesPlan.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      currentPage: meta['current_page'] is int
          ? meta['current_page'] as int
          : int.tryParse('${meta['current_page'] ?? 1}') ?? 1,
      perPage: meta['per_page'] is int
          ? meta['per_page'] as int
          : int.tryParse('${meta['per_page'] ?? 20}') ?? 20,
      total: meta['total'] is int
          ? meta['total'] as int
          : int.tryParse('${meta['total'] ?? 0}') ?? 0,
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
