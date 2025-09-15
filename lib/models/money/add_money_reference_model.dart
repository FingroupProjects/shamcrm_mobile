class AddMoneyReferenceModel {
  String name;
  List<int> users;

  AddMoneyReferenceModel({required this.name, required this.users});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'users': users,
    };
  }
}