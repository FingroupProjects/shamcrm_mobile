class Author {
  final int id;
  final String name;
  final String? login;
  final String? email;
  final String? phone; // Поле может быть null
  // final String? image; // Поле может быть null
  final String? lastSeen; // Поле может быть null

  Author({
    required this.id,
    required this.name,
    this.login,
    this.email,
    this.phone,
    // this.image,
    this.lastSeen,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'],
      name: json['name'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      // image: json['image'],
      lastSeen: json['last_seen'],
    );
  }
}
