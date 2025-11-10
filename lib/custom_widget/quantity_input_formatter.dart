import 'package:flutter/services.dart';

/// Форматтер для ввода количества
/// Разрешает:
/// - Целые числа: 1, 2, 10, 100, и т.д.
/// - Одиночный ноль: 0
/// 
/// Запрещает:
/// - Несколько нулей в начале: 0000, 00, 01, и т.д.
/// - Буквы и специальные символы
/// - Десятичные числа (точки)
///
/// Использование:
/// ```dart
/// inputFormatters: [
///   QuantityInputFormatter(),
/// ],
/// ```
class QuantityInputFormatter extends TextInputFormatter {
  final int maxLength;

  QuantityInputFormatter({this.maxLength = 10});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final newText = newValue.text;

    // Разрешаем пустую строку (при очистке поля)
    if (newText.isEmpty) {
      return newValue;
    }

    // Проверяем, что строка содержит только цифры
    if (!RegExp(r'^\d+$').hasMatch(newText)) {
      // Если есть недопустимые символы, отклоняем ввод
      return oldValue;
    }

    // Запрещаем несколько нулей в начале (00, 000, и т.д.)
    if (newText.length >= 2 && newText.startsWith('00')) {
      return oldValue;
    }

    // Запрещаем числа типа "01", "02" и т.д. (ноль с последующими цифрами)
    if (newText.length >= 2 &&
        newText[0] == '0' &&
        RegExp(r'\d').hasMatch(newText[1])) {
      return oldValue;
    }

    // Ограничиваем максимальную длину
    if (newText.length > maxLength) {
      return oldValue;
    }

    // Если все проверки пройдены, принимаем новое значение
    return newValue;
  }
}
