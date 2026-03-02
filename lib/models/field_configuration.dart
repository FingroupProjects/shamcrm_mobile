import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class FieldConfiguration extends Equatable {
  final int id;
  final String tableName;
  final String fieldName;
  final int position;
  final bool required;
  final bool isActive;
  final bool isCustomField;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? customFieldId;
  final int? directoryId;
  final String? type;
  final bool isDirectory;
  final bool showOnTable;
  final bool showOnSite;
  final bool originalRequired; // Оригинальное значение required с бэкенда

  FieldConfiguration({
    required this.id,
    required this.tableName,
    required this.fieldName,
    required this.position,
    required this.required,
    required this.isActive,
    required this.isCustomField,
    required this.createdAt,
    required this.updatedAt,
    this.customFieldId,
    this.directoryId,
    this.type,
    required this.isDirectory,
    required this.showOnTable,
    this.showOnSite = false,
    required this.originalRequired,
  });

  @override
  List<Object?> get props => [
    id,
    tableName,
    fieldName,
    position,
    required,
    isActive,
    isCustomField,
    createdAt,
    updatedAt,
    customFieldId,
    directoryId,
    type,
    isDirectory,
    showOnTable,
    showOnSite,
    originalRequired,
  ];

  factory FieldConfiguration.fromJson(Map<String, dynamic> json) {

    debugPrint('Parsing FieldConfiguration from JSON required field: ${json['required']}');

    // Сохраняем оригинальное значение required
    final originalRequiredValue = json['required'] == 1;

    final showOnSiteValue =
        json['show_on_site'] ?? json['show_to_site'] ?? json['show_to_sitee'];

    return FieldConfiguration(
      id: json['id'],
      tableName: json['table_name'],
      fieldName: json['field_name'],
      position: json['position'],
      required: false, // Всегда false в UI
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isCustomField: json['is_custom_field'] == true || json['is_custom_field'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      customFieldId: json['custom_field_id'],
      directoryId: json['directory_id'],
      type: json['type'],
      isDirectory: json['is_directory'] == true || json['is_directory'] == 1,
      showOnTable: json['show_on_table'] == 1,
      showOnSite: showOnSiteValue == true || showOnSiteValue == 1,
      originalRequired: originalRequiredValue, // Сохраняем оригинальное значение
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_name': tableName,
      'field_name': fieldName,
      'position': position,
      'required': originalRequired ? 1 : 0, // Используем originalRequired при отправке
      'is_active': isActive,
      'is_custom_field': isCustomField,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'custom_field_id': customFieldId,
      'directory_id': directoryId,
      'type': type,
      'is_directory': isDirectory,
      'show_on_table': showOnTable ? 1 : 0,
      'show_on_site': showOnSite ? 1 : 0,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'result': result.map((field) => field.toJson()).toList(),
      'errors': errors,
    };
  }
}
