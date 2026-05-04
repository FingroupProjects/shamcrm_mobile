import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class TelephonyHourItem {
  final String hour;
  final int hourNumber;
  final int incoming;
  final int outgoing;
  final int missed;
  final int minutes;
  final int total;

  TelephonyHourItem({
    required this.hour,
    required this.hourNumber,
    required this.incoming,
    required this.outgoing,
    required this.missed,
    required this.minutes,
    required this.total,
  });

  factory TelephonyHourItem.fromJson(Map<String, dynamic> json) {
    return TelephonyHourItem(
      hour: SafeConverters.toSafeString(json['hour']),
      hourNumber: SafeConverters.toInt(json['hour_number']),
      incoming: SafeConverters.toInt(json['incoming']),
      outgoing: SafeConverters.toInt(json['outgoing']),
      missed: SafeConverters.toInt(json['missed']),
      minutes: SafeConverters.toInt(json['minutes']),
      total: SafeConverters.toInt(json['total']),
    );
  }
}

class TelephonyByHourResponse {
  final List<TelephonyHourItem> chart;
  final int totalCalls;
  final int totalIncoming;
  final int totalOutgoing;
  final int totalMissed;
  final int totalMinutes;
  final String? peakHour;

  TelephonyByHourResponse({
    required this.chart,
    required this.totalCalls,
    required this.totalIncoming,
    required this.totalOutgoing,
    required this.totalMissed,
    required this.totalMinutes,
    required this.peakHour,
  });

  factory TelephonyByHourResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final chartData = result['chart'];
      return TelephonyByHourResponse(
        chart: chartData is List
            ? chartData.map((e) => TelephonyHourItem.fromJson(e)).toList()
            : <TelephonyHourItem>[],
        totalCalls: SafeConverters.toInt(result['total_calls']),
        totalIncoming: SafeConverters.toInt(result['total_incoming']),
        totalOutgoing: SafeConverters.toInt(result['total_outgoing']),
        totalMissed: SafeConverters.toInt(result['total_missed']),
        totalMinutes: SafeConverters.toInt(result['total_minutes']),
        peakHour: result['peak_hour'] == null
            ? null
            : SafeConverters.toSafeString(result['peak_hour']),
      );
    }

    return TelephonyByHourResponse(
      chart: [],
      totalCalls: 0,
      totalIncoming: 0,
      totalOutgoing: 0,
      totalMissed: 0,
      totalMinutes: 0,
      peakHour: null,
    );
  }
}
