class AddOutcomeModel {
  String name;

  AddOutcomeModel({required this.name});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': 'outcome',
    };
  }
}
