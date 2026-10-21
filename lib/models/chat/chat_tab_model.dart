import 'package:crm_task_manager/utils/safe_converters.dart';

class ChatTab {
  final int id;
  final String name;
  final String? icon;
  final bool isForAll;
  final int? salesFunnelId;
  final int? organizationId;
  final int? chatsCount;
  final int? unreadCount;
  final List<int> chatIds;
  final String? type;
  final String? autoAssignType;
  final List<int> integrationIds;
  final bool? assignExistingChats;

  const ChatTab({
    required this.id,
    required this.name,
    this.icon,
    this.isForAll = true,
    this.salesFunnelId,
    this.organizationId,
    this.chatsCount,
    this.unreadCount,
    this.chatIds = const [],
    this.type,
    this.autoAssignType,
    this.integrationIds = const [],
    this.assignExistingChats,
  });

  factory ChatTab.fromJson(Map<String, dynamic> json) {
    List<int> parsedChatIds = [];
    if (json['chat_ids'] != null && json['chat_ids'] is List) {
      parsedChatIds = (json['chat_ids'] as List)
          .map((e) => SafeConverters.toInt(e))
          .where((id) => id > 0)
          .toList();
    } else if (json['chats'] != null && json['chats'] is List) {
      parsedChatIds = (json['chats'] as List)
          .map((e) {
            if (e is Map) {
              return SafeConverters.toInt(e['id']);
            }
            return SafeConverters.toInt(e);
          })
          .where((id) => id > 0)
          .toList();
    }

    List<int> parsedIntegrationIds = [];
    if (json['integration_ids'] != null && json['integration_ids'] is List) {
      parsedIntegrationIds = (json['integration_ids'] as List)
          .map((e) => SafeConverters.toInt(e))
          .where((id) => id > 0)
          .toList();
    } else if (json['integrations'] != null && json['integrations'] is List) {
      parsedIntegrationIds = (json['integrations'] as List)
          .map((e) {
            if (e is Map) {
              return SafeConverters.toInt(e['id']);
            }
            return SafeConverters.toInt(e);
          })
          .where((id) => id > 0)
          .toList();
    }

    return ChatTab(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      icon: SafeConverters.toStringOrNull(json['icon']),
      isForAll: json['is_for_all'] == true ||
          json['is_for_all'] == 1 ||
          json['is_for_all'] == '1',
      salesFunnelId: SafeConverters.toIntOrNull(json['sales_funnel_id']),
      organizationId: SafeConverters.toIntOrNull(json['organization_id']),
      chatsCount:
          SafeConverters.toIntOrNull(json['chats_count'] ?? json['count']),
      unreadCount: SafeConverters.toIntOrNull(json['unread_count']),
      chatIds: parsedChatIds,
      type: SafeConverters.toStringOrNull(json['type']),
      autoAssignType: SafeConverters.toStringOrNull(json['auto_assign_type']),
      integrationIds: parsedIntegrationIds,
      assignExistingChats: json['assign_existing_chats'] == true ||
          json['assign_existing_chats'] == 1 ||
          json['assign_existing_chats'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (icon != null) 'icon': icon,
      'is_for_all': isForAll,
      if (salesFunnelId != null) 'sales_funnel_id': salesFunnelId,
      if (organizationId != null) 'organization_id': organizationId,
      if (chatsCount != null) 'chats_count': chatsCount,
      if (unreadCount != null) 'unread_count': unreadCount,
      'chat_ids': chatIds,
      if (type != null) 'type': type,
      if (autoAssignType != null) 'auto_assign_type': autoAssignType,
      if (integrationIds.isNotEmpty) 'integration_ids': integrationIds,
      if (assignExistingChats != null)
        'assign_existing_chats': assignExistingChats,
    };
  }

  ChatTab copyWith({
    int? id,
    String? name,
    String? icon,
    bool? isForAll,
    int? salesFunnelId,
    int? organizationId,
    int? chatsCount,
    int? unreadCount,
    List<int>? chatIds,
    String? type,
    String? autoAssignType,
    List<int>? integrationIds,
    bool? assignExistingChats,
  }) {
    return ChatTab(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isForAll: isForAll ?? this.isForAll,
      salesFunnelId: salesFunnelId ?? this.salesFunnelId,
      organizationId: organizationId ?? this.organizationId,
      chatsCount: chatsCount ?? this.chatsCount,
      unreadCount: unreadCount ?? this.unreadCount,
      chatIds: chatIds ?? this.chatIds,
      type: type ?? this.type,
      autoAssignType: autoAssignType ?? this.autoAssignType,
      integrationIds: integrationIds ?? this.integrationIds,
      assignExistingChats: assignExistingChats ?? this.assignExistingChats,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatTab &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          icon == other.icon &&
          isForAll == other.isForAll &&
          salesFunnelId == other.salesFunnelId &&
          chatsCount == other.chatsCount &&
          type == other.type;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      (icon?.hashCode ?? 0) ^
      isForAll.hashCode ^
      (salesFunnelId?.hashCode ?? 0) ^
      (type?.hashCode ?? 0);
}
