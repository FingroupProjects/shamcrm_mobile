import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class LeadSourceItem {
  final String name;
  final int count;

  LeadSourceItem({
    required this.name,
    required this.count,
  });
}

/// Model for /api/v2/dashboard/source-of-leads-chart
class SourceOfLeadsChartResponse {
  final List<LeadSourceItem> sources;
  final String bestSource;
  final int totalSources;

  SourceOfLeadsChartResponse({
    required this.sources,
    required this.bestSource,
    required this.totalSources,
  });

  factory SourceOfLeadsChartResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final sourcesRaw = result['sources'];
      final items = <LeadSourceItem>[];
      if (sourcesRaw is Map<String, dynamic>) {
        sourcesRaw.forEach((key, value) {
          items.add(LeadSourceItem(
            name: SafeConverters.toSafeString(key),
            count: SafeConverters.toInt(value),
          ));
        });
      }

      items.sort((a, b) => b.count.compareTo(a.count));

      final bestSource = SafeConverters.toSafeString(
        result['best_source'],
        defaultValue: items.isNotEmpty ? items.first.name : '',
      );

      return SourceOfLeadsChartResponse(
        sources: items,
        bestSource: bestSource,
        totalSources: SafeConverters.toInt(result['total_sources']),
      );
    }

    return SourceOfLeadsChartResponse(
      sources: [],
      bestSource: '',
      totalSources: 0,
    );
  }

  List<LeadSourceItem> get activeSources =>
      sources.where((item) => item.count > 0).toList();
}
