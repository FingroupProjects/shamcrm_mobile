class DealTask {
  final int id;
  final String name;
  final String? description;
  final String from;
  final String to;

  DealTask({
    required this.id,
    required this.name,
    this.description,
    required this.from,
    required this.to,
  });

  factory DealTask.fromJson(Map<String, dynamic> json) {
    return DealTask(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? 'Без имени',
      description: json['description'],
      from: json['from'] ?? '',
      to: json['to'] ?? '',
    );
  }
}