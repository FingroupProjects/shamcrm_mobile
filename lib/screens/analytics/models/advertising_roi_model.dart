import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class AdvertisingRoiSummary {
  final double totalSpent;
  final int totalLeads;
  final int totalClients;
  final int totalCold;
  final double totalRevenue;
  final double cpl;
  final double roi;
  final double conversionRate;
  final double profit;

  AdvertisingRoiSummary({
    required this.totalSpent,
    required this.totalLeads,
    this.totalClients = 0,
    this.totalCold = 0,
    this.totalRevenue = 0,
    required this.cpl,
    required this.roi,
    this.conversionRate = 0,
    this.profit = 0,
  });

  factory AdvertisingRoiSummary.fromJson(Map<String, dynamic> json) {
    return AdvertisingRoiSummary(
      totalSpent: SafeConverters.toDouble(json['total_spent']),
      totalLeads: SafeConverters.toInt(json['total_leads']),
      totalClients: SafeConverters.toInt(json['total_clients']),
      totalCold: SafeConverters.toInt(json['total_cold']),
      totalRevenue: SafeConverters.toDouble(json['total_revenue']),
      cpl: SafeConverters.toDouble(json['cpl']),
      roi: SafeConverters.toDouble(json['roi']),
      conversionRate: SafeConverters.toDouble(json['conversion_rate']),
      profit: SafeConverters.toDouble(json['profit']),
    );
  }
}

/// Represents a single campaign from `top_campaigns`.
class AdvertisingRoiCampaign {
  final int campaignId;
  final String campaignName;
  final String adType;
  final String source;
  final int integrationId;
  final String integrationName;
  final String integrationType;
  final int totalLeads;
  final int clients;
  final int cold;
  final double conversionRate;
  final double spent;
  final double cpl;
  final double revenue;
  final double roi;
  final double profit;

  AdvertisingRoiCampaign({
    required this.campaignId,
    required this.campaignName,
    required this.adType,
    required this.source,
    required this.integrationId,
    required this.integrationName,
    required this.integrationType,
    required this.totalLeads,
    required this.clients,
    required this.cold,
    required this.conversionRate,
    required this.spent,
    required this.cpl,
    required this.revenue,
    required this.roi,
    required this.profit,
  });

  factory AdvertisingRoiCampaign.fromJson(Map<String, dynamic> json) {
    return AdvertisingRoiCampaign(
      campaignId: SafeConverters.toInt(json['campaign_id']),
      campaignName: SafeConverters.toSafeString(json['campaign_name']),
      adType: SafeConverters.toSafeString(json['ad_type']),
      source: SafeConverters.toSafeString(json['source']),
      integrationId: SafeConverters.toInt(json['integration_id']),
      integrationName: SafeConverters.toSafeString(json['integration_name']),
      integrationType: SafeConverters.toSafeString(json['integration_type']),
      totalLeads: SafeConverters.toInt(json['total_leads']),
      clients: SafeConverters.toInt(json['clients']),
      cold: SafeConverters.toInt(json['cold']),
      conversionRate: SafeConverters.toDouble(json['conversion_rate']),
      spent: SafeConverters.toDouble(json['spent']),
      cpl: SafeConverters.toDouble(json['cpl']),
      revenue: SafeConverters.toDouble(json['revenue']),
      roi: SafeConverters.toDouble(json['roi']),
      profit: SafeConverters.toDouble(json['profit']),
    );
  }
}

/// Keep backward‑compatible alias used by the chart for bar groups.
typedef AdvertisingRoiIntegration = AdvertisingRoiCampaign;

class AdvertisingRoiResponse {
  final AdvertisingRoiSummary summary;
  final List<AdvertisingRoiCampaign> campaigns;
  final int totalCampaignsCount;

  AdvertisingRoiResponse({
    required this.summary,
    required this.campaigns,
    this.totalCampaignsCount = 0,
  });

  /// Backward‑compatible getter so existing chart code still compiles.
  List<AdvertisingRoiCampaign> get integrations => campaigns;

  factory AdvertisingRoiResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final summary = result['summary'] is Map<String, dynamic>
          ? AdvertisingRoiSummary.fromJson(result['summary'])
          : AdvertisingRoiSummary(totalSpent: 0, totalLeads: 0, cpl: 0, roi: 0);

      final rawCampaigns = result['top_campaigns'];
      final campaigns = <AdvertisingRoiCampaign>[];

      if (rawCampaigns is List) {
        for (final c in rawCampaigns) {
          if (c is Map<String, dynamic>) {
            campaigns.add(AdvertisingRoiCampaign.fromJson(c));
          }
        }
      }

      return AdvertisingRoiResponse(
        summary: summary,
        campaigns: campaigns,
        totalCampaignsCount: SafeConverters.toInt(
          result['total_campaigns_count'],
        ),
      );
    }

    return AdvertisingRoiResponse(
      summary:
          AdvertisingRoiSummary(totalSpent: 0, totalLeads: 0, cpl: 0, roi: 0),
      campaigns: [],
    );
  }
}
