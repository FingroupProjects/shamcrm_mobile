import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/organization_model.dart';

enum CallStatus { answer, busy, noAnswer, cancel }

class Call {
  final int id;
  final String? leadName;
  final String? phoneNumber;
  final DateTime? callDate;
  final bool? incoming;
  final bool? missed;
  final bool? notAnswered;
  final CallStatus? status;
  final int? rating;
  final int? organizationId;
  final int? managerId;
  final int? leadId;
  final Duration? duration;
  final String? operatorName;
  final Lead? lead;
  final ManagerData? manager;
  final Organization? organization;

  Call({
    required this.id,
    this.leadName,
    this.phoneNumber,
    this.callDate,
    this.incoming,
    this.missed,
    this.notAnswered,
    this.status,
    this.rating,
    this.organizationId,
    this.managerId,
    this.leadId,
    this.duration,
    this.operatorName,
    this.lead,
    this.manager,
    this.organization,
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'] ?? 0,
      leadName: json['lead_name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      callDate: json['call_date'] != null ? DateTime.parse(json['call_date']) : null,
      incoming: json['incoming'],
      missed: json['missed'],
      notAnswered: json['not_answered'],
      status: json['status'] != null ? _parseCallStatus(json['status']) : null,
      rating: json['rating'],
      organizationId: json['organization_id'],
      managerId: json['manager_id'],
      leadId: json['lead_id'],
      duration: json['duration'] != null ? Duration(seconds: json['duration']) : null,
      operatorName: json['operator_name']?.toString(),
      lead: json['lead'] != null ? Lead.fromJson(json['lead'], -1) : null,
      manager: json['manager'] != null ? ManagerData.fromJson(json['manager']) : null,
      organization: json['organization'] != null ? Organization.fromJson(json['organization']) : null,
    );
  }

  static CallStatus? _parseCallStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ANSWER':
        return CallStatus.answer;
      case 'BUSY':
        return CallStatus.busy;
      case 'NOANSWER':
        return CallStatus.noAnswer;
      case 'CANCEL':
        return CallStatus.cancel;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_name': leadName,
      'phone_number': phoneNumber,
      'call_date': callDate?.toIso8601String(),
      'incoming': incoming,
      'missed': missed,
      'not_answered': notAnswered,
      'status': status?.toString().split('.').last.toUpperCase(),
      'rating': rating,
      'organization_id': organizationId,
      'manager_id': managerId,
      'lead_id': leadId,
      'duration': duration?.inSeconds,
      'operator_name': operatorName,
      'lead': lead?.toJson(),
      'manager': manager?.toJson(),
      'organization': organization?.toJson(),
    };
  }
}