enum CallType { incoming, outgoing, missed }

class CallLogEntry {
  final String id;
  final String leadName;
  final String phoneNumber;
  final DateTime callDate;
  final CallType callType;
  final Duration? duration;
  final String? operatorName;
  final String? rating; // Новое поле
  final String? report; // Новое поле

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

    return CallLogEntry(
      id: json['id'].toString(),
      leadName: lead != null && lead['name'] != null ? lead['name'] : 'Неизвестно',
      phoneNumber: json['caller'] ?? json['destination_number'] ?? 'Неизвестно',
      callDate: DateTime.parse(json['call_started_at'] ?? DateTime.now().toIso8601String()),
      callType: callType,
      duration: json['call_duration'] != null
          ? Duration(seconds: json['call_duration'])
          : null,
      operatorName: json['user'] != null ? json['user']['name'] : null,
      rating: json['rating']?.toString(), // Парсинг рейтинга
      report: json['report']?.toString(), // Парсинг комментария
    );
  }
}