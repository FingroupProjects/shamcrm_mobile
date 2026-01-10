class CallStatistics {
  final List<CallStatMonth> result;
  final dynamic errors;

  CallStatistics({required this.result, this.errors});

  factory CallStatistics.fromJson(Map<String, dynamic> json) {
    var resultList = json['result'] as List;
    return CallStatistics(
      result: resultList.map((item) => CallStatMonth.fromJson(item)).toList(),
      errors: json['errors'],
    );
  }
}

class CallStatMonth {
  final int month;
  final int total;
  final int outgoing;
  final int missed;
  final int unanswered;
  final double averageAnswerTime;
  final int notCalledBackCount;
  final int incoming; // Новое поле

  CallStatMonth({
    required this.month,
    required this.total,
    required this.outgoing,
    required this.missed,
    required this.unanswered,
    required this.averageAnswerTime,
    required this.notCalledBackCount,
    required this.incoming,
  });

  factory CallStatMonth.fromJson(Map<String, dynamic> json) {
    return CallStatMonth(
      month: json['month'] as int,
      total: json['total'] as int,
      outgoing: int.parse(json['outgoing'].toString()),
      missed: int.parse(json['missed'].toString()),
      unanswered: int.parse(json['unanswered'].toString()),
      averageAnswerTime: (json['average_answer_time'] as num).toDouble(),
      notCalledBackCount: json['not_called_back_count'] as int,
      incoming: (json['total'] as int) - int.parse(json['outgoing'].toString()),
    );
  }
}