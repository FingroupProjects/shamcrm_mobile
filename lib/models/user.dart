import 'dart:convert';

class User {
  final int id;
  final String? name;
  final String? login;
  final String? email;
  final String? phone;
  final String? image;
  User({
    required this.id,
    required this.name,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
  });

  User copyWith({
    int? id,
    String? name,
    String? login,
    String? email,
    String? phone,
    String? image,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      login: login ?? this.login,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
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
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(id: $id, name: $name, login: $login, email: $email, phone: $phone, image: $image)';
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
        other.image == image;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        login.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        image.hashCode;
  }
}
