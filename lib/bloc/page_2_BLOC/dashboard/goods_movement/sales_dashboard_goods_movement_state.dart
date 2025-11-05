import '../../../../models/page_2/good_variants_model.dart';

abstract class SalesDashboardGoodsMovementState {}

class SalesDashboardGoodsMovementInitial extends SalesDashboardGoodsMovementState {}

class SalesDashboardGoodsMovementLoading extends SalesDashboardGoodsMovementState {}

class SalesDashboardGoodsMovementLoaded extends SalesDashboardGoodsMovementState {
  final List<GoodVariantItem> variants;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final bool hasReachedMax;

  SalesDashboardGoodsMovementLoaded({
    required this.variants,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
  });
}

class SalesDashboardGoodsMovementError extends SalesDashboardGoodsMovementState {
  final String message;

  SalesDashboardGoodsMovementError({required this.message});
}

class SalesDashboardGoodsMovementPaginationError extends SalesDashboardGoodsMovementState {
  final String message;
  final List<GoodVariantItem> variants;
  final int currentPage;
  final int totalPages;
  final bool hasReachedMax;

  SalesDashboardGoodsMovementPaginationError({
    required this.message,
    required this.variants,
    required this.currentPage,
    required this.totalPages,
    required this.hasReachedMax,
  });
}

