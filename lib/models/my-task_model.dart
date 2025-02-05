class MyTask {
  final int id;
  final String name;
  final int? taskNumber;
  final String? startDate;
  final String? endDate;
  final String? description;
  final int statusId;
  final MyTaskStatus? taskStatus;
  final MyTaskFile? file;
  final List<MyTaskCustomField> taskCustomFields;

  MyTask({
    required this.id,
    required this.name,
    this.taskNumber,
    required this.startDate,
    required this.endDate,
    this.description,
    required this.statusId,
    this.taskStatus,
    this.file,
    required this.taskCustomFields,
  });
 
  factory MyTask.fromJson(Map<String, dynamic> json, int taskStatusId) {
    try {
      return MyTask(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Без имени',
        taskNumber: json['task_number'] is int ? json['task_number'] : 0,
        startDate: json['from'],
        endDate: json['to'],
        description: json['description'] ?? '',
        statusId: taskStatusId,
        taskStatus: json['taskStatus'] != null
            ? MyTaskStatus.fromJson(json['taskStatus'])
            : null,
        file: json['file'] != null && json['file'] is Map<String, dynamic>
            ? MyTaskFile.fromJson(json['file'])
            : null,
        taskCustomFields: json['task_custom_fields'] != null
            ? (json['task_custom_fields'] as List)
                .map((field) => MyTaskCustomField.fromJson(field))
                .toList()
            : [],
      );
    } catch (e) {
      print('Error parsing MyTask: $e, JSON: $json');
      return MyTask(
        id: 0,
        name: 'Ошибка загрузки',
        startDate: null,
        endDate: null,
        description: 'Ошибка при получении данных',
        statusId: taskStatusId,
        taskCustomFields: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'task_number':taskNumber,
      'from': startDate,
      'to': endDate,
      'description': description,
      'statusId': statusId,
      'taskStatus': taskStatus?.toJson(),
      'file': file?.toJson(),
      'task_custom_fields': taskCustomFields.map((e) => e.toJson()).toList(),
    };
  }
}

class MyTaskCustomField {
  final int id;
  final String key;
  final String value;

  MyTaskCustomField({
    required this.id,
    required this.key,
    required this.value,
  });

  factory MyTaskCustomField.fromJson(Map<String, dynamic> json) {
    try {
      return MyTaskCustomField(
        id: json['id'] ?? 0,
        key: json['key'] ?? '',
        value: json['value'] ?? '',
      );
    } catch (e) {
      print('Error parsing MyTaskCustomField: $e');
      return MyTaskCustomField(id: 0, key: 'Unknown', value: 'Unknown');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
    };
  }
}

class MyTaskFile {
  final String name;
  final String size;

  MyTaskFile({required this.name, required this.size});

  Map<String, dynamic> toJson() => {
        "name": name,
        "size": size,
      };

  factory MyTaskFile.fromJson(Map<String, dynamic> json) {
    try {
      return MyTaskFile(
        name: json["name"] ?? 'Unknown',
        size: json["size"] ?? 'Unknown',
      );
    } catch (e) {
      return MyTaskFile(name: 'Unknown', size: 'Unknown');
    }
  }
}

class MyTaskStatus {
  final int id;
  final String title;
  final String? color;
  final int? organizationId;
  final int position;
  final int tasksCount;
  final int? authorId;

  MyTaskStatus({
    required this.id,
    required this.title,
    this.color,
    this.organizationId,
    required this.position,
    required this.tasksCount,
    this.authorId,
  });

  factory MyTaskStatus.fromJson(Map<String, dynamic> json) {
    return MyTaskStatus(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Без статуса',
      color: json['color'] ?? '#FFFFFF',
      organizationId: json['organization_id'] as int?,
      position: json['position'] ?? 0,
      authorId: json['author_id'] ?? 0,
      tasksCount: json['tasks_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'organization_id': organizationId,
      'position': position,
      'author_id': authorId,
      'tasks_count': tasksCount,
    };
  }
}
