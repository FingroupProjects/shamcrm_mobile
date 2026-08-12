import 'package:crm_task_manager/utils/safe_converters.dart';

class UserTask {
  final int id;
  final String name;
  final String lastname;

  final String? login;
  final String? startDate;
  final String? endDate;
  final String? phone;
  final String? email;
  final String? image;

  UserTask({
    required this.id,
    required this.name,
    this.login,
    required this.lastname,
    this.startDate,
    this.endDate,
    this.phone,
    this.email,
    this.image,
  });

  factory UserTask.fromJson(Map<String, dynamic> json) {
    return UserTask(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      lastname: SafeConverters.toSafeString(json['lastname']),
      login: SafeConverters.toStringOrNull(json['login']),
      startDate: SafeConverters.toStringOrNull(json['startDate']),
      endDate: SafeConverters.toStringOrNull(json['endDate']),
      phone: SafeConverters.toStringOrNull(json['phone']),
      email: SafeConverters.toStringOrNull(json['email']),
      image: SafeConverters.toStringOrNull(json['image']),
    );
  }
}
