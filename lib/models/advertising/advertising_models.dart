import 'package:crm_task_manager/utils/safe_converters.dart';

class MetaAdsSummary {
  final double spend;
  final int impressions;
  final int clicks;
  final int linkClicks;
  final double? ctr;
  final int? results;
  final String? resultType;
  final double? costPerResult;
  final int metaLeads;
  final int messaging;
  final int crmLeads;
  final int newLeads;
  final int returningLeads;
  final double? cpl;
  final int deals;
  final double? conversion;
  final double revenue;
  final double? roi;
  final int? reach;
  final String currency;
  final String revenueCurrency;
  final String? dateFrom;
  final String? dateTo;

  MetaAdsSummary({
    required this.spend,
    required this.impressions,
    required this.clicks,
    required this.linkClicks,
    this.ctr,
    this.results,
    this.resultType,
    this.costPerResult,
    required this.metaLeads,
    required this.messaging,
    required this.crmLeads,
    required this.newLeads,
    required this.returningLeads,
    this.cpl,
    required this.deals,
    this.conversion,
    required this.revenue,
    this.roi,
    this.reach,
    required this.currency,
    required this.revenueCurrency,
    this.dateFrom,
    this.dateTo,
  });

  factory MetaAdsSummary.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final period = json['period'] as Map<String, dynamic>?;

    return MetaAdsSummary(
      spend: SafeConverters.toDouble(current['spend']),
      impressions: SafeConverters.toInt(current['impressions']),
      clicks: SafeConverters.toInt(current['clicks']),
      linkClicks: SafeConverters.toInt(current['link_clicks']),
      ctr: SafeConverters.toDoubleOrNull(current['ctr']),
      results: SafeConverters.toIntOrNull(current['results']),
      resultType: current['result_type']?.toString(),
      costPerResult: SafeConverters.toDoubleOrNull(current['cost_per_result']),
      metaLeads: SafeConverters.toInt(current['meta_leads']),
      messaging: SafeConverters.toInt(current['messaging']),
      crmLeads: SafeConverters.toInt(current['crm_leads']),
      newLeads: SafeConverters.toInt(current['new_leads']),
      returningLeads: SafeConverters.toInt(current['returning_leads']),
      cpl: SafeConverters.toDoubleOrNull(current['cpl']),
      deals: SafeConverters.toInt(current['deals']),
      conversion: SafeConverters.toDoubleOrNull(current['conversion']),
      revenue: SafeConverters.toDouble(current['revenue']),
      roi: SafeConverters.toDoubleOrNull(current['roi']),
      reach: SafeConverters.toIntOrNull(current['reach']),
      currency: json['currency']?.toString() ?? 'USD',
      revenueCurrency: json['revenue_currency']?.toString() ?? 'TJS',
      dateFrom: period?['date_from']?.toString(),
      dateTo: period?['date_to']?.toString(),
    );
  }
}

class MetaAdsCampaign {
  final int id;
  final String level;
  final String externalId;
  final String name;
  final String effectiveStatus;
  final String? objective;
  final String? budgetType;
  final double? budgetAmount;
  final int? accountId;
  final String? accountName;
  final double spend;
  final int impressions;
  final int clicks;
  final int linkClicks;
  final double? ctr;
  final int? results;
  final String? resultType;
  final double? costPerResult;
  final int? metaLeads;
  final int? messaging;
  final int? crmLeads;
  final int? newLeads;
  final int? returningLeads;
  final double? cpl;
  final int? deals;
  final double? conversion;
  final double? revenue;
  final int? reach;
  final int? adsCount;
  final int? salesFunnelId;
  final String? salesFunnelName;

  MetaAdsCampaign({
    required this.id,
    required this.level,
    required this.externalId,
    required this.name,
    required this.effectiveStatus,
    this.objective,
    this.budgetType,
    this.budgetAmount,
    this.accountId,
    this.accountName,
    required this.spend,
    required this.impressions,
    required this.clicks,
    required this.linkClicks,
    this.ctr,
    this.results,
    this.resultType,
    this.costPerResult,
    this.metaLeads,
    this.messaging,
    this.crmLeads,
    this.newLeads,
    this.returningLeads,
    this.cpl,
    this.deals,
    this.conversion,
    this.revenue,
    this.reach,
    this.adsCount,
    this.salesFunnelId,
    this.salesFunnelName,
  });

