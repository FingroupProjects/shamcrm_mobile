import '../../../../models/page_2/good_variants_model.dart';

abstract class GoodsDialogState {}

class GoodsDialogInitial extends GoodsDialogState {}

class GoodsDialogLoading extends GoodsDialogState {}

class GoodsDialogLoaded extends GoodsDialogState {
  final List<GoodVariantItem> variants;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  GoodsDialogLoaded({
    required this.variants,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
  });
}

class GoodsDialogError extends GoodsDialogState {
  final String message;

  GoodsDialogError({required this.message});
}
