import 'package:intl/intl.dart';

enum CallType { incoming, outgoing, missed }

class CallLogEntry {
  final int id; // Изменено на int, так как API ожидает ID
  final String? leadName;
  final String? phoneNumber;
  final DateTime? callDate;
  final CallType callType;
  final Duration? duration;
  final String? operatorName;
  final int? organizationId;
  final int? managerId;
  final int? leadId;
  final String? status; // ANSWER, BUSY, NOANSWER, CANCEL
  final int? rating;
  final bool? notAnswered;

  CallLogEntry({
    required this.id,
    this.leadName,
    this.phoneNumber,
    this.callDate,
    required this.callType,
    this.duration,
    this.operatorName,
    this.organizationId,
    this.managerId,
    this.leadId,
    this.status,
    this.rating,
    this.notAnswered,
  });

  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    CallType callType;
    switch (json['call_type']) {
      case 'incoming':
        callType = CallType.incoming;
        break;
      case 'outgoing':
        callType = CallType.outgoing;
        break;
      case 'missed':
        callType = CallType.missed;
        break;
      default:
        callType = CallType.missed;
    }

    return CallLogEntry(
      id: json['id'] ?? 0,
      leadName: json['lead_name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      callDate: json['call_date'] != null
          ? DateTime.parse(json['call_date'])
          : null,
      callType: callType,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      operatorName: json['operator_name']?.toString(),
      organizationId: json['organization_id'],
      managerId: json['manager_id'],
      leadId: json['lead_id'],
      status: json['status']?.toString(),
      rating: json['rating'],
      notAnswered: json['not_answered'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_name': leadName,
      'phone_number': phoneNumber,
      'call_date': callDate?.toIso8601String(),
      'call_type': callType.toString().split('.').last,
      'duration': duration?.inSeconds,
      'operator_name': operatorName,
      'organization_id': organizationId,
      'manager_id': managerId,
      'lead_id': leadId,
      'status': status,
      'rating': rating,
      'not_answered': notAnswered,
    };
  }
}