import 'dart:convert';

import 'package:crm_task_manager/utils/safe_converters.dart';

UsersDataResponse usersDataResponseFromJson(String str) =>
    UsersDataResponse.fromJson(json.decode(str));

String usersDataResponseToJson(UsersDataResponse data) =>
    json.encode(data.toJson());

class UsersDataResponse {
  List<UserData>? result;
  dynamic errors;

  UsersDataResponse({
    this.result,
    this.errors,
  });

  factory UsersDataResponse.fromJson(Map<String, dynamic> json) =>
      UsersDataResponse(
        result: _parseUsers(json['result']),
        errors: json['errors'],
      );

  static List<UserData> _parseUsers(dynamic raw) {
    final items = raw is List
        ? raw
        : SafeConverters.toList(SafeConverters.toMapOrNull(raw)?['data']);

    final users = <UserData>[];
    for (final item in items) {
      final map = SafeConverters.toMapOrNull(item);
      if (map == null) continue;
      final user = UserData.fromJson(map);
      if (user.id <= 0) continue;
      users.add(user);
    }
    return users;
  }

  Map<String, dynamic> toJson() => {
        'result': result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toJson())),
        'errors': errors,
      };
}

class UserData {
  int id;
  String name;
  String lastname;
  String? login;
  String? email;
  String? phone;
  String? image;

  UserData({
    required this.id,
    required this.name,
    required this.lastname,
    this.login,
    this.email,
    this.phone,
    this.image,
  });

  String get displayName {
    final fullName = '$name $lastname'.trim();
    if (fullName.isNotEmpty) return fullName;
    return login?.trim().isNotEmpty == true ? login!.trim() : '';
  }

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        id: SafeConverters.toInt(json['id']),
        name: SafeConverters.toSafeString(json['name']),
        lastname: SafeConverters.toSafeString(json['lastname']),
        login: SafeConverters.toStringOrNull(json['login']),
        email: SafeConverters.toStringOrNull(json['email']),
        phone: SafeConverters.toStringOrNull(json['phone']),
        image: SafeConverters.toStringOrNull(json['image']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lastname': lastname,
        'login': login,
        'email': email,
        'phone': phone,
        'image': image,
      };

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is UserData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => displayName;
}
