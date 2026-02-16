import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class ConnectedAccount {
  final int integrationId;
  final String displayName;
  final String channelType;
  final String username;
  final int totalChats;
  final int answered;
  final int unanswered;
  final int successfulLeads;
  final int coldLeads;

  ConnectedAccount({
    required this.integrationId,
    required this.displayName,
    required this.channelType,
    required this.username,
    required this.totalChats,
    required this.answered,
    required this.unanswered,
    required this.successfulLeads,
    required this.coldLeads,
  });

  factory ConnectedAccount.fromJson(Map<String, dynamic> json) {
    return ConnectedAccount(
      integrationId: SafeConverters.toInt(json['integration_id']),
      displayName: SafeConverters.toSafeString(json['display_name']),
      channelType: SafeConverters.toSafeString(json['channel_type']),
      username: SafeConverters.toSafeString(json['username']),
      totalChats: SafeConverters.toInt(json['total_chats']),
      answered: SafeConverters.toInt(json['answered']),
      unanswered: SafeConverters.toInt(json['unanswered']),
      successfulLeads: SafeConverters.toInt(json['successful_leads']),
      coldLeads: SafeConverters.toInt(json['cold_leads']),
    );
  }
}

class ConnectedAccountsTotals {
  final int totalAccounts;
  final int activeAccounts;
  final int totalChats;
  final int answered;
  final int unanswered;
  final int successfulLeads;
  final int coldLeads;

  ConnectedAccountsTotals({
    required this.totalAccounts,
    required this.activeAccounts,
    required this.totalChats,
    required this.answered,
    required this.unanswered,
    required this.successfulLeads,
    required this.coldLeads,
  });

  factory ConnectedAccountsTotals.fromJson(Map<String, dynamic> json) {
    return ConnectedAccountsTotals(
      totalAccounts: SafeConverters.toInt(json['total_accounts']),
      activeAccounts: SafeConverters.toInt(json['active_accounts']),
      totalChats: SafeConverters.toInt(json['total_chats']),
      answered: SafeConverters.toInt(json['answered']),
      unanswered: SafeConverters.toInt(json['unanswered']),
      successfulLeads: SafeConverters.toInt(json['successful_leads']),
      coldLeads: SafeConverters.toInt(json['cold_leads']),
    );
  }
}

class ConnectedAccountsResponse {
  final List<ConnectedAccount> channels;
  final ConnectedAccountsTotals totals;
  final String bestAccount;

  ConnectedAccountsResponse({
    required this.channels,
    required this.totals,
    required this.bestAccount,
  });

  factory ConnectedAccountsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final channels = result['channels'];
      return ConnectedAccountsResponse(
        channels: channels is List
            ? channels.map((e) => ConnectedAccount.fromJson(e)).toList()
            : <ConnectedAccount>[],
        totals: ConnectedAccountsTotals.fromJson(
          result['totals'] is Map<String, dynamic>
              ? result['totals']
              : <String, dynamic>{},
        ),
        bestAccount:
            SafeConverters.toSafeString(result['best_account'], defaultValue: ''),
      );
    }

    return ConnectedAccountsResponse(
      channels: [],
      totals: ConnectedAccountsTotals(
        totalAccounts: 0,
        activeAccounts: 0,
        totalChats: 0,
        answered: 0,
        unanswered: 0,
        successfulLeads: 0,
        coldLeads: 0,
      ),
      bestAccount: '',
    );
  }
}
