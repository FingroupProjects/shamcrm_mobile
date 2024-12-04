class ContactPerson {
  final int id;
  final String name;
  final String phone;
  final String? position;

  ContactPerson({
    required this.id,
    required this.name,
    required this.phone,
    this.position,
  });

  factory ContactPerson.fromJson(Map<String, dynamic> json) {
    return ContactPerson(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? 'Без имени',
      phone: json['phone'] ?? '',
      position: json['position'],
    );
  }
}
