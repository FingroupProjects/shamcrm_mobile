class UserTaskCompletion {
  final int id;
  final String name;
  final double finishedTasksprocent;

  UserTaskCompletion({
    required this.id,
    required this.name,
    required this.finishedTasksprocent,
  });

  factory UserTaskCompletion.fromJson(Map<String, dynamic> json) {
    return UserTaskCompletion(
      id: json['user_id'] as int,
      name: json['name'] as String,
      // Обработка случая, когда процент может прийти как int или double
      finishedTasksprocent: json['finishedTasksprocent'] is int 
          ? (json['finishedTasksprocent'] as int).toDouble()
          : (json['finishedTasksprocent'] as num).toDouble(),
    );
  }

  // Можно добавить метод toJson если потребуется
  Map<String, dynamic> toJson() => {
    'user_id': id,
    'name': name,
    'finishedTasksprocent': finishedTasksprocent,
  };
}