import '../../../../models/page_2/good_variants_model.dart';

abstract class GoodsDialogEvent {}

class LoadGoodVariantsForDialog extends GoodsDialogEvent {
  final String? search;
  final int? categoryId;
  LoadGoodVariantsForDialog({this.search, this.categoryId});
}

class SearchGoodVariantsForDialog extends GoodsDialogEvent {
  final String? search;
  final int? categoryId;
  SearchGoodVariantsForDialog({this.search, this.categoryId});
}

class RefreshGoodVariantsForDialog extends GoodsDialogEvent {}

// Внутреннее событие для обновления данных в фоне
class UpdateGoodVariantsInBackground extends GoodsDialogEvent {
  final List<GoodVariantItem> data;
  final int totalPages;
  final int loadId;

  UpdateGoodVariantsInBackground(this.data, this.totalPages, this.loadId);
}
