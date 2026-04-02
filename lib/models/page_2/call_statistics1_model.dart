class CallStatistics {
  final List<CallStatMonth> result;
  final dynamic errors;

  CallStatistics({required this.result, this.errors});

  factory CallStatistics.fromJson(Map<String, dynamic> json) {
    final resultList = (json['result'] as List?) ?? const [];
    return CallStatistics(
      result: resultList
          .whereType<Map<String, dynamic>>()
          .map(CallStatMonth.fromJson)
          .toList(),
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

  static num _toNum(dynamic value, {num defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? defaultValue;
  }

  factory CallStatMonth.fromJson(Map<String, dynamic> json) {
    final total = _toNum(json['total']);
    final outgoing = _toNum(json['outgoing']);
    final incoming = json.containsKey('incoming')
        ? _toNum(json['incoming'])
        : (total - outgoing).clamp(0, double.infinity);

    return CallStatMonth(
      month: _toNum(json['month']),
      total: total,
      outgoing: outgoing,
      missed: _toNum(json['missed']),
      unanswered: _toNum(json['unanswered'], defaultValue: incoming),
      averageAnswerTime: _toNum(json['average_answer_time']),
      notCalledBackCount: _toNum(json['not_called_back_count']),
      incoming: incoming,
    );
  }
}
