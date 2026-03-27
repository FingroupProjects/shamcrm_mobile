import 'package:intl/intl.dart';

class Notes {
  final int id;
  final String title;
  final String body;
  final String? date;
  final String? createDate;

  Notes({
    required this.id,
    required this.title,
    required this.body,
    this.date,
    this.createDate,
  });

  factory Notes.fromJson(Map<String, dynamic> json) {
    return Notes(
      id: json['id'],
      title: json['title'] is String ? json['title'] : 'Без заголовок',
      body: json['body'] is String ? json['body'] : 'Без имени',
      date: (json['date'] is String && _isValidDate(json['date']))
          ? json['date']
          : null, // Если дата некорректная, сохраняем null
      createDate: (json['created_at'] is String && _isValidDate(json['created_at']))
          ? json['created_at']
          : null, // Если дата некорректная, сохраняем null
    );
  }

// Функция для проверки корректности формата даты
  static bool _isValidDate(String date) {
    try {
      DateTime.parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  String getFormattedDate() {
    if (date != null && date!.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(date!);
        return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
      } catch (e) {
        return 'Не указано'; // Если дата некорректная
      }
    } else {
      return 'Не указано';
    }
  }
}
