import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:crm_task_manager/utils/utf16_sanitizer.dart';

enum CallType { incoming, outgoing, missed, outgoingMissed }

class CallLogEntry {
  final String id;
  final int? leadId;
  final String leadName;
  final String phoneNumber;
  final String? destinationNumber;
  /// Our PSTN / outbound caller ID from the telephony provider (e.g. 992488886363).
  final String? trunk;
  final DateTime callDate;
  final CallType callType;
  final Duration? duration;
  final String? operatorName;
  final String? rating;
  final String? report;

  CallLogEntry({
    required this.id,
    this.leadId,
    required this.leadName,
    required this.phoneNumber,
    this.destinationNumber,
    this.trunk,
    required this.callDate,
    required this.callType,
    this.duration,
    this.operatorName,
    this.rating,
    this.report,
  });

  /// Number shown to the client on our outgoing calls.
  /// We trust only the explicit backend `trunk` field here.
  String? get outboundCallerNumber {
    final trunkNumber = trunk?.trim() ?? '';
    if (trunkNumber.isNotEmpty) return trunkNumber;
    return null;
  }

  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    final lead = SafeConverters.toMapOrNull(json['lead']);
    final isMissed = SafeConverters.toBool(json['missed']);
    final isIncoming = SafeConverters.toBool(json['incoming']);
    final callType = isMissed
        ? (isIncoming ? CallType.missed : CallType.outgoingMissed)
        : isIncoming
            ? CallType.incoming
            : CallType.outgoing;

    // Вспомогательная функция для парсинга нестандартного формата "YYYY-MM-DD HH:mm"
    DateTime? parseCustomDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        // Предполагаем формат "2025-07-02 06:36"
        final parts = dateStr.split(' ');
        if (parts.length != 2) return null;
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        if (dateParts.length != 3 || timeParts.length != 2) return null;

        return DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      } catch (e) {
        return null;
      }
    }

    // Логика выбора даты
    DateTime callDate;
    if (json['call_started_at'] != null) {
      callDate = SafeConverters.toDateTimeOrNull(json['call_started_at']) ??
          DateTime.now();
    } else {
      callDate = parseCustomDate(json['created_at']) ??
          parseCustomDate(json['updated_at']) ??
          DateTime.now();
    }

    final trunkRaw = json['trunk']?.toString().trim();

    return CallLogEntry(
      id: SafeConverters.toSafeString(json['id']),
      leadId: SafeConverters.toIntOrNull(lead?['id']),
      leadName: sanitizeUtf16(
        lead != null && lead['name'] != null
            ? lead['name'].toString()
            : 'Неизвестно',
      ),
      phoneNumber: sanitizeUtf16(
        (json['caller'] ?? json['destination_number'] ?? 'Неизвестно')
            .toString(),
      ),
      destinationNumber: json['destination_number'] == null
          ? null
          : sanitizeUtf16(json['destination_number'].toString()),
      trunk: (trunkRaw == null || trunkRaw.isEmpty)
          ? null
          : sanitizeUtf16(trunkRaw),
      callDate: callDate,
      callType: callType,
      duration: json['call_duration'] != null
          ? Duration(seconds: SafeConverters.toInt(json['call_duration']))
          : null,
      operatorName: json['user']?['name'] == null
          ? null
          : sanitizeUtf16(json['user']['name'].toString()),
      rating: json['rating'] == null
          ? null
          : sanitizeUtf16(json['rating'].toString()),
      report: json['report'] == null
          ? null
          : sanitizeUtf16(json['report'].toString()),
    );
  }
}
