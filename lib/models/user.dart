import 'dart:convert';
import 'role_model.dart'; // Import the Role class

class User {
  final int id;
  final String? name;
  final String? login;
  final String? email;
  final String? phone;
  final String? image;
  final Role? role; // Added role property

  User({
    required this.id,
    required this.name,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    this.role, // Added role parameter in the constructor
  });

  User copyWith({
    int? id,
    String? name,
    String? login,
    String? email,
    String? phone,
    String? image,
    Role? role, // Added role parameter in copyWith
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      login: login ?? this.login,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      role: role ?? this.role, // Updated copyWith method
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    if (name != null) {
      result.addAll({'name': name});
    }
    if (login != null) {
      result.addAll({'login': login});
    }
    if (email != null) {
      result.addAll({'email': email});
    }
    if (phone != null) {
      result.addAll({'phone': phone});
    }
    if (image != null) {
      result.addAll({'image': image});
    }
    if (role != null) {
      result.addAll({'role': role?.toMap()}); // Convert role to map
    }

    return result;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt() ?? 0,
      name: map['name'],
      login: map['login'],
      email: map['email'],
      phone: map['phone'],
      image: map['image'],
      role: map['role'] != null ? Role.fromJson(map['role']) : null, // Parse role from map
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(id: $id, name: $name, login: $login, email: $email, phone: $phone, image: $image, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.name == name &&
        other.login == login &&
        other.email == email &&
        other.phone == phone &&
        other.image == image &&
        other.role == role; // Updated equality check
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        login.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        image.hashCode ^
        role.hashCode; // Updated hashCode
  }
}
