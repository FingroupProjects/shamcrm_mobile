import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter/foundation.dart';

/// Pre-warms [ApiService._analyticsResponseCache] so that when
/// [AnalyticsScreen] loads, chart widgets get cache hits instead of
/// cold network requests.
class DashboardPrefetchService {
  DashboardPrefetchService._();

  static const String defaultPeriodKey = 'current_year';

  static bool _prefetchStarted = false;
  static Future<void>? _filtersReady;

  /// Applies the same default dashboard filters that [AnalyticsScreen] uses,
  /// so prefetch URLs match the later chart requests.
  static Future<void> applyDefaultFilters() {
    return _filtersReady ??= _applyDefaultFilters();
  }

  static Future<void> _applyDefaultFilters() async {
    final api = ApiService();
    await api.ensureSelectedSalesFunnelInitialized();
    final organizationId = await api.getSelectedOrganization() ?? '1';
    final salesFunnelId = await api.getSelectedSalesFunnel();

    final payload = <String, dynamic>{
      'organization_id': organizationId,
      'period': defaultPeriodKey,
      if (salesFunnelId != null && salesFunnelId.isNotEmpty)
        'sales_funnel_id': salesFunnelId,
      if (salesFunnelId != null && salesFunnelId.isNotEmpty)
        'salesFunnels': [salesFunnelId],
    };

    ApiService.setAnalyticsFilters(payload);
  }

  /// Kick off analytics API calls in the background.
  /// Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> prefetchAnalyticsData() async {
    if (_prefetchStarted) return;
    _prefetchStarted = true;

    final api = ApiService();

    Future<void> safe(Future<Object?> Function() fn) async {
      try {
        await fn();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('DashboardPrefetchService: ignored error → $e');
        }
      }
    }

    await applyDefaultFilters();

    // First paint only needs settings, KPI cards and the first visible charts.
    await Future.wait([
      safe(api.getDashboardSettingsV2),
      safe(api.getDashboardStatisticsV2),
      safe(api.getLeadConversionDataV2),
      safe(api.getSourceOfLeadsChartV2),
    ]);

    // Remaining charts fill the cache after the first cards can already render.
    unawaited(Future.wait([
      safe(api.getLeadConversionByStatuses),
      safe(api.getLeadProcessSpeedV2),
      safe(api.getUsersChartV2),
      safe(api.getTaskChartDataV2),
      safe(api.getDealsByManagersV2),
      safe(api.getCompletedTasksChartV2),
      safe(api.getTelephonyAndEventsChartV2),
      safe(api.getOnlineStoreOrdersChartV2),
    ]));

    if (kDebugMode) {
      debugPrint('DashboardPrefetchService: first-wave prefetch complete');
    }
  }

  /// Reset so the next login session can prefetch again.
  static void reset() {
    _prefetchStarted = false;
    _filtersReady = null;
  }
}
