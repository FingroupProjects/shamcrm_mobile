import 'dart:convert';

class Department {
  final int id;
  final String name;
  final int usersCount;

  Department({
    required this.id,
    required this.name,
    required this.usersCount,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      usersCount: json['users_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'users_count': usersCount,
    };
  }
}