import 'dart:convert';

class MonthlyCallStats {
  final List<MonthlyCallStat> result;
  final String? errors;

  MonthlyCallStats({
    required this.result,
    this.errors,
  });

  factory MonthlyCallStats.fromJson(Map<String, dynamic> json) {
    var resultList = json['result'] as List;
    List<MonthlyCallStat> stats = resultList
        .map((item) => MonthlyCallStat.fromJson(item))
        .toList();

    return MonthlyCallStats(
      result: stats,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result.map((stat) => stat.toJson()).toList(),
      'errors': errors,
    };
  }
}

class MonthlyCallStat {
  final int month;
  final int incoming;
  final int outgoing;
  final int unanswered;
  final int missed;
  final int total;

  MonthlyCallStat({
    required this.month,
    required this.incoming,
    required this.outgoing,
    required this.unanswered,
    required this.missed,
    required this.total,
  });

  factory MonthlyCallStat.fromJson(Map<String, dynamic> json) {
    return MonthlyCallStat(
      month: json['month'],
      incoming: json['incoming'],
      outgoing: json['outgoing'],
      unanswered: json['unanswered'],
      missed: json['missed'],
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'incoming': incoming,
      'outgoing': outgoing,
      'unanswered': unanswered,
      'missed': missed,
      'total': total,
    };
  }
}