import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

/// Тип ввода значения фильтра в конструкторе плана.
enum SalesPlanFilterInputType { select, date, text, number }

class SalesPlanFilterOption {
  final String value;
  final String label;

  const SalesPlanFilterOption({
    required this.value,
    required this.label,
  });
}

/// Поле фильтра из /v3/field-position.
class SalesPlanFilterField {
  final String key;
  final String field;
  final String label;
  final String? labelKey;
  final SalesPlanFilterInputType inputType;
  final int? customFieldId;
  final int? directoryId;
  final int position;
  final List<SalesPlanFilterOption> presetOptions;

  const SalesPlanFilterField({
    required this.key,
    required this.field,
    required this.label,
    this.labelKey,
    required this.inputType,
    this.customFieldId,
    this.directoryId,
    this.position = 0,
    this.presetOptions = const [],
  });

  String displayLabel(AppLocalizations t) {
    if (labelKey != null) {
      final translated = t.translate(labelKey!);
      if (translated.isNotEmpty && translated != labelKey) {
        return translated;
      }
    }
    return label;
  }

  factory SalesPlanFilterField.fromPosition(Map<String, dynamic> json) {
    final fieldName = SafeConverters.toSafeString(json['field_name']);
    final customFieldId = SafeConverters.toIntOrNull(json['custom_field_id']);
    final directoryId = SafeConverters.toIntOrNull(json['directory_id']);
    final isCustom = json['is_custom_field'] == true ||
        json['is_custom_field'] == 1 ||
        customFieldId != null;
    final isDirectory = json['is_directory'] == true ||
        json['is_directory'] == 1 ||
        directoryId != null;
    final type = SafeConverters.toSafeString(json['type']).toLowerCase();

    final key = customFieldId != null
        ? 'custom_$customFieldId'
        : directoryId != null
            ? 'directory_$directoryId'
            : fieldName;

    return SalesPlanFilterField(
      key: key,
      field: fieldName,
      label: _humanLabel(fieldName),
      labelKey: _labelKeyFor(fieldName),
      inputType: _inputTypeFor(
        fieldName: fieldName,
        type: type,
        isCustom: isCustom,
        isDirectory: isDirectory,
      ),
      customFieldId: customFieldId,
      directoryId: directoryId,
      position: SafeConverters.toInt(json['position']),
    );
  }

  static bool shouldSkip(Map<String, dynamic> json) {
    final fieldName =
        SafeConverters.toSafeString(json['field_name']).toLowerCase();
    // users дублируется много раз и не фильтр в вебе.
    return fieldName.isEmpty || fieldName == 'users';
  }

  static String _humanLabel(String fieldName) {
    switch (fieldName) {
      case 'deal_status_id':
      case 'lead_status_id':
      case 'task_status':
        return 'Статус';
      case 'source':
      case 'source_id':
        return 'Источник';
      case 'manager_id':
        return 'Менеджер';
      case 'name':
        return 'Название';
      case 'sum':
        return 'Сумма';
      case 'start_date':
        return 'Дата начала';
      case 'end_date':
        return 'Дата окончания';
      case 'lead_id':
        return 'Лид';
      case 'description':
        return 'Описание';
      default:
        return fieldName;
    }
  }

  static String? _labelKeyFor(String fieldName) {
    switch (fieldName) {
      case 'deal_status_id':
      case 'lead_status_id':
      case 'task_status':
        return 'status';
      case 'source':
      case 'source_id':
        return 'source';
      case 'manager_id':
        return 'manager';
      default:
        return null;
    }
  }

  static SalesPlanFilterInputType _inputTypeFor({
    required String fieldName,
    required String type,
    required bool isCustom,
    required bool isDirectory,
  }) {
    if (type == 'date' ||
        fieldName == 'start_date' ||
        fieldName == 'end_date') {
      return SalesPlanFilterInputType.date;
    }
    if (isDirectory ||
        fieldName == 'deal_status_id' ||
        fieldName == 'lead_status_id' ||
        fieldName == 'source' ||
        fieldName == 'source_id' ||
        fieldName == 'task_status') {
      return SalesPlanFilterInputType.select;
    }
    if (type == 'number') {
      return SalesPlanFilterInputType.number;
    }
    if (isCustom) {
      return SalesPlanFilterInputType.select;
    }
    return SalesPlanFilterInputType.text;
  }
}
