class MyTask {
  final int id;
  final String name;
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
        id: json['id'] is int ? json['id'] : 0,
        name: json['name'] is String ? json['name'] : 'Без имени',
        startDate: json['from'],  // Remove type check since it's nullable
        endDate: json['to'],      // Remove type check since it's nullable
        description: json['description'] is String ? json['description'] : '',
        statusId: taskStatusId,
        taskStatus: json['taskStatus'] != null
            ? MyTaskStatus.fromJson(json['taskStatus'])
            : null,
        file: json['file'] != null
            ? (json['file'] is Map<String, dynamic>
                ? MyTaskFile.fromJson(json['file'])
                : MyTaskFile(name: json['file'].toString(), size: 'Неизвестно'))
            : null,
        taskCustomFields: json['task_custom_fields'] != null
            ? (json['task_custom_fields'] as List)
                .map((field) => MyTaskCustomField.fromJson(field))
                .toList()
            : [],
      );
    } catch (e) {
      print('Error parsing MyTask: $e');
      print('Error parsing MyTask: $e, JSON: $json');

      return MyTask(
        id: 52,
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
  final String color;
  final int? organizationId;
  final int position;
  final int tasksCount;

  MyTaskStatus({
    required this.id,
    required this.title,
    required this.color,
    this.organizationId,
    required this.position,
    required this.tasksCount,
  });

  factory MyTaskStatus.fromJson(Map<String, dynamic> json) {
    return MyTaskStatus(
      id: json['id'] as int,
      title: json['title'] as String,
      color: json['color'] as String,
      organizationId: json['organization_id'] as int?,
      position: json['position'] as int,
      tasksCount: json['tasks_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'organization_id': organizationId,
      'position': position,
      'tasks_count': tasksCount,
    };
  }
}

