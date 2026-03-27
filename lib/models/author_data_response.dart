import 'dart:convert';

AuthorsDataResponse authorsDataResponseFromJson(String str) =>
    AuthorsDataResponse.fromJson(json.decode(str));

String authorsDataResponseToJson(AuthorsDataResponse data) =>
    json.encode(data.toJson());

class AuthorsDataResponse {
  List<AuthorData>? result;
  dynamic errors;

  AuthorsDataResponse({
    this.result,
    this.errors,
  });

  factory AuthorsDataResponse.fromJson(Map<String, dynamic> json) =>
      AuthorsDataResponse(
        result: json["result"] == null
            ? []
            : List<AuthorData>.from(
                json["result"]!.map((x) => AuthorData.fromJson(x))),
        errors: json["errors"],
      );

  Map<String, dynamic> toJson() => {
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toJson())),
        "errors": errors,
      };
}

class AuthorData {
  int id;
  String name;
  String lastname;
  String? login;
  String? email;
  String? phone;
  String? image;

  AuthorData({
    required this.id,
    required this.name,
    required this.lastname,
    this.login,
    this.email,
    this.phone,
    this.image,
  });

  factory AuthorData.fromJson(Map<String, dynamic> json) => AuthorData(
        id: json["id"],
        name: json["name"],
        lastname: json["lastname"],
        login: json["login"],
        email: json["email"],
        phone: json["phone"],
        image: json["image"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "lastname": lastname,
        "login": login,
        "email": email,
        "phone": phone,
        "image": image,
      };

  @override
  String toString() {
    // return 'AuthorData{id: $id, name: $name, login: $login, email!mail, phone: $phone, image: $image}';
    return '$name';
  }
}
