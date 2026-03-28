
import 'package:crm_task_manager/models/page_2/subCategoryById.dart';

abstract class CategoryByIdState {}

class CategoryByIdInitial extends CategoryByIdState {}

class CategoryByIdLoading extends CategoryByIdState {}

class CategoryByIdLoaded extends CategoryByIdState {
  final SubCategoryResponseASD category;
  CategoryByIdLoaded(this.category);
}

class CategoryByIdError extends CategoryByIdState {
  final String message;
  CategoryByIdError(this.message);
}
