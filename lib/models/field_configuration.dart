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
  ];

  factory FieldConfiguration.fromJson(Map<String, dynamic> json) {

    debugPrint('Parsing FieldConfiguration from JSON required field: ${json['required']}');

    return FieldConfiguration(
      id: json['id'],
      tableName: json['table_name'],
      fieldName: json['field_name'],
      position: json['position'],
      required: json['required'] == 1,
      isActive: json['is_active'],
      isCustomField: json['is_custom_field'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      customFieldId: json['custom_field_id'],
      directoryId: json['directory_id'],
      type: json['type'],
      isDirectory: json['is_directory'],
      showOnTable: json['show_on_table'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_name': tableName,
      'field_name': fieldName,
      'position': position,
      'required': required ? 1 : 0,
      'is_active': isActive,
      'is_custom_field': isCustomField,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'custom_field_id': customFieldId,
      'directory_id': directoryId,
      'type': type,
      'is_directory': isDirectory,
      'show_on_table': showOnTable ? 1 : 0,
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