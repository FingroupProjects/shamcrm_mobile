import 'dart:convert';
import 'package:crm_task_manager/models/directory_model.dart';

class DirectoryLink {
  final int id;
  final Directory directory;

  DirectoryLink({
    required this.id,
    required this.directory,
  });

  factory DirectoryLink.fromJson(Map<String, dynamic> json) => DirectoryLink(
        id: json['id'],
        directory: Directory.fromJson(json['directory']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'directory': directory.toJson(),
      };
}

class DirectoryLinkResponse {
  final List<DirectoryLink>? data;

  DirectoryLinkResponse({
    this.data,
  });

  factory DirectoryLinkResponse.fromJson(Map<String, dynamic> json) {
    return DirectoryLinkResponse(
      data: json['data'] != null
          ? List<DirectoryLink>.from(
              (json['data'] as List).map((x) => DirectoryLink.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'data': data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

DirectoryLinkResponse directoryLinkResponseFromJson(String str) =>
    DirectoryLinkResponse.fromJson(json.decode(str));

String directoryLinkResponseToJson(DirectoryLinkResponse data) =>
    json.encode(data.toJson());