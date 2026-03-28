class AddExpenseModel {
  String name;

  AddExpenseModel({required this.name});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': 'expense',
    };
  }
}
