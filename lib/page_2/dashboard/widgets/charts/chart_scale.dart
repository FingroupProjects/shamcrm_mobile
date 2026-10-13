import 'dart:math';

import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Шкала графика по фактическим числам с сервера.
/// Верхняя граница чуть выше максимума и кратна шагу сетки,
/// чтобы линия не прилипала к низу и не обрезалась сверху.
class ChartScale {
  final double minY;
  final double maxY;
  final double interval;

  const ChartScale({
    required this.minY,
    required this.maxY,
    required this.interval,
  });

  static const empty = ChartScale(minY: 0, maxY: 1, interval: 1);

  static ChartScale fromValues(
    Iterable<double> source, {
    bool allowNegative = false,
  }) {
    final values = source.toList();
    if (values.isEmpty) return empty;

    var minValue = values.reduce(min);
    var maxValue = values.reduce(max);
    if (!allowNegative || minValue > 0) minValue = 0;

    if (maxValue == 0 && minValue == 0) return empty;

    final span = max(maxValue - minValue, maxValue.abs());
    final step = _niceStep(span / 4);
    final maxY = max(step, (maxValue / step).ceil() * step);
    final minY = minValue < 0 ? (minValue / step).floor() * step : 0.0;
    return ChartScale(
      minY: minY,
      // Если максимум попал ровно на линию сетки, добавляем ещё один шаг.
      // Иначе точка и подпись упираются в край карточки.
      maxY: maxY <= maxValue ? maxY + step : maxY,
      interval: step,
    );
  }

  static double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final magnitude = pow(10, (log(raw) / ln10).floor()).toDouble();
    final normalized = raw / magnitude;
    final nice = normalized <= 1
        ? 1.0
        : normalized <= 2
            ? 2.0
            : normalized <= 5
                ? 5.0
                : 10.0;
    return nice * magnitude;
  }
}

/// Число с сервера: "1 234,50", "1234.5" и "12,5%" читаются одинаково.
double parseChartNumber(Object? raw) {
  if (raw == null) return 0;
  if (raw is num) return raw.toDouble();
  final text = raw
      .toString()
      .trim()
      .replaceAll('\u00A0', '')
      .replaceAll(' ', '')
      .replaceAll(',', '.');
  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(text);
  if (match == null) return 0;
  return double.tryParse(match.group(0)!) ?? 0;
}

const _monthKeyByAlias = <String, String>{
  '1': 'jan',
  '01': 'jan',
  'январь': 'jan',
  'янв': 'jan',
  'january': 'jan',
  'jan': 'jan',
  '2': 'feb',
  '02': 'feb',
  'февраль': 'feb',
  'фев': 'feb',
  'february': 'feb',
  'feb': 'feb',
  '3': 'mar',
  '03': 'mar',
  'март': 'mar',
  'мар': 'mar',
  'march': 'mar',
  'mar': 'mar',
  '4': 'apr',
  '04': 'apr',
  'апрель': 'apr',
  'апр': 'apr',
  'april': 'apr',
  'apr': 'apr',
  '5': 'may',
  '05': 'may',
  'май': 'may',
  'may': 'may',
  '6': 'jun',
  '06': 'jun',
  'июнь': 'jun',
  'июн': 'jun',
  'june': 'jun',
  'jun': 'jun',
  '7': 'jul',
  '07': 'jul',
  'июль': 'jul',
  'июл': 'jul',
  'july': 'jul',
  'jul': 'jul',
  '8': 'aug',
  '08': 'aug',
  'август': 'aug',
  'авг': 'aug',
  'august': 'aug',
  'aug': 'aug',
  '9': 'sep',
  '09': 'sep',
  'сентябрь': 'sep',
  'сен': 'sep',
  'september': 'sep',
  'sep': 'sep',
  '10': 'oct',
  'октябрь': 'oct',
  'окт': 'oct',
  'october': 'oct',
  'oct': 'oct',
  '11': 'nov',
  'ноябрь': 'nov',
  'ноя': 'nov',
  'november': 'nov',
  'nov': 'nov',
  '12': 'dec',
  'декабрь': 'dec',
  'дек': 'dec',
  'december': 'dec',
  'dec': 'dec',
};

/// Короткая подпись месяца на языке приложения.
/// Английское имя с сервера тоже становится «Янв», а не «January».
String localizedShortMonth(String name, AppLocalizations localizations) {
  final key = _monthKeyByAlias[name.trim().toLowerCase()];
  if (key != null) return localizations.translate(key);
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  // Дни недели и короткие даты оставляем как пришли.
  if (trimmed.length <= 6) return trimmed;
  return trimmed.substring(0, 5);
}

/// Короткая подпись оси: тысячи и миллионы берутся из перевода, не «K»/«M».
String formatChartAxis(double value, AppLocalizations localizations) {
  if (value == 0) return '0';
  final absValue = value.abs();
  final sign = value < 0 ? '-' : '';
  String compact(double divisor, String unitKey) {
    final scaled = absValue / divisor;
    final digits = scaled == scaled.roundToDouble() ? 0 : 1;
    return '$sign${scaled.toStringAsFixed(digits)}${localizations.translate(unitKey)}';
  }

  if (absValue >= 1000000000) return compact(1000000000, 'billion');
  if (absValue >= 1000000) return compact(1000000, 'million');
  if (absValue >= 1000) return compact(1000, 'thousand');
  if (absValue == absValue.roundToDouble()) return '$sign${absValue.toInt()}';
  return '$sign${absValue.toStringAsFixed(1)}';
}

/// Подпись месяца внутри карточки.
/// RotatedBox занимает место в вёрстке. Transform.rotate рисовал текст
/// поверх «Подробнее» и нижней панели, потому что не менял размер.
Widget chartAxisLabel(String text, Color color, TitleMeta meta) {
  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 2,
    child: RotatedBox(
      quarterTurns: 3,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    ),
  );
}

/// Подпись значения слева. Без поворота: это числа, не месяцы.
Widget chartValueLabel(String text, Color color, TitleMeta meta) {
  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 4,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    ),
  );
}
