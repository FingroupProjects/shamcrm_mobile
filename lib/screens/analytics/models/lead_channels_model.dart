import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Individual lead channel data
class LeadChannel {
  final int id;
  final String name;
  final int count;
  final String? color;

  LeadChannel({
    required this.id,
    required this.name,
    required this.count,
    this.color,
  });

  factory LeadChannel.fromJson(Map<String, dynamic> json) {
    return LeadChannel(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Unknown'),
      count: SafeConverters.toInt(json['count']),
      color: json['color'] != null
          ? SafeConverters.toSafeString(json['color'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'count': count,
      if (color != null) 'color': color,
    };
  }

  double getPercentage(int total) {
    if (total == 0) return 0.0;
    return (count / total) * 100;
  }
}

/// Model for lead channels from /api/dashboard/lead-channels
/// Response: {result: [{id, name, count, color?}]}
class LeadChannelsResponse {
  final List<LeadChannel> channels;

  LeadChannelsResponse({required this.channels});

  factory LeadChannelsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];

    if (result is List) {
      return LeadChannelsResponse(
        channels: result.map((e) => LeadChannel.fromJson(e)).toList(),
      );
    }

    // Return empty list if parsing fails
    return LeadChannelsResponse(channels: []);
  }

  int get totalLeads {
    return channels.fold(0, (sum, channel) => sum + channel.count);
  }

  List<LeadChannel> get activeChannels {
    return channels.where((channel) => channel.count > 0).toList();
  }

  List<LeadChannel> get topChannels {
    final sorted = List<LeadChannel>.from(channels)
      ..sort((a, b) => b.count.compareTo(a.count));
    return sorted.take(5).toList();
  }

  LeadChannel? get topChannel {
    if (channels.isEmpty) return null;
    return channels.reduce((a, b) => a.count > b.count ? a : b);
  }
}
