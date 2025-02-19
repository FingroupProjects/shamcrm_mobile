import 'package:intl/intl.dart';
import 'package:crm_task_manager/models/leadById_model.dart';

class ContactPerson {
  final int id;
  final String name;
  final String phone;
  final String? position;
  final Author? author;
  final String createAt;

  ContactPerson({
    required this.id,
    required this.name,
    required this.phone,
    this.position,
    this.author,
    required this.createAt,
  });

  String get formattedDate {
    try {
      final datetime = DateTime.parse(createAt);
      return DateFormat('dd.MM.yyyy HH:mm').format(datetime);
    } catch (e) {
      return createAt;
    }
  }

  factory ContactPerson.fromJson(Map<String, dynamic> json) {
    return ContactPerson(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      position: json['position'],
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? Author.fromJson(json['author'])
          : null,
      createAt: json['created_at'] ?? '',
    );
  }
}