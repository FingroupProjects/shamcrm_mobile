import 'package:crm_task_manager/models/page_2/category_model.dart';

abstract class CategoryState {}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryData> categories;
  
  CategoryLoaded(this.categories);
}

class CategoryEmpty extends CategoryState {}
class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}

class CategoryCreating extends CategoryState {}

class CategoryCreated extends CategoryState {
  final CategoryData newCategory;

  CategoryCreated(this.newCategory);
}

class CategoryCreateError extends CategoryState {
  final String message;

  CategoryCreateError(this.message);
}

class CategorySuccess extends CategoryState {
  final String message;
  
  CategorySuccess(this.message);
}