class MyTaskById {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final int statusId;
  final MyTaskStatusById? taskStatus;
  final String? color;
  final List<MyTaskCustomFieldsById> taskCustomFields;
  final String? taskFile;

  MyTaskById({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description,
    required this.statusId,
    this.taskStatus,
    this.color,
    required this.taskCustomFields,
    this.taskFile,
  });

  factory MyTaskById.fromJson(Map<String, dynamic> json, int taskStatusId) {
    return MyTaskById(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      startDate: json['from'],
      endDate: json['to'],
      description: json['description'] is String ? json['description'] : '',
      statusId: taskStatusId,
      taskStatus: json['taskStatus'] != null &&
              json['taskStatus'] is Map<String, dynamic>
          ? MyTaskStatusById.fromJson(json['taskStatus'])
          : null,
      taskFile: json['file'],
      taskCustomFields: (json['task_custom_fields'] as List<dynamic>?)
              ?.map((field) => MyTaskCustomFieldsById.fromJson(field))
              .toList() ??
          [],
    );
  }
}

class MyTaskCustomFieldsById {
  final int id;
  final String key;
  final String value;

  MyTaskCustomFieldsById({
    required this.id,
    required this.key,
    required this.value,
  });

  factory MyTaskCustomFieldsById.fromJson(Map<String, dynamic> json) {
    return MyTaskCustomFieldsById(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class ChatById {
  final int id;
  final String? lead;
  final String type;
  final String? user;
  final bool canSendMessage;

  ChatById({
    required this.id,
    this.lead,
    required this.type,
    this.user,
    required this.canSendMessage,
  });

  factory ChatById.fromJson(Map<String, dynamic> json) {
    return ChatById(
      id: json['id'] ?? 0,
      lead: json['lead'] as String?,
      type: json['type'] as String? ?? 'unknown',
      user: json['user'] as String?,
      canSendMessage: json["can_send_message"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead': lead,
      'type': type,
      'user': user,
      'can_send_message': canSendMessage,
    };
  }
}

class UserById {
  final int id;
  final String name;
  final String email;
  final String phone;

  UserById({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory UserById.fromJson(Map<String, dynamic> json) {
    return UserById(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указано',
      email: json['email'] ?? 'Не указано',
      phone: json['phone'] ?? 'Не указано',
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


/*

*/