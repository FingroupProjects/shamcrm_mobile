import 'dart:convert';
import 'role_model.dart'; // Импорт модели Role

class User {
  final int id;
  final String? name;
  final String? login;
  final String? email;
  final String? phone;
  final String? image;
  final List<Role>? role; // Изменено на List<Role>

  User({
    required this.id,
    required this.name,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    this.role, // Обновлен параметр конструктора
  });

  User copyWith({
    int? id,
    String? name,
    String? login,
    String? email,
    String? phone,
    String? image,
    List<Role>? role, // Обновлен параметр copyWith
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      login: login ?? this.login,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      role: role ?? this.role, // Обновлен copyWith метод
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
      // Преобразование списка ролей в список Map
      result.addAll({
        'roles': role!.map((role) => role.toMap()).toList()
      });
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
      role: map['roles'] != null 
        ? List<Role>.from(
            map['roles']?.map((x) => Role.fromJson(x))
          )
        : null, // Парсинг списка ролей из Map
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(id: $id, name: $name, login: $login, email!mail, phone: $phone, image: $image, roles: $role)';
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
        _listEquals(other.role, role); // Специальное сравнение списков
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        login.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        image.hashCode ^
        _listHash(role); // Специальный метод хэширования списка
  }

  // Вспомогательный метод для сравнения списков
  bool _listEquals(List<Role>? list1, List<Role>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    
    return true;
  }

  // Вспомогательный метод для хэширования списка
  int _listHash(List<Role>? list) {
    if (list == null) return 0;
    return list.fold(0, (prev, element) => prev ^ element.hashCode);
  }
}