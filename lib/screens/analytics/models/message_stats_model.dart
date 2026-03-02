import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Individual message statistics for a channel
class MessageStat {
  final String name;
  final int received;
  final int sent;

  MessageStat({
    required this.name,
    required this.received,
    required this.sent,
  });

  factory MessageStat.fromJson(Map<String, dynamic> json) {
    return MessageStat(
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Unknown'),
      received: SafeConverters.toInt(json['received']),
      sent: SafeConverters.toInt(json['sent']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'received': received,
      'sent': sent,
    };
  }

  int get total => received + sent;

  double get responseRate {
    if (received == 0) return 0.0;
    return (sent / received) * 100;
  }
}

/// Model for message statistics from /api/dashboard/message-stats
/// Response: {result: [{name, received, sent}]}
class MessageStatsResponse {
  final List<MessageStat> stats;

  MessageStatsResponse({required this.stats});

  factory MessageStatsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];

    if (result is List) {
      return MessageStatsResponse(
        stats: result.map((e) => MessageStat.fromJson(e)).toList(),
      );
    }

    // Return empty list if parsing fails
    return MessageStatsResponse(stats: []);
  }

  int get totalReceived {
    return stats.fold(0, (sum, stat) => sum + stat.received);
  }

  int get totalSent {
    return stats.fold(0, (sum, stat) => sum + stat.sent);
  }

  double get overallResponseRate {
    if (totalReceived == 0) return 0.0;
    return (totalSent / totalReceived) * 100;
  }

  List<MessageStat> get activeChannels {
    return stats.where((stat) => stat.total > 0).toList();
  }
}
