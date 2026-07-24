enum CallType { incoming, outgoing, missed, outgoingMissed }

class CallLogEntry {
  final String id;
  final int? leadId;
  final String leadName;
  final String phoneNumber;
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
    required this.callDate,
    required this.callType,
    this.duration,
    this.operatorName,
    this.rating,
    this.report,
  });

  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    final lead = json['lead'] as Map<String, dynamic>?;
    final isMissed = json['missed'] == true || json['missed'] == 1;
    final isIncoming = json['incoming'] == true || json['incoming'] == 1;
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

    String pickOptionalString(List<Object?> values) {
      for (final value in values) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty &&
            text.toLowerCase() != 'null' &&
            text != 'Неизвестно') {
          return text;
        }
      }
      return '';
    }

    String pickString(List<Object?> values) {
      final value = pickOptionalString(values);
      return value.isEmpty ? 'Неизвестно' : value;
    }

    String leadPhone() {
      if (lead == null) return '';
      return pickOptionalString([
        lead['phone'],
        lead['phone_number'],
        lead['wa_phone'],
        lead['whatsapp'],
        lead['telegram'],
      ]);
    }

    final phoneNumber = isIncoming
        ? pickString([
            json['caller'],
            json['from'],
            json['client_phone'],
            json['phone_number'],
            json['phone'],
            leadPhone(),
            json['destination_number'],
          ])
        : pickString([
            json['destination_number'],
            json['callee'],
            json['to'],
            json['client_phone'],
            json['phone_number'],
            json['phone'],
            leadPhone(),
            json['caller'],
          ]);

    // Логика выбора даты
    DateTime callDate;
    if (json['call_started_at'] != null) {
      callDate = DateTime.parse(json['call_started_at']);
    } else {
      callDate = parseCustomDate(json['created_at']) ??
          parseCustomDate(json['updated_at']) ??
          DateTime.now();
    }

    return CallLogEntry(
      id: json['id'].toString(),
      leadId: lead?['id'] is int
          ? lead!['id'] as int
          : int.tryParse(lead?['id']?.toString() ?? ''),
      leadName:
          lead != null && lead['name'] != null ? lead['name'] : 'Неизвестно',
      phoneNumber: phoneNumber,
      callDate: callDate,
      callType: callType,
      duration: json['call_duration'] != null
          ? Duration(seconds: json['call_duration'])
          : null,
      operatorName: json['user'] != null ? json['user']['name'] : null,
      rating: json['rating']?.toString(),
      report: json['report']?.toString(),
    );
  }
}
