class UserTask {
  final int id;
  final String name;
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
    this.startDate,
    this.endDate,
    this.phone,
    this.email,
    this.image,
  });

  factory UserTask.fromJson(Map<String, dynamic> json) {
    return UserTask(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      login: json['login']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      image: json['image']?.toString(),
    );
  }
}
