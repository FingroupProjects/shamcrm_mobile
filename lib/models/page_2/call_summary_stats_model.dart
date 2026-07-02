class CallSummaryStats {
  final CallSummaryResult result;
  final String? errors;

  CallSummaryStats({
    required this.result,
    this.errors,
  });

  factory CallSummaryStats.fromJson(Map<String, dynamic> json) {
    final resultJson = json['result'];
    return CallSummaryStats(
      result: CallSummaryResult.fromJson(
        resultJson is Map<String, dynamic>
            ? resultJson
            : <String, dynamic>{},
      ),
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result.toJson(),
      'errors': errors,
    };
  }
}

class CallSummaryResult {
  final double averageCallDuration;
  final int averageDailyDuration;
  final int totalCalls;
  final CallCountsByType countsByType;

  CallSummaryResult({
    required this.averageCallDuration,
    required this.averageDailyDuration,
    required this.totalCalls,
    required this.countsByType,
  });

  factory CallSummaryResult.fromJson(Map<String, dynamic> json) {
    return CallSummaryResult(
      averageCallDuration: _toDouble(json['average_call_duration']),
      averageDailyDuration: _toInt(json['average_daily_duration']),
      totalCalls: _toInt(json['total_calls']),
      countsByType: CallCountsByType.fromJson(
        (json['counts_by_type'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  static double _toDouble(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'average_call_duration': averageCallDuration,
      'average_daily_duration': averageDailyDuration,
      'total_calls': totalCalls,
      'counts_by_type': countsByType.toJson(),
    };
  }
}

class CallCountsByType {
  final int incoming;
  final int outgoing;
  final int unanswered;
  final int missed;

  CallCountsByType({
    required this.incoming,
    required this.outgoing,
    required this.unanswered,
    required this.missed,
  });

  factory CallCountsByType.fromJson(Map<String, dynamic> json) {
    return CallCountsByType(
      incoming: _toInt(json['incoming']),
      outgoing: _toInt(json['outgoing']),
      unanswered: _toInt(json['unanswered']),
      missed: _toInt(json['missed']),
    );
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'incoming': incoming,
      'outgoing': outgoing,
      'unanswered': unanswered,
      'missed': missed,
    };
  }
}
