import 'package:crm_task_manager/utils/safe_converters.dart';

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
      id: SafeConverters.toInt(json['id']),
      username: SafeConverters.toSafeString(json['username']),
      name: SafeConverters.toSafeString(json['name']),
      type: SafeConverters.toSafeString(json['type']),
      isActive: SafeConverters.toBool(json['is_active']),
      salesFunnelId: SafeConverters.toIntOrNull(json['sales_funnel_id']),
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
      text: SafeConverters.toSafeString(rawText),
      status: SafeConverters.toSafeString(rawStatus),
      author: _normalizeAuthor(SafeConverters.toSafeString(rawAuthor)),
      sentAt: SafeConverters.toDateTimeOrNull(rawDate),
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
}
