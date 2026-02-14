import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class AdvertisingRoiSummary {
  final double totalSpent;
  final int totalLeads;
  final double cpl;
  final double roi;

  AdvertisingRoiSummary({
    required this.totalSpent,
    required this.totalLeads,
    required this.cpl,
    required this.roi,
  });

  factory AdvertisingRoiSummary.fromJson(Map<String, dynamic> json) {
    return AdvertisingRoiSummary(
      totalSpent: SafeConverters.toDouble(json['total_spent']),
      totalLeads: SafeConverters.toInt(json['total_leads']),
      cpl: SafeConverters.toDouble(json['cpl']),
      roi: SafeConverters.toDouble(json['roi']),
    );
  }
}

class AdvertisingRoiIntegration {
  final int integrationId;
  final String integrationName;
  final String integrationType;
  final int totalLeads;
  final int clients;
  final int cold;
  final double spent;
  final double cpl;
  final double revenue;
  final double roi;

  AdvertisingRoiIntegration({
    required this.integrationId,
    required this.integrationName,
    required this.integrationType,
    required this.totalLeads,
    required this.clients,
    required this.cold,
    required this.spent,
    required this.cpl,
    required this.revenue,
    required this.roi,
  });

  factory AdvertisingRoiIntegration.fromJson(Map<String, dynamic> json) {
    return AdvertisingRoiIntegration(
      integrationId: SafeConverters.toInt(json['integration_id']),
      integrationName: SafeConverters.toSafeString(json['integration_name']),
      integrationType: SafeConverters.toSafeString(json['integration_type']),
      totalLeads: SafeConverters.toInt(json['total_leads']),
      clients: SafeConverters.toInt(json['clients']),
      cold: SafeConverters.toInt(json['cold']),
      spent: SafeConverters.toDouble(json['spent']),
      cpl: SafeConverters.toDouble(json['cpl']),
      revenue: SafeConverters.toDouble(json['revenue']),
      roi: SafeConverters.toDouble(json['roi']),
    );
  }
}

class AdvertisingRoiResponse {
  final AdvertisingRoiSummary summary;
  final List<AdvertisingRoiIntegration> integrations;

  AdvertisingRoiResponse({
    required this.summary,
    required this.integrations,
  });

  factory AdvertisingRoiResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final summary = result['summary'] is Map<String, dynamic>
          ? AdvertisingRoiSummary.fromJson(result['summary'])
          : AdvertisingRoiSummary(totalSpent: 0, totalLeads: 0, cpl: 0, roi: 0);
      final integrations = result['integrations'];
      return AdvertisingRoiResponse(
        summary: summary,
        integrations: integrations is List
            ? integrations.map((e) => AdvertisingRoiIntegration.fromJson(e)).toList()
            : <AdvertisingRoiIntegration>[],
      );
    }

    return AdvertisingRoiResponse(
      summary: AdvertisingRoiSummary(totalSpent: 0, totalLeads: 0, cpl: 0, roi: 0),
      integrations: [],
    );
  }
}
