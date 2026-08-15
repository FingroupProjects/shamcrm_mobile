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

  String get displayName {
    final candidates = [name, username, type];
    for (final value in candidates) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return id > 0 ? 'ID $id' : '';
  }

  factory SmsSenderIntegration.fromJson(Map<String, dynamic> json) {
    final nested = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final integration = json['integration'] is Map<String, dynamic>
        ? json['integration'] as Map<String, dynamic>
        : const <String, dynamic>{};

    String firstText(List<dynamic> values) {
      for (final value in values) {
        final text = SafeConverters.toSafeString(value).trim();
        if (text.isNotEmpty && text != 'null') return text;
      }
      return '';
    }

    return SmsSenderIntegration(
      id: SafeConverters.toInt(json['id'] ?? integration['id']),
      username: firstText([
        json['username'],
        nested['username'],
        integration['username'],
        json['login'],
        nested['login'],
        json['phone'],
        nested['phone'],
        json['sender'],
        nested['sender'],
        json['sender_name'],
        nested['sender_name'],
        json['alphaname'],
        nested['alphaname'],
        json['alpha_name'],
        nested['alpha_name'],
      ]),
      name: firstText([
        json['name'],
        nested['name'],
        integration['name'],
        json['title'],
        nested['title'],
        json['display_name'],
        nested['display_name'],
        json['label'],
        nested['label'],
      ]),
      type: firstText([
        json['type'],
        nested['type'],
        integration['type'],
      ]),
      isActive: SafeConverters.toBool(
          json['is_active'] ?? integration['is_active']),
      salesFunnelId: SafeConverters.toIntOrNull(
          json['sales_funnel_id'] ?? integration['sales_funnel_id']),
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
