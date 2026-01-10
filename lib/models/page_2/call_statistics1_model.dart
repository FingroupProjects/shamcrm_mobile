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
  final num month;
  final num total;
  final num outgoing;
  final num missed;
  final num unanswered;
  final num averageAnswerTime;
  final num notCalledBackCount;
  final num incoming; // Новое поле

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
      month: num.parse(json['month'].toString()),
      total: num.parse(json['total'].toString()),
      outgoing: num.parse(json['outgoing'].toString()),
      missed: num.parse(json['missed'].toString()),
      unanswered: num.parse(json['unanswered'].toString()),
      averageAnswerTime: num.parse((json['average_answer_time'].toString())),
      notCalledBackCount: num.parse(json['not_called_back_count'].toString()),
      incoming: num.parse((json['total'].toString())) - num.parse(json['outgoing'].toString()),
    );
  }
}