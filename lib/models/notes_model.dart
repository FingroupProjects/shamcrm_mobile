// notes_model.dart
class Notes {
  final int id;
  final String body;
  final DateTime date;

  Notes({
    required this.id,
    required this.body,
    required this.date,
  });

  factory Notes.fromJson(Map<String, dynamic> json) {
    return Notes(
      id: json['id'],
      body: json['body'],
      date: DateTime.parse(json['date']),
    );
  }
}
