import 'dart:convert';

import 'package:crm_task_manager/utils/safe_converters.dart';

class Project {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final int? statusId;

  Project({
    required this.id,
    required this.name,
    this.endDate,
    this.startDate,
    this.statusId,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: SafeConverters.toInt(json["id"]),
        name: SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени'),
        startDate: SafeConverters.toStringOrNull(json['start_date']),
        endDate: SafeConverters.toStringOrNull(json['end_date']),
        statusId: SafeConverters.toIntOrNull(json['status_id']),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "start_date": startDate,
        "end_date": endDate,
        "status_id": statusId,
      };

  @override
  String toString() {
    return 'Project{id: $id, name: $name}';
  }
}

ProjectsDataResponse leadsDataResponseFromJson(String str) =>
    ProjectsDataResponse.fromJson(json.decode(str));

String leadsDataResponseToJson(ProjectsDataResponse data) =>
    json.encode(data.toJson());

class ProjectsDataResponse {
  List<Project>? result;
  dynamic errors;
  ProjectPagination? pagination;

  ProjectsDataResponse({
    this.result,
    this.errors,
    this.pagination,
  });

  factory ProjectsDataResponse.fromJson(Map<String, dynamic> json) {
    return ProjectsDataResponse(
      result: SafeConverters.toMapOrNull(json["result"]) != null &&
              SafeConverters.toList(json["result"]["data"]).isNotEmpty
          ? SafeConverters.toList(json["result"]["data"])
              .whereType<Map<String, dynamic>>()
              .map((x) => Project.fromJson(x))
              .toList()
          : [],
      errors: json["errors"],
      pagination: SafeConverters.toMapOrNull(json["result"]?["pagination"]) !=
              null
          ? ProjectPagination.fromJson(
              SafeConverters.toMap(json["result"]["pagination"]))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toJson())),
        "errors": errors,
      };
}

class ProjectPagination {
  final int? currentPage;
  final int? totalPages;

  ProjectPagination({this.currentPage, this.totalPages});

  factory ProjectPagination.fromJson(Map<String, dynamic> json) =>
      ProjectPagination(
        currentPage: SafeConverters.toIntOrNull(json['current_page']),
        totalPages: SafeConverters.toIntOrNull(json['total_pages']),
      );
}
