// Model
class UserTaskCompletionManager {
  final List<double> finishedTasksPercent;

  UserTaskCompletionManager({
    required this.finishedTasksPercent,
  });

  factory UserTaskCompletionManager.fromJson(Map<String, dynamic> json) {
    // Обработка массива данных из ключа 'result'
    List<dynamic> results = json['result'] ?? [];
    return UserTaskCompletionManager(
      finishedTasksPercent: results.map((e) => (e as num).toDouble()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'result': finishedTasksPercent,
      };
}
