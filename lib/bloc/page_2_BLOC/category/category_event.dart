import 'dart:io';

abstract class CategoryEvent {}

class FetchCategories extends CategoryEvent {}

class CreateCategory extends CategoryEvent {
  final String name;
  final int parentId;
  final List<String> attributeNames; // Теперь храним названия
  final File? image;

  CreateCategory({
    required this.name,
    required this.parentId,
    required this.attributeNames,
    this.image,
  });

  @override
  List<Object?> get props => [name, parentId, attributeNames, image];
}