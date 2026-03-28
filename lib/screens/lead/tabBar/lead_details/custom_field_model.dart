import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CustomField {
  final String fieldName;
  final TextEditingController controller;
  final bool isDirectoryField;
  final int? directoryId;
  final int? entryId;
  final String uniqueId; // Уникальный идентификатор
  final String? type; // Тип поля
  final GlobalKey _key; // Приватный ключ для виджета
    final bool isCustomField; // Новый флаг


  CustomField({
    required this.fieldName,
    required this.controller,
    this.isDirectoryField = false,
    this.directoryId,
    this.entryId,
    this.type,
        this.isCustomField = false, // По умолчанию false
    String? uniqueId,
  }) : uniqueId = uniqueId ?? Uuid().v4(),
       _key = GlobalKey();

  // Геттер для доступа к ключу
  GlobalKey get key => _key;

  CustomField copyWith({
    String? fieldName,
    TextEditingController? controller,
    bool? isDirectoryField,
    int? directoryId,
    int? entryId,
    String? uniqueId,
    String? type,
  }) {
    return CustomField(
      fieldName: fieldName ?? this.fieldName,
      controller: controller ?? this.controller,
      isDirectoryField: isDirectoryField ?? this.isDirectoryField,
      directoryId: directoryId ?? this.directoryId,
      entryId: entryId ?? this.entryId,
      uniqueId: uniqueId ?? this.uniqueId,
      type: type ?? this.type,
      isCustomField: this.isCustomField,
    );
  }

  // Метод для освобождения ресурсов
  void dispose() {
    controller.dispose();
  }
}