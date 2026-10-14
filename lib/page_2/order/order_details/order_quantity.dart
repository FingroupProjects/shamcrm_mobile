import 'package:flutter/services.dart';

/// Количество товара в заказе.
/// Целые числа остаются целыми (1, 2).
/// Дробные сохраняются как есть: 0.5 порции, 1.4 штуки.
class OrderQuantity {
  OrderQuantity._();

  /// Три знака после точки хватает для порций вроде 0.125.
  static const int maxFractionDigits = 3;

  static final RegExp _inputPattern = RegExp(r'^\d*\.?\d{0,3}$');
  static final RegExp _completePattern = RegExp(r'^\d+(\.\d+)?$');

  /// Пользователь ещё не дописал число: пусто, «0», «0.», «1.».
  /// Такое значение не сохраняем и не затираем в поле.
  static bool isTyping(String raw) {
    final text = _normalize(raw);
    if (text.isEmpty || text == '.') return true;
    if (text.endsWith('.')) return true;
    return RegExp(r'^0+\.?0*$').hasMatch(text);
  }

  /// Готовое положительное количество. «0» и «1.» сюда не попадают.
  static double? tryParse(String raw) {
    final text = _normalize(raw);
    if (!_completePattern.hasMatch(text)) return null;
    final value = double.tryParse(text);
    if (value == null || value <= 0) return null;
    return round(value);
  }

  /// Читает уже сохранённое количество. Ноль оставляем:
  /// у части заказов площадь может быть ещё не заполнена.
  static double read(dynamic value, {double fallback = 1}) {
    final parsed = _parseLoose(value);
    if (parsed == null || parsed < 0) return fallback;
    return round(parsed);
  }

  /// Целое для полей, где дробь не хранится (карточка самого товара).
  /// Строка заказа при этом остаётся дробной.
  static int asWholeUnits(dynamic value) {
    final rounded = read(value).round();
    return rounded < 1 ? 1 : rounded;
  }

  /// 1.0 уходит как 1, 0.5 остаётся 0.5.
  /// Так целое количество в запросе не превращается в «1.0».
  static num compact(double value) {
    final rounded = round(value);
    if (rounded == rounded.roundToDouble()) return rounded.toInt();
    return rounded;
  }

  static double round(double value) {
    final factor = _factor();
    return (value * factor).roundToDouble() / factor;
  }

  /// «1» вместо «1.0», «0.5» и «1.4» без лишних нулей.
  static String format(num value) {
    final rounded = round(value.toDouble());
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    var text = rounded.toStringAsFixed(maxFractionDigits);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }

  /// Пока пользователь печатает ту же дробь, текст поля не перезаписываем.
  static bool shouldKeepText(String current, String formatted) {
    if (isTyping(current)) return true;
    final typed = tryParse(current);
    final stored = tryParse(formatted);
    if (typed != null && stored != null && typed == stored) return true;
    return current == formatted;
  }

  static double? _parseLoose(dynamic value) {
    if (value is num) {
      if (value.isNaN || value.isInfinite) return null;
      return value.toDouble();
    }
    if (value is String) {
      final cleaned = _normalize(value);
      if (cleaned.isEmpty || cleaned == '.') return null;
      return double.tryParse(cleaned);
    }
    return null;
  }

  static String _normalize(String raw) => raw.trim().replaceAll(',', '.');

  static double _factor() {
    var factor = 1.0;
    for (var i = 0; i < maxFractionDigits; i++) {
      factor *= 10;
    }
    return factor;
  }
}

/// Разрешает цифры и одну точку. Запятую с клавиатуры меняет на точку.
class OrderQuantityInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '.');
    if (text.isNotEmpty && !OrderQuantity._inputPattern.hasMatch(text)) {
      return oldValue;
    }
    if (text == newValue.text) return newValue;
    final offset = newValue.selection.baseOffset.clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