  bool get isActive => effectiveStatus.toUpperCase() == 'ACTIVE';

  factory MetaAdsCampaign.fromJson(Map<String, dynamic> json) {
    final budget = json['budget'] as Map<String, dynamic>?;

    return MetaAdsCampaign(
      id: SafeConverters.toInt(json['id']),
      level: json['level']?.toString() ?? 'campaign',
      externalId: json['external_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      effectiveStatus: json['effective_status']?.toString() ?? '',
      objective: json['objective']?.toString(),
      budgetType: budget?['type']?.toString(),
      budgetAmount: budget != null ? SafeConverters.toDoubleOrNull(budget['amount']) : null,
      accountId: SafeConverters.toIntOrNull(json['account_id']),
      accountName: json['account_name']?.toString(),
      spend: SafeConverters.toDouble(json['spend']),
      impressions: SafeConverters.toInt(json['impressions']),
      clicks: SafeConverters.toInt(json['clicks']),
      linkClicks: SafeConverters.toInt(json['link_clicks']),
      ctr: SafeConverters.toDoubleOrNull(json['ctr']),
      results: SafeConverters.toIntOrNull(json['results']),
      resultType: json['result_type']?.toString(),
      costPerResult: SafeConverters.toDoubleOrNull(json['cost_per_result']),
      metaLeads: SafeConverters.toIntOrNull(json['meta_leads']),
      messaging: SafeConverters.toIntOrNull(json['messaging']),
      crmLeads: SafeConverters.toIntOrNull(json['crm_leads']),
      newLeads: SafeConverters.toIntOrNull(json['new_leads']),
      returningLeads: SafeConverters.toIntOrNull(json['returning_leads']),
      cpl: SafeConverters.toDoubleOrNull(json['cpl']),
      deals: SafeConverters.toIntOrNull(json['deals']),
      conversion: SafeConverters.toDoubleOrNull(json['conversion']),
      revenue: SafeConverters.toDoubleOrNull(json['revenue']),
      reach: SafeConverters.toIntOrNull(json['reach']),
      adsCount: SafeConverters.toIntOrNull(json['ads_count']),
      salesFunnelId: SafeConverters.toIntOrNull(json['sales_funnel_id']),
      salesFunnelName: json['sales_funnel_name']?.toString(),
    );
  }
}

class MetaAdsAdSet {
  final int id;
  final String level;
  final String externalId;
  final String name;
  final String effectiveStatus;
  final String? optimizationGoal;
  final int? campaignId;
  final String? campaignName;
  final int? accountId;
  final String? accountName;
  final double spend;
  final int impressions;
  final int clicks;
  final int linkClicks;
  final double? ctr;
  final int? results;
  final String? resultType;
  final double? costPerResult;
  final int? metaLeads;
  final int? messaging;
  final int? crmLeads;
  final int? newLeads;
  final int? returningLeads;
  final double? cpl;
  final double? revenue;
  final int? reach;
  final int? adsCount;
  final int? salesFunnelId;
  final String? salesFunnelName;

  MetaAdsAdSet({
    required this.id,
    required this.level,
    required this.externalId,
    required this.name,
    required this.effectiveStatus,
    this.optimizationGoal,
    this.campaignId,
    this.campaignName,
    this.accountId,
    this.accountName,
    required this.spend,
    required this.impressions,
    required this.clicks,
    required this.linkClicks,
    this.ctr,
    this.results,
    this.resultType,
    this.costPerResult,
    this.metaLeads,
    this.messaging,
    this.crmLeads,
    this.newLeads,
    this.returningLeads,
    this.cpl,
    this.revenue,
    this.reach,
    this.adsCount,
    this.salesFunnelId,
    this.salesFunnelName,
  });

  bool get isActive => effectiveStatus.toUpperCase() == 'ACTIVE';

