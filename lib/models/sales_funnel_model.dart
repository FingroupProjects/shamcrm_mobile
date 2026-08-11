import 'package:crm_task_manager/utils/safe_converters.dart';

class SalesFunnel {
  final int id;
  final String name;
  final int? organizationId;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;
  final int? acceptLeadStatusId;
  final bool showAcceptDeclineButton;

  SalesFunnel({
    required this.id,
    required this.name,
    this.organizationId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.acceptLeadStatusId,
    this.showAcceptDeclineButton = false,
  });

  factory SalesFunnel.fromJson(Map<String, dynamic> json) {
    return SalesFunnel(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      organizationId: SafeConverters.toIntOrNull(json['organization_id']),
      isActive: SafeConverters.toBoolOrNull(json['is_active']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      acceptLeadStatusId:
          SafeConverters.toIntOrNull(json['accept_lead_status_id']),
      showAcceptDeclineButton:
          SafeConverters.toBool(json['show_accept_decline_button']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'organization_id': organizationId,
      'is_active': isActive != null ? (isActive! ? 1 : 0) : null,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'accept_lead_status_id': acceptLeadStatusId,
      'show_accept_decline_button': showAcceptDeclineButton ? 1 : 0,
    };
  }
}
