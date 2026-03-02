import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Individual status conversion data
class StatusConversion {
  final String statusName;
  final int totalLeads;
  final int conversionFromPrevious;
  final String conversionRate;

  StatusConversion({
    required this.statusName,
    required this.totalLeads,
    required this.conversionFromPrevious,
    required this.conversionRate,
  });

  factory StatusConversion.fromJson(Map<String, dynamic> json) {
    return StatusConversion(
      statusName: SafeConverters.toSafeString(json['status_name']),
      totalLeads: SafeConverters.toInt(json['total_leads']),
      conversionFromPrevious:
          SafeConverters.toInt(json['conversion_from_previous']),
      conversionRate: SafeConverters.toSafeString(json['conversion_rate'],
          defaultValue: '0%'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_name': statusName,
      'total_leads': totalLeads,
      'conversion_from_previous': conversionFromPrevious,
      'conversion_rate': conversionRate,
    };
  }

  double get conversionRateNumeric {
    final cleaned = conversionRate.replaceAll('%', '').trim();
    return SafeConverters.toDouble(cleaned);
  }
}

/// Model for lead conversion by statuses from /api/v2/dashboard/leadConversion-by-statuses-chart
/// Response: {result: {statuses: [...], average_conversion: "16.43%"}}
class LeadConversionByStatusesResponse {
  final List<StatusConversion> statuses;
  final String averageConversion;

  LeadConversionByStatusesResponse({
    required this.statuses,
    required this.averageConversion,
  });

  factory LeadConversionByStatusesResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];

    if (result is Map<String, dynamic>) {
      final statusesData = result['statuses'];
      final statuses = statusesData is List
          ? statusesData.map((e) => StatusConversion.fromJson(e)).toList()
          : <StatusConversion>[];

      return LeadConversionByStatusesResponse(
        statuses: statuses,
        averageConversion: SafeConverters.toSafeString(
          result['average_conversion'],
          defaultValue: '0%',
        ),
      );
    }

    // Return empty data if parsing fails
    return LeadConversionByStatusesResponse(
      statuses: [],
      averageConversion: '0%',
    );
  }

  double get averageConversionNumeric {
    final cleaned = averageConversion.replaceAll('%', '').trim();
    return SafeConverters.toDouble(cleaned);
  }

  int get totalLeads {
    return statuses.fold(0, (sum, status) => sum + status.totalLeads);
  }
}
