import 'dart:convert';

class LeadData {
  final int id;
  final String name;
  final int? managerId;
  final num? debt; // ← Добавляем поле долга

  LeadData({
    required this.id,
    required this.name,
    this.managerId,
    this.debt, // ← Добавляем в конструктор
  });

  factory LeadData.fromJson(Map<String, dynamic> json) => LeadData(
        id: json["id"],
        name: json['name'] is String ? json['name'] : 'Без имени',
        managerId: json['manager'] != null ? json['manager']['id'] : null,
        debt: json['debt'], // ← Парсим долг из JSON
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "managerId": managerId,
        "debt": debt, // ← Добавляем в toJson
      };

  @override
  String toString() {
    return 'LeadData{id: $id, name: $name, managerId: $managerId, debt: $debt}';
  }

  @override
  bool operator == (Object other) =>
      identical(this, other) ||
      other is LeadData &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

}

class Pagination {
  final int? total;
  final int? count;
  final int? perPage;
  final int? currentPage;
  final int? totalPages;

  Pagination({
    this.total,
    this.count,
    this.perPage,
    this.currentPage,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    total: json["total"],
    count: json["count"],
    perPage: json["per_page"],
    currentPage: json["current_page"],
    totalPages: json["total_pages"],
  );

  Map<String, dynamic> toJson() => {
    "total": total,
    "count": count,
    "per_page": perPage,
    "current_page": currentPage,
    "total_pages": totalPages,
  };

  @override
  String toString() {
    return 'Pagination{total: $total, count: $count, perPage: $perPage, currentPage: $currentPage, totalPages: $totalPages}';
  }
}


LeadsDataResponse leadsDataResponseFromJson(String str) => LeadsDataResponse.fromJson(json.decode(str));

String leadsDataResponseToJson(LeadsDataResponse data) => json.encode(data.toJson());

class LeadsDataResponse {
  List<LeadData>? result;
  dynamic errors;
  final Pagination? pagination;

  LeadsDataResponse({
    this.result,
    this.errors,
    this.pagination,
  });

  factory LeadsDataResponse.fromJson(Map<String, dynamic> json) {
    return LeadsDataResponse(
      result: json["result"] != null && json["result"]["data"] != null
          ? List<LeadData>.from(
              (json["result"]["data"] as List).map((x) => LeadData.fromJson(x))
            )
          : [],
      errors: json["errors"],
      pagination: json["result"] != null && json["result"]["pagination"] != null
          ? Pagination.fromJson(json["result"]["pagination"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
    "errors": errors,
    "pagination": pagination?.toJson(),
  };
}

