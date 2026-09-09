import 'package:crm_task_manager/utils/safe_converters.dart';

class EditedMessageSocketPayload {
  const EditedMessageSocketPayload({
    required this.messageId,
    this.text,
    this.chatId,
    this.isChanged = true,
  });

  final int messageId;
  final String? text;
  final int? chatId;
  final bool isChanged;

  static EditedMessageSocketPayload? tryParse(dynamic raw) {
    if (raw is! Map) return null;

    final root = Map<String, dynamic>.from(raw);
    final message = _extractMessageMap(root);
    if (message == null) return null;

    final messageId = SafeConverters.toIntOrNull(
      message['id'] ?? message['message_id'] ?? root['message_id'],
    );
    if (messageId == null || messageId <= 0) return null;

    final text = _extractText(message) ?? _extractText(root);
    final isChanged = SafeConverters.toBool(
      message['is_changed'] ??
          message['isChanged'] ??
          root['is_changed'] ??
          root['isChanged'],
      defaultValue: true,
    );

    return EditedMessageSocketPayload(
      messageId: messageId,
      text: text,
      chatId: _extractChatId(root, message),
      isChanged: isChanged,
    );
  }

  static Map<String, dynamic>? _extractMessageMap(Map<String, dynamic> root) {
    final direct = root['message'];
    if (direct is Map) {
      return Map<String, dynamic>.from(direct);
    }

    final data = root['data'];
    if (data is Map) {
      final nested = data['message'];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
      if (data['id'] != null || data['message_id'] != null) {
        return Map<String, dynamic>.from(data);
      }
    }

    if (root['id'] != null || root['message_id'] != null) {
      return root;
    }

    return null;
  }

  static String? _extractText(Map<String, dynamic> source) {
    for (final key in ['text', 'message', 'body', 'content']) {
      if (!source.containsKey(key)) continue;
      final value = source[key];
      if (value == null) continue;
      if (value is String) return value;
      return value.toString();
    }
    return null;
  }

  static int? _extractChatId(
    Map<String, dynamic> root,
    Map<String, dynamic> message,
  ) {
    final chat = root['chat'];
    final messageChat = message['chat'];
    return SafeConverters.toIntOrNull(
      root['chat_id'] ??
          root['chatId'] ??
          message['chat_id'] ??
          message['chatId'] ??
          (chat is Map ? chat['id'] : null) ??
          (messageChat is Map ? messageChat['id'] : null),
    );
  }
}
