import 'dart:io';

abstract class CategoryEvent {}

class FetchCategories extends CategoryEvent {}

class CreateCategory extends CategoryEvent {
  final String name;
  final int parentId;
  final List<Map<String, dynamic>> attributes;
  final File? image;
  final String displayType;
  final bool hasPriceCharacteristics;

  CreateCategory({
    required this.name,
    required this.parentId,
    required this.attributes,
    this.image,
    required this.displayType,
    required this.hasPriceCharacteristics,
  });

  @override
  List<Object?> get props => [name, parentId, attributes, image, displayType, hasPriceCharacteristics];
}

class UpdateCategory extends CategoryEvent {
  final int categoryId;
  final String name;
  final File? image;

  UpdateCategory({
    required this.categoryId,
    required this.name,
    this.image,
  });

  @override
  List<Object?> get props => [categoryId, name, image];
}

class UpdateSubCategory extends CategoryEvent {
  final int subCategoryId;
  final String name;
  final File? image;
  final List<Map<String, dynamic>> attributes;
  final String displayType;
  final bool hasPriceCharacteristics;

  UpdateSubCategory({
    required this.subCategoryId,
    required this.name,
    this.image,
    required this.attributes,
    required this.displayType,
    required this.hasPriceCharacteristics,
  });

  @override
  List<Object?> get props => [subCategoryId, name, image, attributes, displayType, hasPriceCharacteristics];
}

class DeleteCategory extends CategoryEvent {
  final int catgeoryId;

  DeleteCategory(this.catgeoryId);

  @override
  List<Object?> get props => [catgeoryId];
}