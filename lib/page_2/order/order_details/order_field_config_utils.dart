import 'package:crm_task_manager/models/field_configuration.dart';

String _normalizeFieldName(String value) => value.trim().toLowerCase();

String _canonicalSystemFieldName(String fieldName) {
  final normalized = _normalizeFieldName(fieldName);

  switch (normalized) {
    case 'order_status_id':
    case 'status_id':
      return 'status_id';
    case 'payment_type':
    case 'payment_method':
      return 'payment_method';
    case 'branch_id':
    case 'storage_id':
      return 'branch_id';
    case 'order_type':
    case 'order_type_id':
    case 'type':
      return 'order_type';
    case 'delivery_type':
    case 'deliverytype':
    case 'delivery':
      return 'delivery_type';
    case 'comment_to_courier':
    case 'comment':
      return 'comment';
    case 'goods':
    case 'order_goods':
    case 'items':
    case 'sum':
      return 'items';
    default:
      return normalized;
  }
}

String buildOrderFieldUniqueKey(FieldConfiguration config) {
  if (config.isDirectory) {
    return 'dir:${config.directoryId ?? _normalizeFieldName(config.fieldName)}';
  }

  if (config.isCustomField) {
    return 'custom:${config.customFieldId ?? _normalizeFieldName(config.fieldName)}';
  }

  return 'sys:${_canonicalSystemFieldName(config.fieldName)}';
}

List<FieldConfiguration> deduplicateOrderFieldConfigurations(
  Iterable<FieldConfiguration> fields,
) {
  final sorted = fields.toList()
    ..sort((a, b) => a.position.compareTo(b.position));

  final seenKeys = <String>{};
  final result = <FieldConfiguration>[];

  for (final field in sorted) {
    final key = buildOrderFieldUniqueKey(field);
    if (seenKeys.add(key)) {
      result.add(field);
    }
  }

  return result;
}