  factory MetaAdsAdSet.fromJson(Map<String, dynamic> json) {
    return MetaAdsAdSet(
      id: SafeConverters.toInt(json['id']),
      level: json['level']?.toString() ?? 'adset',
      externalId: json['external_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      effectiveStatus: json['effective_status']?.toString() ?? '',
      optimizationGoal: json['optimization_goal']?.toString(),
      campaignId: SafeConverters.toIntOrNull(json['campaign_id']),
      campaignName: json['campaign_name']?.toString(),
      accountId: SafeConverters.toIntOrNull(json['account_id']),
      accountName: json['account_name']?.toString(),
      spend: SafeConverters.toDouble(json['spend']),
      impressions: SafeConverters.toInt(json['impressions']),
      clicks: SafeConverters.toInt(json['clicks']),
      linkClicks: SafeConverters.toInt(json['link_clicks']),
      ctr: SafeConverters.toDoubleOrNull(json['ctr']),
      results: SafeConverters.toIntOrNull(json['results']),
      resultType: json['result_type']?.toString(),
      costPerResult: SafeConverters.toDoubleOrNull(json['cost_per_result']),
      metaLeads: SafeConverters.toIntOrNull(json['meta_leads']),
      messaging: SafeConverters.toIntOrNull(json['messaging']),
      crmLeads: SafeConverters.toIntOrNull(json['crm_leads']),
      newLeads: SafeConverters.toIntOrNull(json['new_leads']),
      returningLeads: SafeConverters.toIntOrNull(json['returning_leads']),
      cpl: SafeConverters.toDoubleOrNull(json['cpl']),
      revenue: SafeConverters.toDoubleOrNull(json['revenue']),
      reach: SafeConverters.toIntOrNull(json['reach']),
      adsCount: SafeConverters.toIntOrNull(json['ads_count']),
      salesFunnelId: SafeConverters.toIntOrNull(json['sales_funnel_id']),
      salesFunnelName: json['sales_funnel_name']?.toString(),
    );
  }
}

class MetaAdsAd {
  final int id;
  final String level;
  final String externalId;
  final String name;
  final String effectiveStatus;
  final String? thumbnailUrl;
  final String? previewUrl;
  final int? campaignId;
  final String? campaignName;
  final int? adsetId;
  final String? adsetName;
  final int? accountId;
  final String? accountName;
  final int? salesFunnelId;
  final String? salesFunnelName;
  final String? leadFormId;
  final bool leadFormConfigured;
  final double spend;
  final int impressions;
  final int clicks;
  final int linkClicks;
  final double? ctr;
  final int? results;
  final String? resultType;
  final double? costPerResult;
  final int? metaLeads;
  final int? messaging;
  final int? crmLeads;
  final int? newLeads;
  final int? returningLeads;
  final double? cpl;
  final double? revenue;
  final int? reach;

  MetaAdsAd({
    required this.id,
    required this.level,
    required this.externalId,
    required this.name,
    required this.effectiveStatus,
    this.thumbnailUrl,
    this.previewUrl,
    this.campaignId,
    this.campaignName,
    this.adsetId,
    this.adsetName,
    this.accountId,
    this.accountName,
    this.salesFunnelId,
    this.salesFunnelName,
    this.leadFormId,
    this.leadFormConfigured = false,
    required this.spend,
    required this.impressions,
    required this.clicks,
    required this.linkClicks,
    this.ctr,
    this.results,
    this.resultType,
    this.costPerResult,
    this.metaLeads,
    this.messaging,
    this.crmLeads,
    this.newLeads,
    this.returningLeads,
    this.cpl,
    this.revenue,
    this.reach,
  });

  bool get isActive => effectiveStatus.toUpperCase() == 'ACTIVE';

