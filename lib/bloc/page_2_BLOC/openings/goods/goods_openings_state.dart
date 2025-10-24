import '../../../../models/page_2/openings/goods_openings_model.dart';
import '../../../../models/page_2/good_variants_model.dart' as good_variants;

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

// States for good variants
class GoodsOpeningsGoodVariantsInitial extends GoodsOpeningsState {}

class GoodsOpeningsGoodVariantsLoading extends GoodsOpeningsState {}

class GoodsOpeningsGoodVariantsLoaded extends GoodsOpeningsState {
  final List<good_variants.GoodVariantItem> variants;
  final good_variants.Pagination? pagination;
  final int currentPage;

  GoodsOpeningsGoodVariantsLoaded({
    required this.variants,
    this.pagination,
    required this.currentPage,
  });

  GoodsOpeningsGoodVariantsLoaded copyWith({
    List<good_variants.GoodVariantItem>? variants,
    good_variants.Pagination? pagination,
    int? currentPage,
  }) {
    return GoodsOpeningsGoodVariantsLoaded(
      variants: variants ?? this.variants,
      pagination: pagination ?? this.pagination,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class GoodsOpeningsGoodVariantsError extends GoodsOpeningsState {
  final String message;

  GoodsOpeningsGoodVariantsError({required this.message});
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
