class AddIncomeModel {
  String name;

  AddIncomeModel({required this.name});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': 'income',
    };
  }
}
