import 'package:crm_task_manager/utils/safe_converters.dart';

/// Безопасный парсинг int из динамического значения.
int? parseInt(dynamic value) => SafeConverters.toIntOrNull(value);

/// Безопасный парсинг num (int или double) из динамического значения.
num? parseNum(dynamic value) => SafeConverters.toNumOrNull(value);

/// Безопасный парсинг DateTime из динамического значения.
DateTime? parseDate(dynamic dateStr) => SafeConverters.toDateTimeOrNull(dateStr);
