// lib/models/call_analytics_model.dart
import 'dart:convert';

class CallAnalytics {
  final CallAnalyticsResult result;
  final dynamic errors;

  CallAnalytics({
    required this.result,
    this.errors,
  });

  factory CallAnalytics.fromJson(Map<String, dynamic> json) {
    return CallAnalytics(
      result: CallAnalyticsResult.fromJson(json['result']),
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

class CallAnalyticsResult {
  final num unansweredNotCalledBack;
  final num todaysTotalMissedCalls;
  final num todaysTotalOutgoingCalls;
  final num operatorsInCall;

  CallAnalyticsResult({
    required this.unansweredNotCalledBack,
    required this.todaysTotalMissedCalls,
    required this.todaysTotalOutgoingCalls,
    required this.operatorsInCall,
  });

  factory CallAnalyticsResult.fromJson(Map<String, dynamic> json) {
    return CallAnalyticsResult(
      unansweredNotCalledBack: json['unanswered_not_called_back'] ?? 0,
      todaysTotalMissedCalls: json['todays_total_missed_calls'] ?? 0,
      todaysTotalOutgoingCalls: json['todays_total_outgoing_calls'] ?? 0,
      operatorsInCall: json['operators_in_call'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unanswered_not_called_back': unansweredNotCalledBack,
      'todays_total_missed_calls': todaysTotalMissedCalls,
      'todays_total_outgoing_calls': todaysTotalOutgoingCalls,
      'operators_in_call': operatorsInCall,
    };
  }

  bool get isNotEmpty =>
      unansweredNotCalledBack > 0 ||
      todaysTotalMissedCalls > 0 ||
      todaysTotalOutgoingCalls > 0 ||
      operatorsInCall > 0;
}