class UserTask {
  final int id;
  final String name;
  final String? startDate;
  final String? login;
  final String? endDate;
  final int phone;
  final String? email;


  UserTask({
    required this.id,
    required this.name,
    this.login,
    this.endDate,
    this.startDate,
    required this.phone,
    this.email,
  });

  factory UserTask.fromJson(Map<String, dynamic> json) {
    return UserTask(
      id: json['id'],
      name: json['name'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
     
    );
  }
}
