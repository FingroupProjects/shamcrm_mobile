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

class SearchGoods extends GoodsEvent {
  final String query;

  SearchGoods(this.query);

  @override
  List<Object> get props => [query];
}

class FilterGoods extends GoodsEvent {
  final Map<String, dynamic> filters;

  FilterGoods(this.filters);

  @override
  List<Object> get props => [filters];
}

class FetchSubCategories extends GoodsEvent {}

class ResetSubCategories extends GoodsEvent {} // Новое событие для сброса подкатегорий

class CreateGoods extends GoodsEvent {
  final String name;
  final String description;
  final int unitId;
  final int quantity;
  final int parentId;
  final List<Map<String, dynamic>> attributes;
  final List<Map<String, dynamic>> variants;
  final List<File>? images;
  final bool isActive;
  final double? discountPrice;
  final int branch;

  CreateGoods({
    required this.name,
    required this.description,
    required this.unitId,
    required this.quantity,
    required this.parentId,
    required this.attributes,
    required this.variants,
    this.images,
    required this.isActive,
    this.discountPrice,
    required this.branch,
  });
}

class UpdateGoods extends GoodsEvent {
  final int goodId;
  final String name;
  final String description;
  final int unitId;
  final int quantity;
  final int parentId;
  final List<Map<String, dynamic>> attributes;
  final List<Map<String, dynamic>> variants;
  final List<File>? images;
  final bool isActive;
  final double? discountPrice;
  final int branch;

  UpdateGoods({
    required this.goodId,
    required this.name,
    required this.description,
    required this.unitId,
    required this.quantity,
    required this.parentId,
    required this.attributes,
    required this.variants,
    this.images,
    required this.isActive,
    this.discountPrice,
    required this.branch,
  });
}