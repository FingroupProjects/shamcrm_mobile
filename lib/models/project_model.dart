  // class Project {
  //   final int id;
  //   final String name;
    // final String? startDate;
    // final String? endDate;


  //   Project({
  //     required this.id,
  //     required this.name,
      // this.endDate,
      // this.startDate,
  //   });

  //   factory Project.fromJson(Map<String, dynamic> json) {
  //     return Project(
  //       id: json['id'],
  //       name: json['name'],
        // startDate: json['start_date'],
        // endDate: json['end_date']
  //     );
  //   }
  // }


import 'dart:convert';

class Project {
  final int id;
  final String name;  
  final String? startDate;
  final String? endDate;

  Project({
    required this.id,
    required this.name,
    this.endDate,
    this.startDate,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
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



ProjectsDataResponse leadsDataResponseFromJson(String str) => ProjectsDataResponse.fromJson(json.decode(str));

String leadsDataResponseToJson(ProjectsDataResponse data) => json.encode(data.toJson());

class ProjectsDataResponse {
  List<Project>? result;
  dynamic errors;

  ProjectsDataResponse({
    this.result,
    this.errors,
  });

  factory ProjectsDataResponse.fromJson(Map<String, dynamic> json) {
    return ProjectsDataResponse(
      result: json["result"] != null && json["result"]["data"] != null
          ? List<Project>.from(
              (json["result"]["data"] as List).map((x) => Project.fromJson(x))
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

