import '../../../../models/page_2/openings/goods_openings_model.dart';
import '../../../../models/page_2/good_variants_model.dart' as good_variants;

abstract class GoodsOpeningsState {}

class GoodsOpeningsInitial extends GoodsOpeningsState {}

class GoodsOpeningsLoading extends GoodsOpeningsState {}

class GoodsOpeningsLoaded extends GoodsOpeningsState {
  final List<GoodsOpeningDocument> goods;

  GoodsOpeningsLoaded({
    required this.goods,
  });

  GoodsOpeningsLoaded copyWith({
    List<GoodsOpeningDocument>? goods,
  }) {
    return GoodsOpeningsLoaded(
      goods: goods ?? this.goods,
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

// Состояние для ошибок операций (создание, редактирование, удаление)
// Не влияет на отображение контента, используется только для snackbar
class GoodsOpeningsOperationError extends GoodsOpeningsState {
  final String message;
  final GoodsOpeningsState previousState;

  GoodsOpeningsOperationError({
    required this.message,
    required this.previousState,
  });
}

// Состояние загрузки для операции создания
class GoodsOpeningCreating extends GoodsOpeningsState {}

// Состояние успешного создания
class GoodsOpeningCreateSuccess extends GoodsOpeningsState {}

// Состояние ошибки создания
class GoodsOpeningCreateError extends GoodsOpeningsState {
  final String message;

  GoodsOpeningCreateError({required this.message});
}

// Состояние загрузки для операции обновления
class GoodsOpeningUpdating extends GoodsOpeningsState {}

class GoodsOpeningUpdateSuccess extends GoodsOpeningsState {}

// Deprecated: используйте GoodsOpeningsOperationError
class GoodsOpeningUpdateError extends GoodsOpeningsState {
  final String message;

  GoodsOpeningUpdateError({required this.message});
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