  factory MetaAdsAd.fromJson(Map<String, dynamic> json) {
    return MetaAdsAd(
      id: SafeConverters.toInt(json['id']),
      level: json['level']?.toString() ?? 'ad',
      externalId: json['external_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      effectiveStatus: json['effective_status']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      previewUrl: json['preview_url']?.toString(),
      campaignId: SafeConverters.toIntOrNull(json['campaign_id']),
      campaignName: json['campaign_name']?.toString(),
      adsetId: SafeConverters.toIntOrNull(json['adset_id']),
      adsetName: json['adset_name']?.toString(),
      accountId: SafeConverters.toIntOrNull(json['account_id']),
      accountName: json['account_name']?.toString(),
      salesFunnelId: SafeConverters.toIntOrNull(json['sales_funnel_id']),
      salesFunnelName: json['sales_funnel_name']?.toString(),
      leadFormId: json['lead_form_id']?.toString(),
      leadFormConfigured: json['lead_form_configured'] == true,
      spend: SafeConverters.toDouble(json['spend']),
      impressions: SafeConverters.toInt(json['impressions']),
      clicks: SafeConverters.toInt(json['clicks']),
      linkClicks: SafeConverters.toInt(json['link_clicks']),
      ctr: SafeConverters.toDoubleOrNull(json['ctr']),
      results: SafeConverters.toIntOrNull(json['results']),
      resultType: json['result_type']?.toString(),
      costPerResult: SafeConverters.toDoubleOrNull(json['cost_per_result']),
      metaLeads: SafeConverters.toIntOrNull(json['meta_leads']),
      messaging: SafeConverters.toIntOrNull(json['messaging']),
      crmLeads: SafeConverters.toIntOrNull(json['crm_leads']),
      newLeads: SafeConverters.toIntOrNull(json['new_leads']),
      returningLeads: SafeConverters.toIntOrNull(json['returning_leads']),
      cpl: SafeConverters.toDoubleOrNull(json['cpl']),
      revenue: SafeConverters.toDoubleOrNull(json['revenue']),
      reach: SafeConverters.toIntOrNull(json['reach']),
    );
  }
}

class OtherAdvertisingCampaign {
  final int id;
  final String? externalAdId;
  final String name;
  final String? type;
  final String? source;
  final String? status;
  final double cost;
  final int clientsCount;
  final int leadsCount;
  final String? description;
  final String? mediaUrl;
  final String? postId;
  final Map<String, dynamic>? integration;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OtherAdvertisingCampaign({
    required this.id,
    this.externalAdId,
    required this.name,
    this.type,
    this.source,
    this.status,
    required this.cost,
    required this.clientsCount,
    required this.leadsCount,
    this.description,
    this.mediaUrl,
    this.postId,
    this.integration,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status?.toLowerCase() == 'active';

  factory OtherAdvertisingCampaign.fromJson(Map<String, dynamic> json) {
    return OtherAdvertisingCampaign(
      id: SafeConverters.toInt(json['id']),
      externalAdId: json['external_ad_id']?.toString(),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      source: json['source']?.toString(),
      status: json['status']?.toString(),
      cost: SafeConverters.toDouble(json['cost']),
      clientsCount: SafeConverters.toInt(json['clients_count']),
      leadsCount: SafeConverters.toInt(json['leads_count']),
      description: json['description']?.toString(),
      mediaUrl: json['media_url']?.toString(),
      postId: json['post_id']?.toString(),
      integration: json['integration'] is Map<String, dynamic> ? json['integration'] : null,
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }
}

class MetaAdsAccount {
  final int id;
  final String externalId;
  final String name;
  final String? businessName;
  final String currency;
  final String? timezoneName;
  final int? accountStatus;
  final bool isEnabled;
  final String? syncStatus;
  final String? lastSyncedAt;
  final String? lastSyncStartedAt;

  MetaAdsAccount({
    required this.id,
    required this.externalId,
    required this.name,
    this.businessName,
    required this.currency,
    this.timezoneName,
    this.accountStatus,
    this.isEnabled = true,
    this.syncStatus,
    this.lastSyncedAt,
    this.lastSyncStartedAt,
  });

  factory MetaAdsAccount.fromJson(Map<String, dynamic> json) {
    return MetaAdsAccount(
      id: SafeConverters.toInt(json['id']),
      externalId: json['external_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      businessName: json['business_name']?.toString(),
      currency: json['currency']?.toString() ?? 'USD',
      timezoneName: json['timezone_name']?.toString(),
      accountStatus: SafeConverters.toIntOrNull(json['account_status']),
      isEnabled: json['is_enabled'] == true,
      syncStatus: json['sync_status']?.toString(),
      lastSyncedAt: json['last_synced_at']?.toString(),
      lastSyncStartedAt: json['last_sync_started_at']?.toString(),
    );
  }
}

class AdvertisingPagination {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  AdvertisingPagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory AdvertisingPagination.fromJson(Map<String, dynamic> json) {
    return AdvertisingPagination(
      total: SafeConverters.toInt(json['total']),
      count: SafeConverters.toInt(json['count']),
      perPage: SafeConverters.toInt(json['per_page']),
      currentPage: SafeConverters.toInt(json['current_page']),
      totalPages: SafeConverters.toInt(json['total_pages']),
    );
  }
}
