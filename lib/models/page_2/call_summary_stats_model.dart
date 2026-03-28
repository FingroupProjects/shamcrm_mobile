
import 'dart:convert';

class CallSummaryStats {
  final CallSummaryResult result;
  final String? errors;

  CallSummaryStats({
    required this.result,
    this.errors,
  });

  factory CallSummaryStats.fromJson(Map<String, dynamic> json) {
    return CallSummaryStats(
      result: CallSummaryResult.fromJson(json['result']),
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
      averageCallDuration: json['average_call_duration'].toDouble(),
      averageDailyDuration: json['average_daily_duration'],
      totalCalls: json['total_calls'],
      countsByType: CallCountsByType.fromJson(json['counts_by_type']),
    );
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
      incoming: json['incoming'],
      outgoing: json['outgoing'],
      unanswered: json['unanswered'],
      missed: json['missed'],
    );
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
