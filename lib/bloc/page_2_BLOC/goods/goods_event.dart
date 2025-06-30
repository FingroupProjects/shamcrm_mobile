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
  final int? branch;
  final int? mainImageIndex;
  final bool isNew; // Added
  final bool isPopular; // Added
  final bool isSale; // Added

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
    this.mainImageIndex,
    required this.isNew,
    required this.isPopular,
    required this.isSale,
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
  final int? branch;
  final String? comments; // Добавляем поле comments
  final int? mainImageIndex; // Добавляем поле mainImageIndex
  final bool isNew; // Added
  final bool isPopular; // Added
  final bool isSale; // Added

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
    this.comments,
    this.mainImageIndex,
    required this.isNew, // Added
    required this.isPopular, // Added
    required this.isSale, // Added
  });
}