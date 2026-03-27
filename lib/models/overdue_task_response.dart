class OverdueTasksResponse {
  final Result? result;
  final dynamic errors;

  OverdueTasksResponse({this.result, this.errors});

  factory OverdueTasksResponse.fromJson(Map<String, dynamic> json) {
    return OverdueTasksResponse(
      result: json['result'] != null ? Result.fromJson(json['result']) : null,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() => {
    'result': result?.toJson(),
    'errors': errors,
  };
}

class Result {
  final num? currentPage;
  final List<OverdueTask>? data;
  final String? firstPageUrl;
  final num? from;
  final num? lastPage;
  final String? lastPageUrl;
  final List<Link>? links;
  final String? nextPageUrl;
  final String? path;
  final num? perPage;
  final String? prevPageUrl;
  final num? to;
  final num? total;

  Result({
    this.currentPage,
    this.data,
    this.firstPageUrl,
    this.from,
    this.lastPage,
    this.lastPageUrl,
    this.links,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      currentPage: json['current_page'],
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => OverdueTask.fromJson(e))
          .toList(),
      firstPageUrl: json['first_page_url'],
      from: json['from'],
      lastPage: json['last_page'],
      lastPageUrl: json['last_page_url'],
      links: (json['links'] as List<dynamic>?)
          ?.map((e) => Link.fromJson(e))
          .toList(),
      nextPageUrl: json['next_page_url'],
      path: json['path'],
      perPage: json['per_page'],
      prevPageUrl: json['prev_page_url'],
      to: json['to'],
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() => {
    'current_page': currentPage,
    'data': data?.map((e) => e.toJson()).toList(),
    'first_page_url': firstPageUrl,
    'from': from,
    'last_page': lastPage,
    'last_page_url': lastPageUrl,
    'links': links?.map((e) => e.toJson()).toList(),
    'next_page_url': nextPageUrl,
    'path': path,
    'per_page': perPage,
    'prev_page_url': prevPageUrl,
    'to': to,
    'total': total,
  };
}

class OverdueTask {
  final num? id;
  final String? name;
  final num? taskNumber;
  final String? description;
  final String? from;
  final String? to;
  final num? overdue;
  final String? priorityLevel;
  final OverdueTaskStatus? taskStatus;
  final Project? project;
  final Author? author;

  OverdueTask({
    this.id,
    this.name,
    this.taskNumber,
    this.description,
    this.from,
    this.to,
    this.overdue,
    this.priorityLevel,
    this.taskStatus,
    this.project,
    this.author,
  });

  factory OverdueTask.fromJson(Map<String, dynamic> json) {
    return OverdueTask(
      id: json['id'],
      name: json['name'],
      taskNumber: json['task_number'],
      description: json['description'],
      from: json['from'],
      to: json['to'],
      overdue: json['overdue'],
      priorityLevel: json['priority_level'],
      taskStatus: json['task_status'] != null
          ? OverdueTaskStatus.fromJson(json['task_status'])
          : null,
      project:
      json['project'] != null ? Project.fromJson(json['project']) : null,
      author: json['author'] != null ? Author.fromJson(json['author']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'task_number': taskNumber,
    'description': description,
    'from': from,
    'to': to,
    'overdue': overdue,
    'priority_level': priorityLevel,
    'task_status': taskStatus?.toJson(),
    'project': project?.toJson(),
    'author': author?.toJson(),
  };
}

class OverdueTaskStatus {
  final num? id;
  final String? name;
  final String? color;

  OverdueTaskStatus({this.id, this.name, this.color});

  factory OverdueTaskStatus.fromJson(Map<String, dynamic> json) {
    return OverdueTaskStatus(
      id: json['id'],
      name: json['name'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
  };
}

class Project {
  final num? id;
  final String? name;

  Project({this.id, this.name});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

class Author {
  final num? id;
  final String? name;

  Author({this.id, this.name});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

class Link {
  final String? url;
  final String? label;
  final bool? active;

  Link({this.url, this.label, this.active});

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      url: json['url'],
      label: json['label'],
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'label': label,
    'active': active,
  };
}
