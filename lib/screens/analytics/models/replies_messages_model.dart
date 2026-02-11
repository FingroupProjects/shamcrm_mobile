import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class ReplyChannelStats {
  final String channelName;
  final int sentMessages;
  final int receivedMessages;
  final int unansweredChats;

  ReplyChannelStats({
    required this.channelName,
    required this.sentMessages,
    required this.receivedMessages,
    required this.unansweredChats,
  });

  factory ReplyChannelStats.fromJson(Map<String, dynamic> json) {
    return ReplyChannelStats(
      channelName: SafeConverters.toSafeString(json['channel_name'], defaultValue: 'Unknown'),
      sentMessages: SafeConverters.toInt(json['sent_messages']),
      receivedMessages: SafeConverters.toInt(json['received_messages']),
      unansweredChats: SafeConverters.toInt(json['unanswered_chats']),
    );
  }
}

class RepliesMessagesTotals {
  final int sentMessages;
  final int receivedMessages;
  final int unansweredChats;

  RepliesMessagesTotals({
    required this.sentMessages,
    required this.receivedMessages,
    required this.unansweredChats,
  });

  factory RepliesMessagesTotals.fromJson(Map<String, dynamic> json) {
    return RepliesMessagesTotals(
      sentMessages: SafeConverters.toInt(json['sent_messages']),
      receivedMessages: SafeConverters.toInt(json['received_messages']),
      unansweredChats: SafeConverters.toInt(json['unanswered_chats']),
    );
  }
}

class RepliesToMessagesResponse {
  final List<ReplyChannelStats> byChannel;
  final RepliesMessagesTotals totals;

  RepliesToMessagesResponse({
    required this.byChannel,
    required this.totals,
  });

  factory RepliesToMessagesResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final channels = result['by_channel'];
      return RepliesToMessagesResponse(
        byChannel: channels is List
            ? channels.map((e) => ReplyChannelStats.fromJson(e)).toList()
            : <ReplyChannelStats>[],
        totals: RepliesMessagesTotals.fromJson(
          result['total'] is Map<String, dynamic>
              ? result['total']
              : <String, dynamic>{},
        ),
      );
    }

    return RepliesToMessagesResponse(
      byChannel: [],
      totals: RepliesMessagesTotals(sentMessages: 0, receivedMessages: 0, unansweredChats: 0),
    );
  }
}
