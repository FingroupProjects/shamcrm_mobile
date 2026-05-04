import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Model for lead channel data from /api/dashboard/lead-channels
class LeadChannelModel {
  final int id;
  final String name;
  final int count;

  LeadChannelModel({
    required this.id,
    required this.name,
    required this.count,
  });

  factory LeadChannelModel.fromJson(Map<String, dynamic> json) {
    return LeadChannelModel(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Unknown'),
      count: SafeConverters.toInt(json['count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'count': count,
    };
  }
}
