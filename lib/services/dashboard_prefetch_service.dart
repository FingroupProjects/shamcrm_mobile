import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter/foundation.dart';

/// Pre-warms [ApiService._analyticsResponseCache] so that when
/// [AnalyticsScreen] loads, every chart widget gets an instant cache
/// hit instead of firing cold network requests.
///
/// Call [prefetchAnalyticsData] as early as possible (e.g. immediately
/// after PIN is verified) and let it run in the background. Errors are
/// silently swallowed — the individual chart widgets will retry on their own.
class DashboardPrefetchService {
  DashboardPrefetchService._();

  static bool _prefetchStarted = false;

  /// Kick off all V2 analytics API calls in parallel.
  /// Safe to call multiple times — subsequent calls while a prefetch is
  /// already in-flight are no-ops.
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

    await Future.wait([
      safe(api.getDashboardSettingsV2),
      safe(api.getDashboardStatisticsV2),
      safe(api.getLeadConversionDataV2),
      safe(api.getLeadConversionByStatuses),
      safe(api.getLeadProcessSpeedV2),
      safe(api.getUsersChartV2),
      safe(api.getTaskChartDataV2),
      safe(api.getSourceOfLeadsChartV2),
      safe(api.getDealsByManagersV2),
      safe(api.getCompletedTasksChartV2),
      safe(api.getTelephonyAndEventsChartV2),
      safe(api.getOnlineStoreOrdersChartV2),
    ]);

    if (kDebugMode) {
      debugPrint('DashboardPrefetchService: prefetch complete ✅');
    }
  }

  /// Reset so the next login session can prefetch again.
  static void reset() => _prefetchStarted = false;
}
