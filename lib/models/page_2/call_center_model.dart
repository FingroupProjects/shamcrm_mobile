enum CallType { incoming, outgoing, missed }

class CallLogEntry {
  final String id;
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
    final callType = json['missed'] == true
        ? CallType.missed
        : json['incoming'] == true
            ? CallType.incoming
            : CallType.outgoing;

    // Вспомогательная функция для парсинга нестандартного формата "YYYY-MM-DD HH:mm"
    DateTime? _parseCustomDate(String? dateStr) {
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
      callDate = DateTime.parse(json['call_started_at']);
    } else {
      callDate = _parseCustomDate(json['created_at']) ??
                 _parseCustomDate(json['updated_at']) ??
                 DateTime.now();
    }

    return CallLogEntry(
      id: json['id'].toString(),
      leadName: lead != null && lead['name'] != null ? lead['name'] : 'Неизвестно',
      phoneNumber: json['caller'] ?? json['destination_number'] ?? 'Неизвестно',
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