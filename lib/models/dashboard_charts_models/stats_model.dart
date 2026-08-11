import 'package:crm_task_manager/utils/safe_converters.dart';

// DashboardStats модель
Map<String, dynamic> _statsDataFor(List<dynamic> result, String name) {
  for (final item in result) {
    final map = SafeConverters.toMapOrNull(item);
    if (map != null && SafeConverters.toSafeString(map['name']) == name) {
      final datas = SafeConverters.toList(map['datas']);
      if (datas.isNotEmpty) {
        return SafeConverters.toMap(datas.first);
      }
      return {};
    }
  }
  return {};
}

class DashboardStats {
  final LeadStats leadStats;
  final DealStats dealStats;
  final TaskStats taskStats;

  DashboardStats({
    required this.leadStats,
    required this.dealStats,
    required this.taskStats,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final result = SafeConverters.toList(json['result']);
    final leadData = _statsDataFor(result, 'Lead');
    final dealData = _statsDataFor(result, 'Deals');
    final taskData = _statsDataFor(result, 'Tasks');

    return DashboardStats(
      leadStats: LeadStats(
        unknown: SafeConverters.toInt(leadData['unknownLeads']),
        atWork: SafeConverters.toInt(leadData['atWorkLeads']),
        finished: SafeConverters.toInt(leadData['finishedLeads']),
      ),
      dealStats: DealStats(
        finished: SafeConverters.toInt(dealData['finishedDeals']),
      ),
      taskStats: TaskStats(
        all: SafeConverters.toInt(taskData['allTasks']),
        outDated: SafeConverters.toInt(taskData['outDatedTasks']),
        finished: SafeConverters.toInt(taskData['finishedTasks']),
      ),
    );
  }
}

// LeadStats модель
class LeadStats {
  final int unknown;
  final int atWork;
  final int finished;

  LeadStats({
    required this.unknown,
    required this.atWork,
    required this.finished,
  });
}

// DealStats модель
class DealStats {
  final int finished;

  DealStats({required this.finished});
}

// TaskStats модель
class TaskStats {
  final int all;
  final int outDated;
  final int finished;

  TaskStats({
    required this.all,
    required this.outDated,
    required this.finished,
  });
}
