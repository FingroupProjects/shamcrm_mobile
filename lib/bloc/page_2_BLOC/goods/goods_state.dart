import 'package:crm_task_manager/models/page_2/goods_model.dart';

abstract class GoodsState {}

class GoodsInitial extends GoodsState {}

class GoodsLoading extends GoodsState {}

class GoodsDataLoaded extends GoodsState {
  final List<Goods> goods;
  final int currentPage;

  GoodsDataLoaded(this.goods, {this.currentPage = 1});
}

class GoodsError extends GoodsState {
  final String message;

  GoodsError(this.message);
}

class GoodsEmpty extends GoodsState {} 

class GoodsSuccess extends GoodsState {
  final String message;
  
  GoodsSuccess(this.message);
}
