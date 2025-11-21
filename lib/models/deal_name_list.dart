class DealNameData {
  final int id;
  final String title;
  final String? createdAt;
  final String? updatedAt;

  DealNameData({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  factory DealNameData.fromJson(Map<String, dynamic> json) {
    return DealNameData(
      id: json['id'],
      title: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
class DealNameDataResponse {
  List<DealNameData>? result;
  dynamic errors;

  DealNameDataResponse({
    this.result,
    this.errors,
  });

  factory DealNameDataResponse.fromJson(Map<String, dynamic> json) {
    return DealNameDataResponse(
      result: json["result"] != null
          ? List<DealNameData>.from(
              (json["result"] as List).map((x) => DealNameData.fromJson(x)))
          : [],
      errors: json["errors"],
    );
  }
}