import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';

abstract class VariantBottomSheetState {}

class AllVariantLoading extends VariantBottomSheetState {}

class AllVariantLoaded extends VariantBottomSheetState {
  final List<Variant> variants;
  final Pagination pagination;
  final int currentPage;

  AllVariantLoaded(
    this.variants,
    this.pagination, {
    this.currentPage = 1,
  });
}

class AllVariantError extends VariantBottomSheetState {
  final String message;
  AllVariantError(this.message);
}

// Новые состояния для работы с категориями
class CategoriesLoading extends VariantBottomSheetState {}

class CategoriesLoaded extends VariantBottomSheetState {
  final List<CategoryWithCount> categories;

  CategoriesLoaded(this.categories);
}

class CategoriesError extends VariantBottomSheetState {
  final String message;
  CategoriesError(this.message);
}

class CategoryVariantsLoading extends VariantBottomSheetState {
  final int categoryId;
  CategoryVariantsLoading(this.categoryId);
}

class CategoryVariantsLoaded extends VariantBottomSheetState {
  final int categoryId;
  final List<Variant> variants;
  final VariantPagination pagination;
  final int currentPage;

  CategoryVariantsLoaded({
    required this.categoryId,
    required this.variants,
    required this.pagination,
    this.currentPage = 1,
  });

  CategoryVariantsLoaded merge(
    List<Variant> newVariants,
    VariantPagination newPagination,
  ) {
    final uniqueVariants = [...variants, ...newVariants].fold<List<Variant>>(
      [],
      (uniqueList, item) {
        if (!uniqueList.any((existing) => existing.id == item.id)) {
          uniqueList.add(item);
        }
        return uniqueList;
      },
    );

    return CategoryVariantsLoaded(
      categoryId: categoryId,
      variants: uniqueVariants,
      pagination: newPagination,
      currentPage: newPagination.currentPage,
    );
  }
}

class CategoryVariantsError extends VariantBottomSheetState {
  final String message;
  CategoryVariantsError(this.message);
}