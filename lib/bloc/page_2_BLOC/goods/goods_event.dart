import 'dart:io';

abstract class GoodsEvent {}

class FetchGoods extends GoodsEvent {
  final int page;
  FetchGoods({this.page = 1});
}

class FetchMoreGoods extends GoodsEvent {
  final int currentPage;

  FetchMoreGoods(this.currentPage);
}

class CreateGoods extends GoodsEvent {
  final String name;
  final String description;
  final int quantity;
  final int parentId;
  final List<String> attributeNames;
  final List<File>? images;
  final bool isActive;
  final double? discountPrice;

  CreateGoods({
    required this.name,
    required this.description,
    required this.quantity,
    required this.parentId,
    required this.attributeNames,
    this.images,
    required this.isActive,
    this.discountPrice,
  });
}

class UpdateGoods extends GoodsEvent {
  final int goodId;
  final String name;
  final String description;
  final int quantity;
  final int parentId;
  final List<String> attributeNames;
  final List<File>? images;
  final bool isActive;
  final double? discountPrice;

  UpdateGoods({
    required this.goodId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.parentId,
    required this.attributeNames,
    this.images,
    required this.isActive,
    this.discountPrice,
  });
}