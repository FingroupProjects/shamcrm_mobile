import '../../../../models/page_2/good_variants_model.dart';

abstract class GoodsDialogState {}

class GoodsDialogInitial extends GoodsDialogState {}

class GoodsDialogLoading extends GoodsDialogState {}

class GoodsDialogLoaded extends GoodsDialogState {
  final List<GoodVariantItem> variants;

  GoodsDialogLoaded({required this.variants});
}

class GoodsDialogError extends GoodsDialogState {
  final String message;

  GoodsDialogError({required this.message});
}

