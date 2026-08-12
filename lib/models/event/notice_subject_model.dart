class SubjectData {
  final int id;
  final String title;
  final String? createdAt;
  final String? updatedAt;

  SubjectData({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  factory SubjectData.fromJson(Map<String, dynamic> json) {
    return SubjectData(
      id: json['id'],
      title: json['title'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class SubjectDataResponse {
  List<SubjectData>? result;
  dynamic errors;

  SubjectDataResponse({
    this.result,
    this.errors,
  });

  factory SubjectDataResponse.fromJson(Map<String, dynamic> json) {
    return SubjectDataResponse(
      result: json["result"] != null
          ? List<SubjectData>.from(
              (json["result"] as List).map((x) => SubjectData.fromJson(x)))
          : [],
      errors: json["errors"],
    );
  }
}