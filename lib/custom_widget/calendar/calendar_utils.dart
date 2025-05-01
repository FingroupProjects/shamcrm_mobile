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
        return Colors.green;
      case 'my_task':
        return Colors.blue;
      case 'notice':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}