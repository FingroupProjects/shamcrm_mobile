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
    try {
      return MyTaskById(
        id: json['id'] ?? 0,
        taskNumber: json['task_number'] ?? 0,
        name: json['name'] ?? 'Без имени',
        startDate: json['from']?.toString(),
        endDate: json['to']?.toString(),
        description: json['description'] ?? '',
        statusId: json['taskStatus']?['id'] ?? statusId, // Изменено здесь
        taskStatus: json['taskStatus'] != null 
            ? MyTaskStatusById.fromJson(json['taskStatus'] as Map<String, dynamic>)
            : null,
        taskFile: json['file']?.toString(),
        files: json['files'] != null
            ? List<MyTaskFiles>.from(
                (json['files'] as List).map((x) => MyTaskFiles.fromJson(x as Map<String, dynamic>)))
            : null,
      );
    } catch (e, stackTrace) {
      print('Error parsing MyTaskById: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
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
        name: json["name"] as String,
        size: json["size"] as String,
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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      path: json['path'] ?? '',
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
    try {
      return MyTaskStatusById(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        color: json['color'] ?? '#000000',
        position: json['position'] ?? 0,
        taskStatus: json['title']?.toString(), // Используем title как taskStatus
      );
    } catch (e) {
      print('Error parsing MyTaskStatusById: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

//   // Метод для преобразования объекта в JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'taskStatus': taskStatus.toJson(),
//       'color': color,
//     };
//   }
// }

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

  // Метод для создания вложенного объекта из JSON
  factory MyTaskStatusNameById.fromJson(Map<String, dynamic> json) {
    return MyTaskStatusNameById(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  // Метод для преобразования вложенного объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
