import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Individual user performance data
class UserPerformance {
  final String name;
  final int userId;
  final double finishedTasksPercent;
  final String status; // best, good, requires_attention, bad

  UserPerformance({
    required this.name,
    required this.userId,
    required this.finishedTasksPercent,
    required this.status,
  });

  factory UserPerformance.fromJson(Map<String, dynamic> json) {
    return UserPerformance(
      name: SafeConverters.toSafeString(json['name']),
      userId: SafeConverters.toInt(json['user_id']),
      finishedTasksPercent:
          SafeConverters.toDouble(json['finishedTasksprocent']),
      status: SafeConverters.toSafeString(json['status'],
          defaultValue: 'requires_attention'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'user_id': userId,
      'finishedTasksprocent': finishedTasksPercent,
      'status': status,
    };
  }

  bool get isBest => status == 'best';
  bool get isGood => status == 'good';
  bool get requiresAttention => status == 'requires_attention';
  bool get isBad => status == 'bad';

  String get statusDisplayName {
    switch (status) {
      case 'best':
        return 'Отлично';
      case 'good':
        return 'Хорошо';
      case 'requires_attention':
        return 'Требует внимания';
      case 'bad':
        return 'Плохо';
      default:
        return 'Неизвестно';
    }
  }
}

/// Pagination info for users chart
class UsersPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  UsersPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory UsersPagination.fromJson(Map<String, dynamic> json) {
    return UsersPagination(
      total: SafeConverters.toInt(json['total']),
      perPage: SafeConverters.toInt(json['per_page']),
      currentPage: SafeConverters.toInt(json['current_page']),
      lastPage: SafeConverters.toInt(json['last_page']),
      from: SafeConverters.toInt(json['from']),
      to: SafeConverters.toInt(json['to']),
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}

/// Model for users chart from /api/v2/dashboard/users-chart
/// Response: {result: {users: [...], average_kpi: 48, requires_attention_count: 12, pagination: {...}}}
class UsersChartResponse {
  final List<UserPerformance> users;
  final int averageKpi;
  final int requiresAttentionCount;
  final UsersPagination? pagination;

  UsersChartResponse({
    required this.users,
    required this.averageKpi,
    required this.requiresAttentionCount,
    this.pagination,
  });

  factory UsersChartResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];

    if (result is Map<String, dynamic>) {
      final usersData = result['users'];
      final users = usersData is List
          ? usersData.map((e) => UserPerformance.fromJson(e)).toList()
          : <UserPerformance>[];

      final paginationData = result['pagination'];
      final pagination = paginationData is Map<String, dynamic>
          ? UsersPagination.fromJson(paginationData)
          : null;

      return UsersChartResponse(
        users: users,
        averageKpi: SafeConverters.toInt(result['average_kpi']),
        requiresAttentionCount:
            SafeConverters.toInt(result['requires_attention_count']),
        pagination: pagination,
      );
    }

    // Return empty data if parsing fails
    return UsersChartResponse(
      users: [],
      averageKpi: 0,
      requiresAttentionCount: 0,
    );
  }

  List<UserPerformance> get topPerformers {
    return users.where((u) => u.isBest || u.isGood).toList();
  }

  List<UserPerformance> get needsAttention {
    return users.where((u) => u.requiresAttention || u.isBad).toList();
  }

  double get averagePerformance {
    if (users.isEmpty) return 0.0;
    final sum = users.fold(0.0, (sum, user) => sum + user.finishedTasksPercent);
    return sum / users.length;
  }
}
