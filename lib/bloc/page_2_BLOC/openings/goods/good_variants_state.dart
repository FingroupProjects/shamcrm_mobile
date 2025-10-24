import '../../../../models/page_2/good_variants_model.dart';

abstract class GoodVariantsState {}

class GoodVariantsInitial extends GoodVariantsState {}

class GoodVariantsLoading extends GoodVariantsState {}

class GoodVariantsLoaded extends GoodVariantsState {
  final List<GoodVariantItem> variants;
  final Pagination? pagination;
  final int currentPage;

  GoodVariantsLoaded({
    required this.variants,
    this.pagination,
    required this.currentPage,
  });

  GoodVariantsLoaded copyWith({
    List<GoodVariantItem>? variants,
    Pagination? pagination,
    int? currentPage,
  }) {
    return GoodVariantsLoaded(
      variants: variants ?? this.variants,
      pagination: pagination ?? this.pagination,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class GoodVariantsError extends GoodVariantsState {
  final String message;

  GoodVariantsError({required this.message});
}

