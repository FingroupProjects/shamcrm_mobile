import 'package:intl/intl.dart';
import 'package:crm_task_manager/models/lead/leadById_model.dart';

class ContactPerson {
  final int id;
  final String name;
  final String phone;
  final String? position;
  final String? email;
  final String? tgId;
  final String? address;
  final int? regionId;
  final Author? author;
  final String createAt;

  ContactPerson({
    required this.id,
    required this.name,
    required this.phone,
    this.position,
    this.email,
    this.tgId,
    this.address,
    this.regionId,
    this.author,
    required this.createAt,
  });

  String get formattedDate {
    try {
      final datetime = DateTime.parse(createAt);
      return DateFormat('dd.MM.yyyy').format(datetime);
    } catch (e) {
      return createAt;
    }
  }

  factory ContactPerson.fromJson(Map<String, dynamic> json) {
    int? regionId;
    if (json['region_id'] != null) {
      regionId = json['region_id'] is int
          ? json['region_id']
          : int.tryParse(json['region_id'].toString());
    } else if (json['region'] is Map<String, dynamic>) {
      final region = json['region'] as Map<String, dynamic>;
      regionId = region['id'] is int
          ? region['id']
          : int.tryParse(region['id']?.toString() ?? '');
    }

    return ContactPerson(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      position: json['position'],
      email: json['email']?.toString(),
      tgId: (json['tg_id'] ?? json['telegram'])?.toString(),
      address: json['address']?.toString(),
      regionId: regionId,
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? Author.fromJson(json['author'])
          : null,
      createAt: json['created_at'] ?? '',
    );
  }
}