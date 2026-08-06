import 'package:crm_task_manager/models/role_model.dart';

class UserByIdProfile {
  final int id;
  final String name;
  final String lastname;
  final String Pname;
  final String login;
  final String email;
  final String phone;
  final String? image;
  final String? lastSeen;
  final List<Role>? role;
  final String? uniqueId; // Новое поле
  final int? internalNumber;

  UserByIdProfile({
    required this.id,
    required this.name,
    required this.lastname,
    required this.Pname,
    required this.login,
    required this.email,
    required this.phone,
    this.image,
    this.lastSeen,
    this.role,
    this.uniqueId, // Добавляем в конструктор
    this.internalNumber,
  });

  factory UserByIdProfile.fromJson(Map<String, dynamic> json) {
    final internalNumberRaw = json['internal_number'];
    final int? internalNumber = internalNumberRaw is int
        ? internalNumberRaw
        : int.tryParse(internalNumberRaw?.toString() ?? '');

    return UserByIdProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указано',
      lastname: json['lastname'] ?? '',
      Pname: json['patronymic'] ?? 'Не указано',
      login: json['login'] ?? 'Не указано',
      email: json['email'] ?? 'Не указано',
      phone: json['phone'] ?? '',
      image: json['image'] as String?,
      lastSeen: json['last_seen'] as String?,
      uniqueId: json['unique_id'] as String?, // Парсим unique_id
      internalNumber: internalNumber,
      role: (json['roles'] as List<dynamic>?)
          ?.map((roleJson) => Role.fromJson(roleJson))
          .toList(),
    );
  }
}