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

  /// Client-facing title: lead name, or phone when the name is empty.
  String get displayTitle {
    final name = leadName.trim();
    if (name.isNotEmpty && name != 'Неизвестно') return name;
    final phone = phoneNumber.trim();
    return phone.isEmpty ? leadName : phone;
  }

  /// Extra line under the title. Hidden when name and phone are the same.
  String? get displaySubtitle {
    final phone = phoneNumber.trim();
    if (phone.isEmpty) return null;
    if (sameLeadNameAndPhone(leadName, phone)) return null;
    return phone;
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

    // call_started_at comes as UTC (09:56Z). Convert to the device timezone (14:56).
    DateTime callDate;
    if (json['call_started_at'] != null) {
      callDate = _parseCallDateTime(json['call_started_at']) ?? DateTime.now();
    } else {
      callDate = _parseCallDateTime(json['created_at']) ??
          _parseCallDateTime(json['updated_at']) ??
          DateTime.now();
    }

    final trunkRaw = json['trunk']?.toString().trim();
    final leadNameRaw = lead != null && lead['name'] != null
        ? lead['name'].toString()
        : '';
    final leadPhoneRaw = lead != null && lead['phone'] != null
        ? lead['phone'].toString()
        : '';
    // Client number is lead.phone, not the telephony caller/trunk.
    final clientPhone = leadPhoneRaw.trim().isNotEmpty
        ? leadPhoneRaw
        : (json['destination_number'] ?? json['caller'] ?? 'Неизвестно')
            .toString();

    return CallLogEntry(
      id: SafeConverters.toSafeString(json['id']),
      leadId: SafeConverters.toIntOrNull(lead?['id']),
      leadName: sanitizeUtf16(
        leadNameRaw.trim().isNotEmpty ? leadNameRaw : 'Неизвестно',
      ),
      phoneNumber: sanitizeUtf16(clientPhone),
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

/// Parses server call timestamps and converts UTC instants to local time.
DateTime? _parseCallDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();

  final parsed = SafeConverters.toDateTimeOrNull(value);
  if (parsed != null) return parsed.toLocal();

  final dateStr = value.toString().trim();
  if (dateStr.isEmpty) return null;
  try {
    final parts = dateStr.split(' ');
    if (parts.length != 2) return null;
    final dateParts = parts[0].split('-');
    final timeParts = parts[1].split(':');
    if (dateParts.length != 3 || timeParts.length < 2) return null;
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

bool sameLeadNameAndPhone(String name, String phone) {
  final normalizedName = name.trim().toLowerCase();
  final normalizedPhone = phone.trim().toLowerCase();
  if (normalizedName.isEmpty || normalizedPhone.isEmpty) return false;
  if (normalizedName == normalizedPhone) return true;

  final nameDigits = normalizedName.replaceAll(RegExp(r'\D'), '');
  final phoneDigits = normalizedPhone.replaceAll(RegExp(r'\D'), '');
  return nameDigits.isNotEmpty && nameDigits == phoneDigits;
}
