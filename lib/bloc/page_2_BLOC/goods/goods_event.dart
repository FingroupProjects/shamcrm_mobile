import 'dart:io';

abstract class GoodsEvent {}

class FetchGoods extends GoodsEvent {}

class CreateGoods extends GoodsEvent {
  final String name;
  final String description;
  final int quantity;
  final int parentId;
  final List<String> attributeNames;
  final List<File>? images; // Изменено на List<File>?
  final bool isActive;

  CreateGoods({
    required this.name,
    required this.description,
    required this.quantity,
    required this.parentId,
    required this.attributeNames,
    this.images, // Изменено на List<File>?
    required this.isActive,
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

  UpdateGoods({
    required this.goodId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.parentId,
    required this.attributeNames,
    this.images,
    required this.isActive,
  });
}