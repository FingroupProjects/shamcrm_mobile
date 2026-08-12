import 'package:crm_task_manager/utils/safe_converters.dart';

class OverdueTasksResponse {
  final Result? result;
  final dynamic errors;

  OverdueTasksResponse({this.result, this.errors});

  factory OverdueTasksResponse.fromJson(Map<String, dynamic> json) {
    return OverdueTasksResponse(
      result: SafeConverters.toMapOrNull(json['result']) != null
          ? Result.fromJson(SafeConverters.toMap(json['result']))
          : null,
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
      currentPage: SafeConverters.toNumOrNull(json['current_page']),
      data: SafeConverters.toList(json['data']).isEmpty
          ? null
          : SafeConverters.toList(json['data'])
              .whereType<Map<String, dynamic>>()
              .map((e) => OverdueTask.fromJson(e))
              .toList(),
      firstPageUrl: SafeConverters.toStringOrNull(json['first_page_url']),
      from: SafeConverters.toNumOrNull(json['from']),
      lastPage: SafeConverters.toNumOrNull(json['last_page']),
      lastPageUrl: SafeConverters.toStringOrNull(json['last_page_url']),
      links: SafeConverters.toList(json['links']).isEmpty
          ? null
          : SafeConverters.toList(json['links'])
              .whereType<Map<String, dynamic>>()
              .map((e) => Link.fromJson(e))
              .toList(),
      nextPageUrl: SafeConverters.toStringOrNull(json['next_page_url']),
      path: SafeConverters.toStringOrNull(json['path']),
      perPage: SafeConverters.toNumOrNull(json['per_page']),
      prevPageUrl: SafeConverters.toStringOrNull(json['prev_page_url']),
      to: SafeConverters.toNumOrNull(json['to']),
      total: SafeConverters.toNumOrNull(json['total']),
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
      id: SafeConverters.toNumOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      taskNumber: SafeConverters.toNumOrNull(json['task_number']),
      description: SafeConverters.toStringOrNull(json['description']),
      from: SafeConverters.toStringOrNull(json['from']),
      to: SafeConverters.toStringOrNull(json['to']),
      overdue: SafeConverters.toNumOrNull(json['overdue']),
      priorityLevel: SafeConverters.toStringOrNull(json['priority_level']),
      taskStatus: SafeConverters.toMapOrNull(json['task_status']) != null
          ? OverdueTaskStatus.fromJson(SafeConverters.toMap(json['task_status']))
          : null,
      project: SafeConverters.toMapOrNull(json['project']) != null
          ? Project.fromJson(SafeConverters.toMap(json['project']))
          : null,
      author: SafeConverters.toMapOrNull(json['author']) != null
          ? Author.fromJson(SafeConverters.toMap(json['author']))
          : null,
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
      id: SafeConverters.toNumOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      color: SafeConverters.toStringOrNull(json['color']),
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
      id: SafeConverters.toNumOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
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
      id: SafeConverters.toNumOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
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
      url: SafeConverters.toStringOrNull(json['url']),
      label: SafeConverters.toStringOrNull(json['label']),
      active: SafeConverters.toBoolOrNull(json['active']),
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'label': label,
    'active': active,
  };
}
