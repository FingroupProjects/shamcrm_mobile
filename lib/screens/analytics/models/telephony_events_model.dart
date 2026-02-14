import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class TelephonyEventDay {
  final int day;
  final int incoming;
  final int outgoing;
  final int missed;
  final int noticesCreated;
  final int noticesFinished;

  TelephonyEventDay({
    required this.day,
    required this.incoming,
    required this.outgoing,
    required this.missed,
    required this.noticesCreated,
    required this.noticesFinished,
  });

  factory TelephonyEventDay.fromJson(Map<String, dynamic> json) {
    return TelephonyEventDay(
      day: SafeConverters.toInt(json['day']),
      incoming: SafeConverters.toInt(json['incoming']),
      outgoing: SafeConverters.toInt(json['outgoing']),
      missed: SafeConverters.toInt(json['missed']),
      noticesCreated: SafeConverters.toInt(json['notices_created']),
      noticesFinished: SafeConverters.toInt(json['notices_finished']),
    );
  }
}

class TelephonyEventsResponse {
  final List<TelephonyEventDay> chart;
  final int totalCalls;
  final int totalIncoming;
  final int totalOutgoing;
  final int totalMissed;
  final int totalNoticesCreated;
  final int totalNoticesFinished;

  TelephonyEventsResponse({
    required this.chart,
    required this.totalCalls,
    required this.totalIncoming,
    required this.totalOutgoing,
    required this.totalMissed,
    required this.totalNoticesCreated,
    required this.totalNoticesFinished,
  });

  factory TelephonyEventsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final chartData = result['chart'];
      return TelephonyEventsResponse(
        chart: chartData is List
            ? chartData.map((e) => TelephonyEventDay.fromJson(e)).toList()
            : <TelephonyEventDay>[],
        totalCalls: SafeConverters.toInt(result['total_calls']),
        totalIncoming: SafeConverters.toInt(result['total_incoming']),
        totalOutgoing: SafeConverters.toInt(result['total_outgoing']),
        totalMissed: SafeConverters.toInt(result['total_missed']),
        totalNoticesCreated: SafeConverters.toInt(result['total_notices_created']),
        totalNoticesFinished: SafeConverters.toInt(result['total_notices_finished']),
      );
    }

    return TelephonyEventsResponse(
      chart: [],
      totalCalls: 0,
      totalIncoming: 0,
      totalOutgoing: 0,
      totalMissed: 0,
      totalNoticesCreated: 0,
      totalNoticesFinished: 0,
    );
  }
}
