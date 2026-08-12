import 'package:crm_task_manager/utils/safe_converters.dart';

class MyTaskById {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final int statusId;
  final MyTaskStatusById? taskStatus;
  final String? taskFile;
  final int? taskNumber;
  final List<MyTaskFiles>? files;

  MyTaskById({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description,
    this.taskNumber,
    required this.statusId,
    this.taskStatus,
    this.taskFile,
    this.files,
  });

  factory MyTaskById.fromJson(Map<String, dynamic> json, [int statusId = 0]) {
    final taskStatusMap = SafeConverters.toMapOrNull(json['taskStatus']);
    return MyTaskById(
      id: SafeConverters.toInt(json['id']),
      taskNumber: SafeConverters.toIntOrNull(json['task_number']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени'),
      startDate: SafeConverters.toStringOrNull(json['from']),
      endDate: SafeConverters.toStringOrNull(json['to']),
      description: SafeConverters.toSafeString(json['description']),
      statusId: taskStatusMap != null
          ? SafeConverters.toInt(taskStatusMap['id'], defaultValue: statusId)
          : statusId,
      taskStatus: taskStatusMap != null
          ? MyTaskStatusById.fromJson(taskStatusMap)
          : null,
      taskFile: SafeConverters.toStringOrNull(json['file']),
      files: json['files'] != null
          ? SafeConverters.toList(json['files'])
              .map((x) => MyTaskFiles.fromJson(SafeConverters.toMap(x)))
              .toList()
          : null,
    );
  }
}

class MyTaskFileById {
  final String name;
  final String size;

  MyTaskFileById({required this.name, required this.size});

  Map<String, dynamic> toJson() => {
        "name": name,
        "size": size,
      };

  factory MyTaskFileById.fromJson(Map<String, dynamic> json) => MyTaskFileById(
        name: SafeConverters.toSafeString(json["name"]),
        size: SafeConverters.toSafeString(json["size"]),
      );
}

class MyTaskFiles {
  final int id;
  final String name;
  final String path;

  MyTaskFiles({
    required this.id,
    required this.name,
    required this.path,
  });

  factory MyTaskFiles.fromJson(Map<String, dynamic> json) {
    return MyTaskFiles(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      path: SafeConverters.toSafeString(json['path']),
    );
  }
}

class MyTaskStatusById {
  final int id;
  final String title;
  final String color;
  final int position;
  final String? taskStatus;

  MyTaskStatusById({
    required this.id,
    required this.title,
    required this.color,
    required this.position,
    this.taskStatus,
  });

  factory MyTaskStatusById.fromJson(Map<String, dynamic> json) {
    return MyTaskStatusById(
      id: SafeConverters.toInt(json['id']),
      title: SafeConverters.toSafeString(json['title']),
      color: SafeConverters.toSafeString(json['color'], defaultValue: '#000000'),
      position: SafeConverters.toInt(json['position']),
      taskStatus: SafeConverters.toStringOrNull(json['title']),
    );
  }
}

class MyTaskStatusNameById {
  final int id;
  final String name;
  final String? createdAt;
  final String? updatedAt;

  MyTaskStatusNameById({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory MyTaskStatusNameById.fromJson(Map<String, dynamic> json) {
    return MyTaskStatusNameById(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
