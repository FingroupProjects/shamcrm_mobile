import 'package:crm_task_manager/models/page_2/goods_model.dart';

abstract class GoodsByIdState {}

class GoodsByIdInitial extends GoodsByIdState {}

class GoodsByIdLoading extends GoodsByIdState {}

class GoodsByIdLoaded extends GoodsByIdState {
  final Goods goods;

  GoodsByIdLoaded(this.goods);
}

class GoodsByIdError extends GoodsByIdState {
  final String message;

  GoodsByIdError(this.message);
}

class GoodsByIdEmpty extends GoodsByIdState {}