class MyTaskById {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final int statusId;
  final MyTaskStatusById? taskStatus;
  final String? taskFile;

  MyTaskById({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description,
    required this.statusId,
    this.taskStatus,
    this.taskFile,
  });

  factory MyTaskById.fromJson(Map<String, dynamic> json, [int statusId = 0]) {
    return MyTaskById(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Без имени',
      startDate: json['from'],
      endDate: json['to'],
      description: json['description'] ?? '',
      statusId: statusId,
      taskStatus: json['taskStatus'] != null
          ? MyTaskStatusById.fromJson(json['taskStatus'])
          : null,
      taskFile: json['file'],
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
        name: json["name"] as String,
        size: json["size"] as String,
      );
}

class MyTaskStatusById {
  final int id;
  final MyTaskStatusNameById taskStatus;
  final String color;

  MyTaskStatusById({
    required this.id,
    required this.taskStatus,
    required this.color,
  });

  // Метод для создания объекта из JSON
  factory MyTaskStatusById.fromJson(Map<String, dynamic> json) {
    return MyTaskStatusById(
      id: json['id'],
      taskStatus: MyTaskStatusNameById.fromJson(json['taskStatus']),
      color: json['color'],
    );
  }

  // Метод для преобразования объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskStatus': taskStatus.toJson(),
      'color': color,
    };
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
