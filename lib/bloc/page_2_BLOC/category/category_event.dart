import 'dart:io';

abstract class CategoryEvent {}

class FetchCategories extends CategoryEvent {}

class CreateCategory extends CategoryEvent {
  final String name;
  final int parentId;
  final List<String> attributeNames;
  final File? image;
  final String displayType; // Новое поле для типа отображения
  final bool hasPriceCharacteristics; // Новое поле для влияния на цену

  CreateCategory({
    required this.name,
    required this.parentId,
    required this.attributeNames,
    this.image,
    required this.displayType,
    required this.hasPriceCharacteristics,
  });

  @override
  List<Object?> get props => [
        name,
        parentId,
        attributeNames,
        image,
        displayType,
        hasPriceCharacteristics
      ];
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
}
class UpdateSubCategory extends CategoryEvent {
  final int subCategoryId;
  final String name;
  final File? image;
  final List<String> attributeNames; 


  UpdateSubCategory({
    required this.subCategoryId,
    required this.name,
    this.image,
    required this.attributeNames,
  });
}

class DeleteCategory extends CategoryEvent {
  final int catgeoryId;

  DeleteCategory(this.catgeoryId);
}
