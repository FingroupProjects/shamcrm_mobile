import '../../../../models/page_2/openings/goods_openings_model.dart';

abstract class GoodsOpeningsState {}

class GoodsOpeningsInitial extends GoodsOpeningsState {}

class GoodsOpeningsLoading extends GoodsOpeningsState {}

class GoodsOpeningsLoaded extends GoodsOpeningsState {
  final List<GoodsOpeningDocument> goods;
  final bool hasReachedMax;
  final Pagination pagination;

  GoodsOpeningsLoaded({
    required this.goods,
    required this.hasReachedMax,
    required this.pagination,
  });

  GoodsOpeningsLoaded copyWith({
    List<GoodsOpeningDocument>? goods,
    bool? hasReachedMax,
    Pagination? pagination,
  }) {
    return GoodsOpeningsLoaded(
      goods: goods ?? this.goods,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      pagination: pagination ?? this.pagination,
    );
  }
}

class GoodsOpeningsError extends GoodsOpeningsState {
  final String message;

  GoodsOpeningsError({required this.message});
}

class GoodsOpeningsPaginationError extends GoodsOpeningsState {
  final String message;

  GoodsOpeningsPaginationError({required this.message});
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
