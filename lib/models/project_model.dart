import 'dart:convert';

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
        id: json["id"],
        name: json['name'] is String ? json['name'] : 'Без имени',
        startDate: json['start_date'],
        endDate: json['end_date'],
        statusId: json['status_id'] is int
            ? json['status_id']
            : int.tryParse(json['status_id']?.toString() ?? ''),
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
      result: json["result"] != null && json["result"]["data"] != null
          ? List<Project>.from(
              (json["result"]["data"] as List).map((x) => Project.fromJson(x)))
          : [],
      errors: json["errors"],
      pagination: json["result"]?["pagination"] is Map<String, dynamic>
          ? ProjectPagination.fromJson(json["result"]["pagination"])
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
        currentPage: json['current_page'] as int?,
        totalPages: json['total_pages'] as int?,
      );
}
