class CashRegisterModel {
  final int id;
  final String name;
  final List<UserModel> users;
  final DateTime createdAt;
  final DateTime updatedAt;

  CashRegisterModel({
    required this.id,
    required this.name,
    required this.users,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CashRegisterModel.fromJson(Map<String, dynamic> json) {
    return CashRegisterModel(
      id: json['id'],
      name: json['name'],
      users: (json['users'] as List<dynamic>)
          .map((e) => UserModel.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'users': users.map((e) => e.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class UserModel {
  final int id;
  final String name;
  final String lastname;
  final String login;
  final String email;
  final String phone;
  final String image;
  final String? lastSeen;
  final String? deletedAt;
  final String? telegramUserId;
  final String jobTitle;
  final bool online;
  final String fullName;
  final int isFirstLogin;
  final String uniqueId;

  UserModel({
    required this.id,
    required this.name,
    required this.lastname,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    required this.lastSeen,
    required this.deletedAt,
    required this.telegramUserId,
    required this.jobTitle,
    required this.online,
    required this.fullName,
    required this.isFirstLogin,
    required this.uniqueId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
      lastSeen: json['last_seen'],
      deletedAt: json['deleted_at'],
      telegramUserId: json['telegram_user_id'],
      jobTitle: json['job_title'],
      online: json['online'] ?? false,
      fullName: json['full_name'],
      isFirstLogin: json['is_first_login'],
      uniqueId: json['unique_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lastname': lastname,
    'login': login,
    'email': email,
    'phone': phone,
    'image': image,
    'last_seen': lastSeen,
    'deleted_at': deletedAt,
    'telegram_user_id': telegramUserId,
    'job_title': jobTitle,
    'online': online,
    'full_name': fullName,
    'is_first_login': isFirstLogin,
    'unique_id': uniqueId,
  };
}
