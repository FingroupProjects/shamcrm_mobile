import '../../../../models/page_2/openings/supplier_openings_model.dart';

abstract class SupplierOpeningsState {}

class SupplierOpeningsInitial extends SupplierOpeningsState {}

class SupplierOpeningsLoading extends SupplierOpeningsState {}

class SupplierOpeningsLoaded extends SupplierOpeningsState {
  final List<SupplierOpening> suppliers;
  final bool hasReachedMax;
  final Pagination pagination;

  SupplierOpeningsLoaded({
    required this.suppliers,
    required this.hasReachedMax,
    required this.pagination,
  });

  SupplierOpeningsLoaded copyWith({
    List<SupplierOpening>? suppliers,
    bool? hasReachedMax,
    Pagination? pagination,
  }) {
    return SupplierOpeningsLoaded(
      suppliers: suppliers ?? this.suppliers,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      pagination: pagination ?? this.pagination,
    );
  }
}

class SupplierOpeningsError extends SupplierOpeningsState {
  final String message;

  SupplierOpeningsError({required this.message});
}

class SupplierOpeningsPaginationError extends SupplierOpeningsState {
  final String message;

  SupplierOpeningsPaginationError({required this.message});
}

class Pagination {
  final int total;
  final int count;
  final int per_page;
  final int current_page;
  final int total_pages;

  Pagination({
    required this.total,
    required this.count,
    required this.per_page,
    required this.current_page,
    required this.total_pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int,
      count: json['count'] as int,
      per_page: json['per_page'] as int,
      current_page: json['current_page'] as int,
      total_pages: json['total_pages'] as int,
    );
  }
}
