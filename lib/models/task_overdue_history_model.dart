class TaskOverdueHistoryResponse {
  final List<TaskOverdueHistoryItem>? result;
  final dynamic errors;

  TaskOverdueHistoryResponse({
    this.result,
    this.errors,
  });

  factory TaskOverdueHistoryResponse.fromJson(Map<String, dynamic> json) {
    return TaskOverdueHistoryResponse(
      result: json['result'] != null
          ? (json['result'] as List)
              .map((item) => TaskOverdueHistoryItem.fromJson(item))
              .toList()
          : null,
      errors: json['errors'],
    );
  }
}

class TaskOverdueHistoryItem {
  final HistoryAuthor? author;
  final String type; // "overdue", "finished", "change_deadline"
  final String createdAt;
  final HistoryBody? body;

  TaskOverdueHistoryItem({
    this.author,
    required this.type,
    required this.createdAt,
    this.body,
  });

  factory TaskOverdueHistoryItem.fromJson(Map<String, dynamic> json) {
    return TaskOverdueHistoryItem(
      author: json['author'] != null
          ? HistoryAuthor.fromJson(json['author'])
          : null,
      type: json['type']?.toString() ?? 'overdue',
      createdAt: json['created_at']?.toString() ?? '',
      body: json['body'] != null ? HistoryBody.fromJson(json['body']) : null,
    );
  }
}

class HistoryAuthor {
  final int id;
  final String name;
  final String? lastname;
  final String? login;
  final String? email;
  final String? phone;
  final String? image;
  final String? jobTitle;

  HistoryAuthor({
    required this.id,
    required this.name,
    this.lastname,
    this.login,
    this.email,
    this.phone,
    this.image,
    this.jobTitle,
  });

  factory HistoryAuthor.fromJson(Map<String, dynamic> json) {
    return HistoryAuthor(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      lastname: json['lastname']?.toString(),
      login: json['login']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      image: json['image']?.toString(),
      jobTitle: json['job_title']?.toString(),
    );
  }

  String get fullName {
    if (lastname != null && lastname!.isNotEmpty) {
      return '$name $lastname';
    }
    return name;
  }
}

class HistoryBody {
  final int? overdueDays;
  final int? workingHours;
  final String? toDate;
  final String? fromDate;

  HistoryBody({
    this.overdueDays,
    this.workingHours,
    this.toDate,
    this.fromDate,
  });

  factory HistoryBody.fromJson(Map<String, dynamic> json) {
    return HistoryBody(
      overdueDays: json['overdue_days'],
      workingHours: json['working_hours'],
      toDate: json['to_date']?.toString(),
      fromDate: json['from_date']?.toString(),
    );
  }
}
