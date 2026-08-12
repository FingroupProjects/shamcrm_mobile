import 'package:crm_task_manager/models/user/role_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

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
    return UserByIdProfile(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Не указано'),
      lastname: SafeConverters.toSafeString(json['lastname']),
      Pname: SafeConverters.toSafeString(json['patronymic'], defaultValue: 'Не указано'),
      login: SafeConverters.toSafeString(json['login'], defaultValue: 'Не указано'),
      email: SafeConverters.toSafeString(json['email'], defaultValue: 'Не указано'),
      phone: SafeConverters.toSafeString(json['phone']),
      image: SafeConverters.toStringOrNull(json['image']),
      lastSeen: SafeConverters.toStringOrNull(json['last_seen']),
      uniqueId: SafeConverters.toStringOrNull(json['unique_id']),
      internalNumber: SafeConverters.toIntOrNull(json['internal_number']),
      role: json['roles'] != null
          ? SafeConverters.toList(json['roles'])
              .map((roleJson) => Role.fromJson(SafeConverters.toMap(roleJson)))
              .toList()
          : null,
    );
  }
}
