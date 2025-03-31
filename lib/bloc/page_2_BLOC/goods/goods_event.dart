import 'dart:io';

abstract class GoodsEvent {}

class FetchGoods extends GoodsEvent {}

class CreateGoods extends GoodsEvent {
  final String name;
  final String description;
  final int quantity;
  final int parentId;
  final List<String> attributeNames; 
  final File? image;
  final bool isActive;

  CreateGoods({
    required this.name,
    required this.description,
    required this.quantity,
    required this.parentId,
    required this.attributeNames,
    this.image,
    required this.isActive,
  });
}
