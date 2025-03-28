abstract class CategoryByIdEvent {}

class FetchCategoryByIdEvent extends CategoryByIdEvent {
  final int categoryId;
  FetchCategoryByIdEvent({required this.categoryId});
}
