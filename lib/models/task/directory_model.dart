import 'dart:convert';

class Directory {
  final int id;
  final String name;
  final bool? isMain;
  final int? fieldsCount;
  final int? entriesCount;
  final String? createdAt;

  Directory({
    required this.id,
    required this.name,
    this.isMain,
    this.fieldsCount,
    this.entriesCount,
    this.createdAt,
  });

  factory Directory.fromJson(Map<String, dynamic> json) => Directory(
        id: json["id"],
        name: json['name'] is String ? json['name'] : 'Без имени',
        isMain: json['is_main'],
        fieldsCount: json['fields_count'],
        entriesCount: json['entries_count'],
        createdAt: json['created_at'],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "is_main": isMain,
        "fields_count": fieldsCount,
        "entries_count": entriesCount,
        "created_at": createdAt,
      };

  @override
  String toString() {
    return 'Directory{id: $id, name: $name}';
  }
}

DirectoryDataResponse directoryDataResponseFromJson(String str) => DirectoryDataResponse.fromJson(json.decode(str));

String directoryDataResponseToJson(DirectoryDataResponse data) => json.encode(data.toJson());

class DirectoryDataResponse {
  List<Directory>? result;
  dynamic errors;

  DirectoryDataResponse({
    this.result,
    this.errors,
  });

  factory DirectoryDataResponse.fromJson(Map<String, dynamic> json) {
    return DirectoryDataResponse(
      result: json["result"] != null && json["result"]["data"] != null
          ? List<Directory>.from(
              (json["result"]["data"] as List).map((x) => Directory.fromJson(x)))
          : [],
      errors: json["errors"],
    );
  }

  Map<String, dynamic> toJson() => {
        "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
        "errors": errors,
      };
}