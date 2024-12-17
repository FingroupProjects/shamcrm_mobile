import 'package:crm_task_manager/models/role_model.dart';

class UserByIdProfile {
  final int id;
  final String name;
  final String Sname;
  final String Pname;

  final String login;
  final String email;
  final String phone;
  final String? image;
  final String? lastSeen;
  final List<Role>? role;

  UserByIdProfile({
    required this.id,
    required this.name,
    required this.Sname,
    required this.Pname,
    required this.login,
    required this.email,
    required this.phone,
    this.image,
    this.lastSeen,
    this.role,
  });

  factory UserByIdProfile.fromJson(Map<String, dynamic> json) {
    return UserByIdProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указано',
      Sname: json['surname'] ?? 'Не указано',
      Pname: json['patronymic'] ?? 'Не указано',
      login: json['login'] ?? 'Не указано',
      email: json['email'] ?? 'Не указано',
      phone: json['phone'] ?? 'Не указано',
      image: json['image'] as String?,
      lastSeen: json['last_seen'] as String?,
      role: (json['roles'] as List<dynamic>?)
          ?.map((roleJson) => Role.fromJson(roleJson))
          .toList(),
    );
  }
}
