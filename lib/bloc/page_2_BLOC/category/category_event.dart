import 'dart:io';

abstract class CategoryEvent {}

class FetchCategories extends CategoryEvent {}

class CreateCategory extends CategoryEvent {
  final String name;
  final int parentId;
  final List<int> attributeIds;
  final File? image; // Изменяем тип на File

  CreateCategory({
    required this.name,
    required this.parentId,
    required this.attributeIds,
     this.image,
  });
  }
