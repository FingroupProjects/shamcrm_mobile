import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

class ChatMessagesPagination {
  final int count;
  final int total;
  final int perPage;
  final int currentPage;
  final int totalPages;

  const ChatMessagesPagination({
    required this.count,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory ChatMessagesPagination.fromJson(
    Map<String, dynamic>? json, {
    required int fallbackCount,
  }) {
    final source = json ?? const <String, dynamic>{};

    final count = SafeConverters.toInt(source['count'], defaultValue: fallbackCount);
    final total = SafeConverters.toInt(source['total'], defaultValue: count);
    final perPage = SafeConverters.toInt(
      source['per_page'],
      defaultValue: count == 0 ? fallbackCount : count,
    );
    final currentPage = SafeConverters.toInt(source['current_page'], defaultValue: 1);
    final totalPages = SafeConverters.toInt(source['total_pages'], defaultValue: 1);

    return ChatMessagesPagination(
      count: count,
      total: total,
      perPage: perPage,
      currentPage: currentPage,
      totalPages: totalPages < 1 ? 1 : totalPages,
    );
  }
}

class ChatMessagesPage {
  final List<Message> data;
  final ChatMessagesPagination meta;

  const ChatMessagesPage({
    required this.data,
    required this.meta,
  });

  factory ChatMessagesPage.fromJson(
    Map<String, dynamic> json, {
    String? chatType,
  }) {
    final result = json['result'];

    final resultMap = SafeConverters.toMapOrNull(result) ?? const <String, dynamic>{};

    final rawData = result is List
        ? SafeConverters.toList(result)
        : SafeConverters.toList(resultMap['data']).isNotEmpty
            ? SafeConverters.toList(resultMap['data'])
            : SafeConverters.toList(json['data']);

    final messages = rawData
        .map((item) => SafeConverters.toMapOrNull(item))
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => Message.fromJson(item, chatType: chatType),
        )
        .toList()
      ..sort((a, b) => _compareMessagesByCreatedAtDesc(a, b));

    final paginationJson = SafeConverters.toMapOrNull(resultMap['pagination']) ??
        SafeConverters.toMapOrNull(json['pagination']);

    return ChatMessagesPage(
      data: messages,
      meta: ChatMessagesPagination.fromJson(
        paginationJson,
        fallbackCount: messages.length,
      ),
    );
  }
}

int _compareMessagesByCreatedAtDesc(Message left, Message right) {
  final leftDate = _tryParseMessageDate(left.createMessateTime);
  final rightDate = _tryParseMessageDate(right.createMessateTime);

  if (leftDate != null && rightDate != null) {
    return rightDate.compareTo(leftDate);
  }
  if (leftDate != null) return -1;
  if (rightDate != null) return 1;
  return right.createMessateTime.compareTo(left.createMessateTime);
}

DateTime? _tryParseMessageDate(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty) return null;
  return DateTime.tryParse(normalized)?.toUtc();
}
