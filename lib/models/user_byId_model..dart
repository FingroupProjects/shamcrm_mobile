class UserByIdProfile {
  final int id;
  final String name;
  final String login;
  final String email;
  final String phone;
  final String? image;
  final String? lastSeen;

  UserByIdProfile({
    required this.id,
    required this.name,
    required this.login,
    required this.email,
    required this.phone,
    this.image,
    this.lastSeen,
  });

  factory UserByIdProfile.fromJson(Map<String, dynamic> json) {
    return UserByIdProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указано',
      login: json['login'] ?? 'Не указано',
      email: json['email'] ?? 'Не указано',
      phone: json['phone'] ?? 'Не указано',
      image: json['image'] as String?,
      lastSeen: json['last_seen'] as String?,
    );
  }
}