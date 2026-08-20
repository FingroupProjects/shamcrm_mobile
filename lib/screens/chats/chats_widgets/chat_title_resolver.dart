import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chat/chatGetId_model.dart';
import 'package:crm_task_manager/utils/global_value.dart';

class ChatTitleResolver {
  static const Set<String> _placeholders = {
    '',
    'null',
    'без имени',
    'без названия',
    'no name',
    'nomsiz',
  };

  static const Set<String> _channelTitles = {
    'telegram_account',
    'telegram_bot',
    'mini_app',
    'whatsapp',
    'green_api',
    'instagram',
    'instagram_comment',
    'facebook',
    'messenger',
    'phone',
    'email',
    'site',
  };

  static bool isPlaceholder(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return true;
    final normalized = trimmed.toLowerCase();
    if (_placeholders.contains(normalized)) return true;
    if (_channelTitles.contains(normalized)) return true;
    return false;
  }

  static String? clean(String? value) {
    if (isPlaceholder(value)) return null;
    return value!.trim();
  }

  static String? fromPush({
    Map<String, dynamic>? data,
    String? notificationTitle,
  }) {
    final payload = data ?? const <String, dynamic>{};
    final candidates = <String?>[
      payload['sender_name']?.toString(),
      payload['chat_name']?.toString(),
      payload['lead_name']?.toString(),
      payload['client_name']?.toString(),
      payload['name']?.toString(),
      payload['title']?.toString(),
      notificationTitle,
    ];
    for (final candidate in candidates) {
      final cleaned = clean(candidate);
      if (cleaned != null) return cleaned;
    }
    return null;
  }

  static String? fromChat(ChatsGetId chat, {String? currentUserId}) {
    final groupName = clean(chat.group?.name);
    if (groupName != null) return groupName;

    final parsedName = clean(chat.name);
    if (parsedName != null) return parsedName;

    final myId = (currentUserId ?? userID.value).trim();
    String? firstAvailableUserName;
    for (final user in chat.chatUsers) {
      final userName = clean(user.participant.name);
      if (userName == null) continue;
      firstAvailableUserName ??= userName;
      if (myId.isNotEmpty &&
          myId != 'null' &&
          user.participant.id.toString() == myId) {
        continue;
      }
      return userName;
    }
    if (firstAvailableUserName != null) return firstAvailableUserName;

    return null;
  }

  static Future<String> resolve({
    required ApiService apiService,
    required ChatsGetId chat,
    String? currentUserId,
    String? pushFallback,
  }) async {
    final immediate = fromChat(chat, currentUserId: currentUserId);
    if (immediate != null) return immediate;

    final fromPushTitle = clean(pushFallback);
    if (fromPushTitle != null) return fromPushTitle;

    if (chat.type == 'lead') {
      try {
        final profile = await apiService.getChatProfile(chat.id);
        final profileName = clean(profile.name);
        if (profileName != null) return profileName;
      } catch (_) {}
    }

    if (chat.type == 'task') {
      try {
        final profile = await apiService.getTaskProfile(chat.id);
        final profileName = clean(profile.name);
        if (profileName != null) return profileName;
      } catch (_) {}
    }

    return '';
  }
}
