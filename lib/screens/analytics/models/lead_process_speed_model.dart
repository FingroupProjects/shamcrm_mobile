import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Model for lead process speed from /api/v2/dashboard/lead-process-speed
/// Response: {result: {average_processing_speed: 2381.69, leads_format: "hours", deals_format: "days"}}
class LeadProcessSpeedResponse {
  final double averageProcessingSpeed;
  final String leadsFormat;
  final String dealsFormat;
  final String speedTimeFormat;
  final double? excellentTo;
  final double? goodTo;
  final double? normalTo;
  final double? badTo;

  LeadProcessSpeedResponse({
    required this.averageProcessingSpeed,
    required this.leadsFormat,
    required this.dealsFormat,
    required this.speedTimeFormat,
    this.excellentTo,
    this.goodTo,
    this.normalTo,
    this.badTo,
  });

  factory LeadProcessSpeedResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];

    if (result is Map<String, dynamic>) {
      final settings = result['settings'] is Map<String, dynamic>
          ? result['settings'] as Map<String, dynamic>
          : const <String, dynamic>{};
      final zones = settings['zones'] is Map<String, dynamic>
          ? settings['zones'] as Map<String, dynamic>
          : const <String, dynamic>{};

      double? readZoneTo(String key) {
        final zone = zones[key];
        if (zone is Map<String, dynamic>) {
          return SafeConverters.toDouble(zone['to']);
        }
        return null;
      }

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
        speedTimeFormat: SafeConverters.toSafeString(
          settings['speed_time_format'],
          defaultValue: SafeConverters.toSafeString(
            result['leads_format'],
            defaultValue: 'hours',
          ),
        ),
        excellentTo: readZoneTo('excellent'),
        goodTo: readZoneTo('good'),
        normalTo: readZoneTo('normal'),
        badTo: readZoneTo('bad'),
      );
    }

    // Return default data if parsing fails
    return LeadProcessSpeedResponse(
      averageProcessingSpeed: 0.0,
      leadsFormat: 'hours',
      dealsFormat: 'days',
      speedTimeFormat: 'hours',
      excellentTo: null,
      goodTo: null,
      normalTo: null,
      badTo: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_processing_speed': averageProcessingSpeed,
      'leads_format': leadsFormat,
      'deals_format': dealsFormat,
      'speed_time_format': speedTimeFormat,
      'zones': {
        'excellent_to': excellentTo,
        'good_to': goodTo,
        'normal_to': normalTo,
        'bad_to': badTo,
      },
    };
  }

  String get formattedSpeed {
    if (averageProcessingSpeed < 1) {
      return '< 1 $leadsFormat';
    }
    return '${averageProcessingSpeed.toStringAsFixed(1)} $leadsFormat';
  }

  String get displayText {
    if (speedTimeFormat == 'hours' || leadsFormat == 'hours') {
      if (averageProcessingSpeed < 24) {
        return '${averageProcessingSpeed.toStringAsFixed(1)} ч';
      } else {
        final days = averageProcessingSpeed / 24;
        return '${days.toStringAsFixed(1)} дн';
      }
    }
    if (speedTimeFormat == 'minutes' || leadsFormat == 'minutes') {
      return '${averageProcessingSpeed.toStringAsFixed(1)} мин';
    }
    if (speedTimeFormat == 'days' || leadsFormat == 'days') {
      return '${averageProcessingSpeed.toStringAsFixed(1)} дн';
    }
    return '${averageProcessingSpeed.toStringAsFixed(1)} $speedTimeFormat';
  }
}
