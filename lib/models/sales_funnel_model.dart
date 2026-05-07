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
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      organizationId: _asInt(json['organization_id']),
      isActive: json['is_active'] != null ? _asBool(json['is_active']) : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      acceptLeadStatusId: _asInt(json['accept_lead_status_id']),
      showAcceptDeclineButton: _asBool(json['show_accept_decline_button']),
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

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return int.tryParse('$value');
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
  return false;
}
