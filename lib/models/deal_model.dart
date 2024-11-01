class Deal {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final String sum;
  final int statusId;
  final List<DealCustomField> dealCustomFields;

  Deal({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.description,
    required this.sum,
    required this.statusId,
    required this.dealCustomFields,
  });

  factory Deal.fromJson(Map<String, dynamic> json, int dealStatusId) {
    return Deal(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      startDate: json['start_date'] is String ? json['start_date'] : null,
      endDate: json['end_date'] is String ? json['end_date'] : null,
      description: json['description'] is String ? json['description'] : '',
      sum: json['sum'] is String ? json['sum'] : '0.00',
      statusId: dealStatusId,
      dealCustomFields: (json['deal_custom_fields'] as List<dynamic>?)
              ?.map((field) => DealCustomField.fromJson(field))
              .toList() ??
          [],
    );
  }
}

class DealCustomField {
  final int id;
  final String key;
  final String value;

  DealCustomField({
    required this.id,
    required this.key,
    required this.value,
  });

  factory DealCustomField.fromJson(Map<String, dynamic> json) {
    return DealCustomField(
      id: json['id'] is int ? json['id'] : 0,
      key: json['key'] is String ? json['key'] : '',
      value: json['value'] is String ? json['value'] : '',
    );
  }
}

class DealStatus {
  final int id;
  final String title;
  final String color;
  final String? createdAt;
  final String? updatedAt;

  DealStatus({
    required this.id,
    required this.title,
    required this.color,
    this.createdAt,
    this.updatedAt,
  });

  factory DealStatus.fromJson(Map<String, dynamic> json) {
    return DealStatus(
      id: json['id'] is int ? json['id'] : 0,
      title: json['title'] is String ? json['title'] : 'Без имени',
      color: json['color'] is String ? json['color'] : '#000',
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      updatedAt: json['updated_at'] is String ? json['updated_at'] : null,
    );
  }
}
