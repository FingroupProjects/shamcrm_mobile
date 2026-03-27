class OutcomeResponseModel {
  final List<OutcomeModel> data;
  final PaginationModel pagination;

  OutcomeResponseModel({
    required this.data,
    required this.pagination,
  });

  factory OutcomeResponseModel.fromJson(Map<String, dynamic> json) {
    return OutcomeResponseModel(
      data: (json['data'] as List)
          .map((item) => OutcomeModel.fromJson(item))
          .toList(),
      pagination: PaginationModel.fromJson(json['pagination']),
    );
  }
}

class PaginationModel {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  PaginationModel({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total: json['total'],
      count: json['count'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
    );
  }
}

class OutcomeModel {
  final int id;
  final String name;
  final String type;

  OutcomeModel({
    required this.id,
    required this.name,
    required this.type,
  });

  factory OutcomeModel.fromJson(Map<String, dynamic> json) {
    return OutcomeModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
  };
}
