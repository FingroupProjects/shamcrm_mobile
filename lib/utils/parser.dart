// Безопасная функция для парсинга int из динамического значения
int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    try {
      return int.parse(value);
    } catch (e) {
      //print('Error parsing int from string "$value": $e');
      return null;
    }
  }
  //print('Unexpected type for int parsing: ${value.runtimeType}');
  return null;
}

// Безопасная функция для парсинга num (int или double) из динамического значения
num? parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) {
    if (value is int) return value;
    if (value is double) {
      if (value == value.toInt()) {
        return value.toInt();
      }
      return value;
    }
    return value;
  }
  if (value is String) {
    if (value.isEmpty) return null;
    try {
      double parsed = double.parse(value.replaceAll(',', '.'));

      if (parsed == parsed.toInt()) {
        return parsed.toInt(); // Return as int (1, 2, 3, etc.)
      }
      return parsed; // Return as double (1.23, 2.5, etc.)
    } catch (e) {
      //print('Error parsing num from string "$value": $e');
      return null;
    }
  }
  //print('Unexpected type for num parsing: ${value.runtimeType}');
  return null;
}

// Безопасная функция для парсинга DateTime из динамического значения
DateTime? parseDate(dynamic dateStr) {
  if (dateStr == null || dateStr == '' || dateStr is! String) return null;
  try {
    return DateTime.parse(dateStr);
  } catch (e) {
    //print('Error parsing date $dateStr: $e');
    return null; // Возвращаем null в случае ошибки
  }
}
