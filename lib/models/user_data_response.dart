import 'dart:convert';

UsersDataResponse usersDataResponseFromJson(String str) => UsersDataResponse.fromJson(json.decode(str));

String usersDataResponseToJson(UsersDataResponse data) => json.encode(data.toJson());

class UsersDataResponse {
  List<UserData>? result;
  dynamic errors;

  UsersDataResponse({
    this.result,
    this.errors,
  });

  factory UsersDataResponse.fromJson(Map<String, dynamic> json) => UsersDataResponse(
    result: json["result"] == null ? [] : List<UserData>.from(json["result"]!.map((x) => UserData.fromJson(x))),
    errors: json["errors"],
  );

  Map<String, dynamic> toJson() => {
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
    "errors": errors,
  };
}

class UserData {
  int id;
  String? name;
  String? login;
  String? email;
  String? phone;
  String? image;

  UserData({
    required this.id,
    this.name,
    this.login,
    this.email,
    this.phone,
    this.image,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    id: json["id"],
    name: json["name"],
    login: json["login"],
    email: json["email"],
    phone: json["phone"],
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "login": login,
    "email": email,
    "phone": phone,
    "image": image,
  };

  @override
  String toString() {
    // return 'UserData{id: $id, name: $name, login: $login, email!mail, phone: $phone, image: $image}';
    return '$name';
  }
}
