class AddCashDeskModel {
  String name;
  List<int> users;

  AddCashDeskModel({required this.name, required this.users});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'users': users,
    };
  }
}