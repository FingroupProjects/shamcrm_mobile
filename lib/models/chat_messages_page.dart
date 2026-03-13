import 'package:crm_task_manager/models/chats_model.dart';

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

    int parseInt(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    final count = parseInt(source['count'], fallbackCount);
    final total = parseInt(source['total'], count);
    final perPage =
        parseInt(source['per_page'], count == 0 ? fallbackCount : count);
    final currentPage = parseInt(source['current_page'], 1);
    final totalPages = parseInt(source['total_pages'], 1);

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

    final Map<String, dynamic> resultMap =
        result is Map<String, dynamic> ? result : const <String, dynamic>{};

    final rawData = result is List
        ? result
        : resultMap['data'] is List
            ? resultMap['data'] as List
            : json['data'] is List
                ? json['data'] as List
                : const [];

    final messages = rawData
        .whereType<Map>()
        .map(
          (item) => Message.fromJson(
            Map<String, dynamic>.from(item),
            chatType: chatType,
          ),
        )
        .toList()
      ..sort((a, b) => b.createMessateTime.compareTo(a.createMessateTime));

    final paginationJson = resultMap['pagination'] is Map<String, dynamic>
        ? resultMap['pagination'] as Map<String, dynamic>
        : json['pagination'] is Map<String, dynamic>
            ? json['pagination'] as Map<String, dynamic>
            : null;

    return ChatMessagesPage(
      data: messages,
      meta: ChatMessagesPagination.fromJson(
        paginationJson,
        fallbackCount: messages.length,
      ),
    );
  }
}
