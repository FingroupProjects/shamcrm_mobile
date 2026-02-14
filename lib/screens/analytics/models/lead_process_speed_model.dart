import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Model for lead process speed from /api/v2/dashboard/lead-process-speed
/// Response: {result: {average_processing_speed: 2381.69, leads_format: "hours", deals_format: "days"}}
class LeadProcessSpeedResponse {
  final double averageProcessingSpeed;
  final String leadsFormat;
  final String dealsFormat;

  LeadProcessSpeedResponse({
    required this.averageProcessingSpeed,
    required this.leadsFormat,
    required this.dealsFormat,
  });

  factory LeadProcessSpeedResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];

    if (result is Map<String, dynamic>) {
      return LeadProcessSpeedResponse(
        averageProcessingSpeed: SafeConverters.toDouble(
          result['average_processing_speed'],
        ),
        leadsFormat: SafeConverters.toSafeString(
          result['leads_format'],
          defaultValue: 'hours',
        ),
        dealsFormat: SafeConverters.toSafeString(
          result['deals_format'],
          defaultValue: 'days',
        ),
      );
    }

    // Return default data if parsing fails
    return LeadProcessSpeedResponse(
      averageProcessingSpeed: 0.0,
      leadsFormat: 'hours',
      dealsFormat: 'days',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_processing_speed': averageProcessingSpeed,
      'leads_format': leadsFormat,
      'deals_format': dealsFormat,
    };
  }

  String get formattedSpeed {
    if (averageProcessingSpeed < 1) {
      return '< 1 $leadsFormat';
    }
    return '${averageProcessingSpeed.toStringAsFixed(1)} $leadsFormat';
  }

  String get displayText {
    if (leadsFormat == 'hours') {
      if (averageProcessingSpeed < 24) {
        return '${averageProcessingSpeed.toStringAsFixed(1)} ч';
      } else {
        final days = averageProcessingSpeed / 24;
        return '${days.toStringAsFixed(1)} дн';
      }
    }
    return '${averageProcessingSpeed.toStringAsFixed(1)} $leadsFormat';
  }
}
