import 'package:crm_task_manager/services/chat_voice_player_service.dart';

/// Очередь голосовых одного чата.
/// Нужна, чтобы после окончания записи включить следующую.
class ChatVoiceCatalog {
  ChatVoiceCatalog._();

  static final Map<int, List<ChatVoiceTrack>> _byChat = {};

  static void replaceChat(int chatId, List<ChatVoiceTrack> tracks) {
    chatVoiceNextResolver ??= nextAfter;
    final unique = <int, ChatVoiceTrack>{};
    for (final track in tracks) {
      unique[track.messageId] = track;
    }
    final sorted = unique.values.toList()
      ..sort((a, b) => a.messageId.compareTo(b.messageId));
    _byChat[chatId] = sorted;
  }

  static ChatVoiceTrack? nextAfter(ChatVoiceTrack current) {
    return nextVoiceInChat(_byChat[current.chatId] ?? const [], current);
  }
}

/// Следующее голосовое — то, что новее текущего.
/// Список должен быть по возрастанию id сообщения.
ChatVoiceTrack? nextVoiceInChat(
  List<ChatVoiceTrack> ordered,
  ChatVoiceTrack current,
) {
  final index = ordered.indexWhere(
    (track) => track.messageId == current.messageId,
  );
  if (index >= 0) {
    if (index + 1 >= ordered.length) return null;
    return ordered[index + 1];
  }

  for (final track in ordered) {
    if (track.messageId > current.messageId) return track;
  }
  return null;
}
