import 'package:flutter/services.dart';

/// Форматтер для ввода цены
/// Разрешает:
/// - Целые числа: 1, 2, 10, 100, и т.д.
/// - Десятичные числа с максимум 3 цифрами после точки: 1.234, 10.5, и т.д.
/// - Одиночный ноль: 0
/// - Ноль с десятичной частью: 0.5, 0.123
/// 
/// Запрещает:
/// - Несколько нулей в начале: 0000, 00, 01, и т.д.
/// - Более 3 цифр после точки
///
/// Использование:
/// ```dart
/// inputFormatters: [
///   FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
///   PriceInputFormatter(),
/// ],
/// ```
class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String newText = newValue.text;

    // Разрешаем пустую строку
    if (newText.isEmpty) {
      return newValue;
    }

    // Удаляем все символы кроме цифр и точки
    newText = newText.replaceAll(RegExp(r'[^\d.]'), '');

    // Если после очистки строка пустая, возвращаем пустое значение
    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Запрещаем более одной точки
    if (newText.split('.').length > 2) {
      return oldValue;
    }

    // Запрещаем несколько нулей в начале
    if (newText.startsWith('00')) {
      return oldValue;
    }

    // Запрещаем числа типа "01", "02" и т.д. (ноль с последующими цифрами без точки)
    if (newText.length > 1 && newText.startsWith('0') && !newText.startsWith('0.')) {
      return oldValue;
    }

    // Обрабатываем количество цифр после точки (максимум 3)
    if (newText.contains('.')) {
      final parts = newText.split('.');
      if (parts.length == 2) {
        // Ограничиваем количество цифр после точки до 3
        if (parts[1].length > 3) {
          newText = parts[0] + '.' + parts[1].substring(0, 3);
          return TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
      }
    }

    return newValue;
  }
}