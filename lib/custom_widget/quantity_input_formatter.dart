import 'package:flutter/services.dart';

/// Форматтер для ввода количества.
/// Разрешает:
/// - Целые числа: 1, 2, 10, 100, и т.д.
/// - Десятичные числа: 1.5, 2,75 и т.д.
/// - Одиночный ноль: 0
///
/// Запрещает:
/// - Несколько нулей в начале: 0000, 00, 01, и т.д.
/// - Буквы и специальные символы
/// - Более одной десятичной точки
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
    final newText = newValue.text.replaceAll(',', '.');

    // Разрешаем пустую строку (при очистке поля)
    if (newText.isEmpty) {
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    // Проверяем, что строка содержит только цифры и одну точку
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(newText)) {
      // Если есть недопустимые символы, отклоняем ввод
      return oldValue;
    }

    // Запрещаем начинать с точки
    if (newText.startsWith('.')) {
      return oldValue;
    }

    // Запрещаем несколько нулей в начале (00, 000, и т.д.)
    final normalizedText = newText.replaceAll(',', '.');
    final parts = normalizedText.split('.');

    if (parts.length > 2) {
      return oldValue;
    }

    if (parts.first.length >= 2 && parts.first.startsWith('00')) {
      return oldValue;
    }

    // Запрещаем числа типа "01", "02" и т.д. (ноль с последующими цифрами без точки)
    if (newText.length >= 2 &&
        newText[0] == '0' &&
        newText[1] != '.' &&
        RegExp(r'\d').hasMatch(newText[1])) {
      return oldValue;
    }

    // Ограничиваем максимальную длину
    if (newText.length > maxLength) {
      return oldValue;
    }

    // Поддерживаем максимум одну десятичную точку
    if ('.'.allMatches(newText).length > 1) {
      return oldValue;
    }

    // Ограничиваем максимальную длину
    if (newText.contains('.')) {
      final parts = newText.split('.');
      if (parts.length == 2 && parts[1].length > 3) {
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
