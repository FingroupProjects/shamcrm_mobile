class FieldPositionUpdate {
  final int id;
  final int position;
  final int isActive;
  final int isRequired;
  final int showOnTable;

  FieldPositionUpdate({
    required this.id,
    required this.position,
    required this.isActive,
    required this.isRequired,
    required this.showOnTable,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'is_active': isActive,
      'is_required': isRequired,
      'show_on_table': showOnTable,
    };
  }

  factory FieldPositionUpdate.fromJson(Map<String, dynamic> json) {
    return FieldPositionUpdate(
      id: json['id'],
      position: json['position'],
      isActive: json['is_active'],
      isRequired: json['is_required'],
      showOnTable: json['show_on_table'],
    );
  }
}

class FieldPositionUpdateRequest {
  final List<FieldPositionUpdate> updates;
  final String organizationId;
  final String salesFunnelId;

  FieldPositionUpdateRequest({
    required this.updates,
    required this.organizationId,
    required this.salesFunnelId,
  });

  Map<String, dynamic> toJson() {
    return {
      'updates': updates.map((update) => update.toJson()).toList(),
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };
  }

  factory FieldPositionUpdateRequest.fromJson(Map<String, dynamic> json) {
    return FieldPositionUpdateRequest(
      updates: (json['updates'] as List)
          .map((item) => FieldPositionUpdate.fromJson(item))
          .toList(),
      organizationId: json['organization_id'],
      salesFunnelId: json['sales_funnel_id'],
    );
  }
}

