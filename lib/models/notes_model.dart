import 'package:intl/intl.dart';

class Notes {
  final int id;
  final String title;
  final String body;
  final String? date;

  Notes({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
  });

  factory Notes.fromJson(Map<String, dynamic> json) {
    return Notes(
      id: json['id'],
      title: json['title'] is String ? json['title'] : 'Без заголовок',
      body: json['body'] is String ? json['body'] : 'Без имени',
      date: json['date'] is String ? json['date'] : 'Не указано',
    );
  }
  String getFormattedDate() {
    if (date != null) {
      final dateTime = DateTime.parse(date!);
      final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
      return formattedDate;
    } else {
      return 'Не указано';
    }
  }
}
