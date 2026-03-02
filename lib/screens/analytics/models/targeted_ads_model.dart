import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class TargetedAdsSummary {
  final int totalReaches;
  final int successful;
  final double costPerLead;

  TargetedAdsSummary({
    required this.totalReaches,
    required this.successful,
    required this.costPerLead,
  });

  factory TargetedAdsSummary.fromJson(Map<String, dynamic> json) {
    return TargetedAdsSummary(
      totalReaches: SafeConverters.toInt(json['total_reaches']),
      successful: SafeConverters.toInt(json['successful']),
      costPerLead: SafeConverters.toDouble(json['cost_per_lead']),
    );
  }
}

class TargetedAdCampaign {
  final int campaignId;
  final String campaignName;
  final String adType;
  final String adSource;
  final String integrationName;
  final String integrationType;
  final int totalReaches;
  final int successful;
  final int cold;
  final int inProgress;
  final double cost;
  final double revenue;
  final double costPerLead;
  final double conversionRate;

  TargetedAdCampaign({
    required this.campaignId,
    required this.campaignName,
    required this.adType,
    required this.adSource,
    required this.integrationName,
    required this.integrationType,
    required this.totalReaches,
    required this.successful,
    required this.cold,
    required this.inProgress,
    required this.cost,
    required this.revenue,
    required this.costPerLead,
    required this.conversionRate,
  });

  factory TargetedAdCampaign.fromJson(Map<String, dynamic> json) {
    return TargetedAdCampaign(
      campaignId: SafeConverters.toInt(json['campaign_id']),
      campaignName: SafeConverters.toSafeString(json['campaign_name']),
      adType: SafeConverters.toSafeString(json['ad_type']),
      adSource: SafeConverters.toSafeString(json['ad_source']),
      integrationName: SafeConverters.toSafeString(json['integration_name']),
      integrationType: SafeConverters.toSafeString(json['integration_type']),
      totalReaches: SafeConverters.toInt(json['total_reaches']),
      successful: SafeConverters.toInt(json['successful']),
      cold: SafeConverters.toInt(json['cold']),
      inProgress: SafeConverters.toInt(json['in_progress']),
      cost: SafeConverters.toDouble(json['cost']),
      revenue: SafeConverters.toDouble(json['revenue']),
      costPerLead: SafeConverters.toDouble(json['cost_per_lead']),
      conversionRate: SafeConverters.toDouble(json['conversion_rate']),
    );
  }
}

class TargetedAdsResponse {
  final TargetedAdsSummary summary;
  final List<TargetedAdCampaign> topCampaigns;

  TargetedAdsResponse({
    required this.summary,
    required this.topCampaigns,
  });

  factory TargetedAdsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final summary = result['summary'] is Map<String, dynamic>
          ? TargetedAdsSummary.fromJson(result['summary'])
          : TargetedAdsSummary(totalReaches: 0, successful: 0, costPerLead: 0);
      final campaigns = result['top_campaigns'];
      return TargetedAdsResponse(
        summary: summary,
        topCampaigns: campaigns is List
            ? campaigns.map((e) => TargetedAdCampaign.fromJson(e)).toList()
            : <TargetedAdCampaign>[],
      );
    }

    return TargetedAdsResponse(
      summary: TargetedAdsSummary(totalReaches: 0, successful: 0, costPerLead: 0),
      topCampaigns: [],
    );
  }
}
