class UserTaskCompletion {
  final String name;
  final double finishedTasksprocent;

  UserTaskCompletion({
    required this.name,
    required this.finishedTasksprocent,
  });

  factory UserTaskCompletion.fromJson(Map<String, dynamic> json) {
    return UserTaskCompletion(
      name: json['name'] as String,
      // Обработка случая, когда процент может прийти как int или double
      finishedTasksprocent: json['finishedTasksprocent'] is int 
          ? (json['finishedTasksprocent'] as int).toDouble()
          : (json['finishedTasksprocent'] as num).toDouble(),
    );
  }

  // Можно добавить метод toJson если потребуется
  Map<String, dynamic> toJson() => {
    'name': name,
    'finishedTasksprocent': finishedTasksprocent,
  };
}