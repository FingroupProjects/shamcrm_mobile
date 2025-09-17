import 'cash_register_model.dart';

class IncomeResponseModel {
  final List<IncomeModel> data;
  final PaginationModel pagination;

  IncomeResponseModel({
    required this.data,
    required this.pagination,
  });

  factory IncomeResponseModel.fromJson(Map<String, dynamic> json) {
    return IncomeResponseModel(
      data: (json['data'] as List)
          .map((item) => IncomeModel.fromJson(item))
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

class IncomeModel {
  final int id;
  final String name;
  final String type;
  final List<UserModel> users;
  final DateTime createdAt;
  final DateTime updatedAt;

  IncomeModel({
    required this.id,
    required this.name,
    required this.type,
    required this.users,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      users: (json['users'] as List<dynamic>?)
          ?.map((e) => UserModel.fromJson(e))
          .toList() ?? [],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'users': users.map((e) => e.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
