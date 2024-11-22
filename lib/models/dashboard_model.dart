// ChartData модель
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
      data: (json['data'] as List<dynamic>)
          .map((x) => (x as num).toDouble())
          .toList(),
      color: json['color'] ?? '#000000',
    );
  }
}

 class LeadConversion {
  final List<double> data;

  LeadConversion({
    required this.data,
  });

  factory LeadConversion.fromJson(Map<String, dynamic> json) {
    print('LeadConversion.fromJson вызван');
    print('Входящий JSON: $json');
    
    // Получаем данные из поля 'result' и проверяем, что 'data' не null
    final result = json['result'] as Map<String, dynamic>? ?? {};
    print('Результат извлечения result: $result');
    
    final data = result['data'] as List<dynamic>? ?? [];
    print('Извлеченные данные: $data');

    // Преобразуем список в список чисел с типом double
    final convertedData = data.map((x) => (x as num).toDouble()).toList();
    print('Преобразованные данные: $convertedData');

    return LeadConversion(
      data: convertedData,
    );
  }
}


// DashboardStats модель
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
    final result = json['result'] as List<dynamic>? ?? [];
    final leadData = result.firstWhere(
      (e) => e['name'] == 'Lead',
      orElse: () => {'datas': [{}]},
    )['datas'][0] as Map<String, dynamic>? ?? {};
    final dealData = result.firstWhere(
      (e) => e['name'] == 'Deals',
      orElse: () => {'datas': [{}]},
    )['datas'][0] as Map<String, dynamic>? ?? {};
    final taskData = result.firstWhere(
      (e) => e['name'] == 'Tasks',
      orElse: () => {'datas': [{}]},
    )['datas'][0] as Map<String, dynamic>? ?? {};

    return DashboardStats(
      leadStats: LeadStats(
        unknown: leadData['unknownLeads'] as int? ?? 0,
        atWork: leadData['atWorkLeads'] as int? ?? 0,
        finished: leadData['finishedLeads'] as int? ?? 0,
      ),
      dealStats: DealStats(
        finished: dealData['finishedDeals'] as int? ?? 0,
      ),
      taskStats: TaskStats(
        all: taskData['allTasks'] as int? ?? 0,
        outDated: taskData['outDatedTasks'] as int? ?? 0,
        finished: taskData['finishedTasks'] as int? ?? 0,
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
