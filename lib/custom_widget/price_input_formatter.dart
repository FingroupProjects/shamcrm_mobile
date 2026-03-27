import 'package:flutter/services.dart';

/// Форматтер для конвертации запятой в точку (для iOS локалей)
/// Автоматически заменяет запятую на точку при вводе
class CommaToDoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Заменяем запятую на точку
    final newText = newValue.text.replaceAll(',', '.');
    
    // Возвращаем новое значение с заменённым текстом
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// Форматтер для ввода цены с поддержкой запятой
/// Разрешает:
/// - Целые числа: 1, 2, 10, 100, и т.д.
/// - Десятичные числа с максимум 3 цифрами после точки: 1.234, 10.5, и т.д.
/// - Одиночный ноль: 0
/// - Ноль с десятичной частью: 0.5, 0.123
/// - Запятую (автоматически конвертируется в точку)
/// 
/// Запрещает:
/// - Несколько нулей в начале: 0000, 00, 01, и т.д.
/// - Более 3 цифр после точки
/// - Буквы и специальные символы
///
/// Использование:
/// ```dart
/// inputFormatters: [
///   PriceInputFormatter(),
/// ],
/// ```
class PriceInputFormatter extends TextInputFormatter {
  final int decimalRange;

  PriceInputFormatter({this.decimalRange = 3});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Сначала заменяем запятую на точку
    String newText = newValue.text.replaceAll(',', '.');

    // Разрешаем пустую строку (при очистке поля)
    if (newText.isEmpty) {
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    // Проверяем, что строка содержит только цифры и точку
    if (!RegExp(r'^[\d.]+$').hasMatch(newText)) {
      // Если есть недопустимые символы, отклоняем ввод
      return oldValue;
    }

    // Запрещаем более одной точки
    if ('.'.allMatches(newText).length > 1) {
      return oldValue;
    }

    // Запрещаем несколько нулей в начале (00, 000, и т.д.)
    if (newText.length >= 2 && newText.startsWith('00')) {
      return oldValue;
    }

    // Запрещаем числа типа "01", "02" и т.д. (ноль с последующими цифрами без точки)
    if (newText.length >= 2 &&
        newText[0] == '0' &&
        newText[1] != '.' &&
        RegExp(r'\d').hasMatch(newText[1])) {
      return oldValue;
    }

    // Проверяем количество цифр после точки
    if (newText.contains('.')) {
      final parts = newText.split('.');
      // Если после точки больше decimalRange цифр, отклоняем ввод
      if (parts.length == 2 && parts[1].length > decimalRange) {
        return oldValue;
      }
    }

    // Если все проверки пройдены, принимаем новое значение
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}