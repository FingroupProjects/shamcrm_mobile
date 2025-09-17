class AddIncomeModel {
  String name;
  List<int> users;

  AddIncomeModel({required this.name, required this.users});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': 'income',
      'users': users,
    };
  }
}
