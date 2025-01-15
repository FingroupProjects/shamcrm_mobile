

import 'dart:convert';

class ProjectTask {
  final int id;
  final String name;  
  final String? startDate;
  final String? endDate;

  ProjectTask({
    required this.id,
    required this.name,
    this.endDate,
    this.startDate,
  });

  factory ProjectTask.fromJson(Map<String, dynamic> json) => ProjectTask(
    id: json["id"],
    name: json['name'] is String ? json['name'] : 'Без имени',
    startDate: json['start_date'],
    endDate: json['end_date']
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "start_date": startDate,
    "end_date": endDate,
  };

  @override
  String toString() {
    return 'Project{id: $id, name: $name}';
  }
}

ProjectTaskDataResponse leadsDataResponseFromJson(String str) => ProjectTaskDataResponse.fromJson(json.decode(str));

String leadsDataResponseToJson(ProjectTaskDataResponse data) => json.encode(data.toJson());

class ProjectTaskDataResponse {
  List<ProjectTask>? result;
  dynamic errors;

  ProjectTaskDataResponse({
    this.result,
    this.errors,
  });

  factory ProjectTaskDataResponse.fromJson(Map<String, dynamic> json) {
    return ProjectTaskDataResponse(
      result: json["result"] != null && json["result"]["data"] != null
          ? List<ProjectTask>.from(
              (json["result"]["data"] as List).map((x) => ProjectTask.fromJson(x))
            )
          : [],
      errors: json["errors"],
    );
  }

  Map<String, dynamic> toJson() => {
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
    "errors": errors,
  };
}

