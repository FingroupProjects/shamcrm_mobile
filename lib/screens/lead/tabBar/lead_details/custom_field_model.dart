import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CustomField {
  final String fieldName;
  final TextEditingController controller;
  final bool isDirectoryField;
  final int? directoryId;
  final int? entryId;
  final String uniqueId; // Уникальный идентификатор

  CustomField({
    required this.fieldName,
    required this.controller,
    this.isDirectoryField = false,
    this.directoryId,
    this.entryId,
    String? uniqueId, // Опционально, если не передан, генерируем новый
  }) : uniqueId = uniqueId ?? Uuid().v4();

  CustomField copyWith({
    String? fieldName,
    TextEditingController? controller,
    bool? isDirectoryField,
    int? directoryId,
    int? entryId,
    String? uniqueId,
  }) {
    return CustomField(
      fieldName: fieldName ?? this.fieldName,
      controller: controller ?? this.controller,
      isDirectoryField: isDirectoryField ?? this.isDirectoryField,
      directoryId: directoryId ?? this.directoryId,
      entryId: entryId ?? this.entryId,
      uniqueId: uniqueId ?? this.uniqueId,
    );
  }
}