// models/dashboard_model.dart
// dashboard_model.dart
class ChartData {
  final String label;
  final List<double> data;
  final String color;

  ChartData({
    required this.label,
    required this.data,
    required this.color,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label'] ?? json['status'] ?? '',
      data: List<double>.from(json['data'].map((x) => x.toDouble())),
      color: json['color'] ?? '#000000',
    );
  }
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
    final result = json['result'] as List;
    
    final leadData = result.firstWhere((e) => e['name'] == 'Lead')['datas'][0];
    final dealData = result.firstWhere((e) => e['name'] == 'Deals')['datas'][0];
    final taskData = result.firstWhere((e) => e['name'] == 'Tasks')['datas'][0];

    return DashboardStats(
      leadStats: LeadStats(
        unknown: leadData['unknownLeads'],
        atWork: leadData['atWorkLeads'],
        finished: leadData['finishedLeads'],
      ),
      dealStats: DealStats(
        finished: dealData['finishedDeals'],
      ),
      taskStats: TaskStats(
        all: taskData['allTasks'],
        outDated: taskData['outDatedTasks'],
        finished: taskData['finishedTasks'],
      ),
    );
  }
}

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

class DealStats {
  final int finished;

  DealStats({required this.finished});
}

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