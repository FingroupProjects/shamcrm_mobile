class SmsSenderIntegration {
  final int id;
  final String username;
  final String name;
  final String type;
  final bool isActive;
  final int? salesFunnelId;

  const SmsSenderIntegration({
    required this.id,
    required this.username,
    required this.name,
    required this.type,
    required this.isActive,
    this.salesFunnelId,
  });

  String get displayName => username.isNotEmpty ? username : name;

  factory SmsSenderIntegration.fromJson(Map<String, dynamic> json) {
    return SmsSenderIntegration(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      username: (json['username'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      salesFunnelId: json['sales_funnel_id'] is int
          ? json['sales_funnel_id'] as int
          : int.tryParse('${json['sales_funnel_id']}'),
    );
  }
}

class LeadSmsMessage {
  final String text;
  final String status;
  final String author;
  final DateTime? sentAt;

  const LeadSmsMessage({
    required this.text,
    required this.status,
    required this.author,
    required this.sentAt,
  });

  factory LeadSmsMessage.fromJson(Map<String, dynamic> json) {
    final rawText = json['text'] ??
        json['message'] ??
        json['body'] ??
        json['content'] ??
        json['sms_text'];
    final rawStatus = json['status'] ??
        json['message_status'] ??
        json['delivery_status'] ??
        json['state'];
    final rawAuthor = _extractAuthor(json);
    final rawDate = json['created_at'] ??
        json['sent_at'] ??
        json['date_send'] ??
        json['date'] ??
        json['updated_at'];

    return LeadSmsMessage(
      text: (rawText ?? '').toString(),
      status: (rawStatus ?? '').toString(),
      author: _normalizeAuthor((rawAuthor ?? '').toString()),
      sentAt: _tryParseDate(rawDate),
    );
  }

  static dynamic _extractAuthor(Map<String, dynamic> json) {
    final author = json['author'];
    if (author is Map<String, dynamic>) {
      return author['name'] ?? author['fullname'] ?? author['username'];
    }

    final createdBy = json['created_by'];
    if (createdBy is Map<String, dynamic>) {
      return createdBy['name'] ??
          createdBy['fullname'] ??
          createdBy['username'];
    }

    return json['created_by_name'] ??
        json['sender_name'] ??
        json['user_name'] ??
        json['username'] ??
        author;
  }

  static String _normalizeAuthor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.contains('@')) {
      final beforeAt = trimmed.split('@').first.trim();
      if (beforeAt.isNotEmpty) {
        return beforeAt;
      }
    }

    final cleaned = trimmed.replaceAll(RegExp(r'^\d+\s*[-:]\s*'), '');
    return cleaned;
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
