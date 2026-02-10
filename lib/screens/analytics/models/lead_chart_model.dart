import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Individual lead chart item with status and data
class LeadChartItem {
  final String status;
  final String color;
  final List<int> data;

  LeadChartItem({
    required this.status,
    required this.color,
    required this.data,
  });

  factory LeadChartItem.fromJson(Map<String, dynamic> json) {
    return LeadChartItem(
      status: SafeConverters.toSafeString(json['status']),
      color:
          SafeConverters.toSafeString(json['color'], defaultValue: '#4ae6b3'),
      data: SafeConverters.toIntList(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'color': color,
      'data': data,
    };
  }

  int get total => data.isEmpty ? 0 : data.reduce((a, b) => a + b);
}

/// Model for lead chart from /api/dashboard/lead-chart
/// Response: [{status, color, data: [int, int]}]
class LeadChartResponse {
  final List<LeadChartItem> items;

  LeadChartResponse({required this.items});

  factory LeadChartResponse.fromJson(dynamic json) {
    if (json is List) {
      return LeadChartResponse(
        items: json.map((e) => LeadChartItem.fromJson(e)).toList(),
      );
    }

    // Return empty list if parsing fails
    return LeadChartResponse(items: []);
  }

  int get totalLeads {
    return items.fold(0, (sum, item) => sum + item.total);
  }

  List<String> get statuses => items.map((e) => e.status).toList();
}
