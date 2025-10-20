class FieldConfiguration {
  final int id;
  final String tableName;
  final String fieldName;
  final int position;
  final bool required;
  final bool isActive;
  final bool isCustomField;
  final int? customFieldId;
  final int? directoryId;
  final String? type;
  final bool isDirectory;
  final bool showOnTable;

  FieldConfiguration({
    required this.id,
    required this.tableName,
    required this.fieldName,
    required this.position,
    required this.required,
    required this.isActive,
    required this.isCustomField,
    this.customFieldId,
    this.directoryId,
    this.type,
    required this.isDirectory,
    required this.showOnTable,
  });

  factory FieldConfiguration.fromJson(Map<String, dynamic> json) {
    return FieldConfiguration(
      id: json['id'],
      tableName: json['table_name'],
      fieldName: json['field_name'],
      position: json['position'],
      required: json['required'] == 1,
      isActive: json['is_active'],
      isCustomField: json['is_custom_field'],
      customFieldId: json['custom_field_id'],
      directoryId: json['directory_id'],
      type: json['type'],
      isDirectory: json['is_directory'],
      showOnTable: json['show_on_table'] == 1,
    );
  }
}

class FieldConfigurationResponse {
  final List<FieldConfiguration> result;
  final dynamic errors;

  FieldConfigurationResponse({
    required this.result,
    this.errors,
  });

  factory FieldConfigurationResponse.fromJson(Map<String, dynamic> json) {
    return FieldConfigurationResponse(
      result: (json['result'] as List)
          .map((field) => FieldConfiguration.fromJson(field))
          .toList(),
      errors: json['errors'],
    );
  }
}