import 'package:flutter/material.dart';

class CalendarEventData {
  final int id;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final String type;
  final bool isFinished;

  CalendarEventData({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.type = '',
    required this.isFinished ,
  });
}

class CalendarUtils {
  static Color getEventColor(String type) {
    switch (type) {
      case 'task':
        return Colors.blue;
      // case 'my_task':
      //   return Colors.purpleAccent;
      case 'notice':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// Сколько дней от сегодня до выбранного дня, как в календаре телефона.
/// «Сегодня», «Завтра», «Через 74 дня», «5 дней назад».
String relativeCalendarDistance(
  DateTime selected,
  DateTime now,
  String languageCode,
) {
  final selectedDay = DateTime(selected.year, selected.month, selected.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = selectedDay.difference(today).inDays;
  final lang = languageCode.toLowerCase();

  if (days == 0) {
    return switch (lang) {
      'en' => 'Today',
      'uz' => 'Bugun',
      _ => 'Сегодня',
    };
  }
  if (days == 1) {
    return switch (lang) {
      'en' => 'Tomorrow',
      'uz' => 'Ertaga',
      _ => 'Завтра',
    };
  }
  if (days == -1) {
    return switch (lang) {
      'en' => 'Yesterday',
      'uz' => 'Kecha',
      _ => 'Вчера',
    };
  }
  if (days > 1) {
    return switch (lang) {
      'en' => 'In $days ${days == 1 ? 'day' : 'days'}',
      'uz' => '$days kundan keyin',
      _ => 'Через $days ${_ruDays(days)}',
    };
  }
  final past = days.abs();
  return switch (lang) {
    'en' => '$past ${past == 1 ? 'day' : 'days'} ago',
    'uz' => '$past kun oldin',
    _ => '$past ${_ruDays(past)} назад',
  };
}

/// Склонение «день / дня / дней» для русского.
String _ruDays(int count) {
  final mod100 = count.abs() % 100;
  final mod10 = mod100 % 10;
  if (mod100 >= 11 && mod100 <= 14) return 'дней';
  if (mod10 == 1) return 'день';
  if (mod10 >= 2 && mod10 <= 4) return 'дня';
  return 'дней';
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}