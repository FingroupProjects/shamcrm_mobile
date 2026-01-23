import '../../../../models/page_2/good_variants_model.dart';

abstract class GoodsDialogEvent {}

class LoadGoodVariantsForDialog extends GoodsDialogEvent {
  final String? search;
  LoadGoodVariantsForDialog({this.search});
}

class SearchGoodVariantsForDialog extends GoodsDialogEvent {
  final String? search;
  SearchGoodVariantsForDialog({this.search});
}

class RefreshGoodVariantsForDialog extends GoodsDialogEvent {}

// Внутреннее событие для обновления данных в фоне
class UpdateGoodVariantsInBackground extends GoodsDialogEvent {
  final List<GoodVariantItem> data;
  final int totalPages;
  
  UpdateGoodVariantsInBackground(this.data, this.totalPages);
}
