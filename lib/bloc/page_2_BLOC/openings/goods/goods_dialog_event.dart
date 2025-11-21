import '../../../../models/page_2/good_variants_model.dart';

abstract class GoodsDialogEvent {}

class LoadGoodVariantsForDialog extends GoodsDialogEvent {}

class RefreshGoodVariantsForDialog extends GoodsDialogEvent {}

// Внутреннее событие для обновления данных в фоне
class UpdateGoodVariantsInBackground extends GoodsDialogEvent {
  final List<GoodVariantItem> data;
  final int totalPages;
  
  UpdateGoodVariantsInBackground(this.data, this.totalPages);
}
