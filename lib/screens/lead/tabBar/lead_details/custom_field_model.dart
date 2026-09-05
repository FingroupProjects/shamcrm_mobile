import 'package:crm_task_manager/models/field/main_field_model.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CustomField {
  final String fieldName;
  final TextEditingController controller;
  final bool isDirectoryField;
  final int? directoryId;
  final int? entryId;
  final List<int> entryIds;
  final String uniqueId;
  final String? type;
  final GlobalKey _key;
  final bool isCustomField;

  CustomField({
    required this.fieldName,
    required this.controller,
    this.isDirectoryField = false,
    this.directoryId,
    this.entryId,
    List<int>? entryIds,
    this.type,
    this.isCustomField = false,
    String? uniqueId,
  })  : entryIds = List<int>.from(
          entryIds ?? (entryId != null ? <int>[entryId] : const <int>[]),
        ),
        uniqueId = uniqueId ?? const Uuid().v4(),
        _key = GlobalKey();

  GlobalKey get key => _key;

  List<int> get selectedEntryIds {
    if (entryIds.isNotEmpty) return entryIds;
    if (entryId != null) return <int>[entryId!];
    return const <int>[];
  }

  List<Map<String, int>> toDirectoryPayloads() {
    if (!isDirectoryField || directoryId == null) return const [];
    return selectedEntryIds
        .map((id) => <String, int>{
              'directory_id': directoryId!,
              'entry_id': id,
            })
        .toList();
  }

  CustomField copyWith({
    String? fieldName,
    TextEditingController? controller,
    bool? isDirectoryField,
    int? directoryId,
    int? entryId,
    List<int>? entryIds,
    String? uniqueId,
    String? type,
    bool? isCustomField,
  }) {
    final nextEntryIds = entryIds ??
        (entryId != null ? <int>[entryId] : this.entryIds);
    return CustomField(
      fieldName: fieldName ?? this.fieldName,
      controller: controller ?? this.controller,
      isDirectoryField: isDirectoryField ?? this.isDirectoryField,
      directoryId: directoryId ?? this.directoryId,
      entryId: nextEntryIds.isNotEmpty ? nextEntryIds.first : null,
      entryIds: nextEntryIds,
      uniqueId: uniqueId ?? this.uniqueId,
      type: type ?? this.type,
      isCustomField: isCustomField ?? this.isCustomField,
    );
  }

  CustomField withDirectorySelection(List<MainField> selected) {
    return copyWith(
      entryIds: selected.map((field) => field.id).toList(),
      controller: TextEditingController(
        text: selected.map((field) => field.value).join(', '),
      ),
    );
  }

  void dispose() {
    controller.dispose();
  }
}
