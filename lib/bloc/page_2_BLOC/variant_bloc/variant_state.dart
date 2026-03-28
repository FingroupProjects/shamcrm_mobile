import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';

abstract class VariantState {}

class VariantInitial extends VariantState {}

class VariantLoading extends VariantState {}

class VariantDataLoaded extends VariantState {
  final List<Variant> variants;
  final Pagination pagination;
  final int currentPage;

  VariantDataLoaded(
    this.variants,
    this.pagination, {
    this.currentPage = 1,
  });

  VariantDataLoaded merge(
    List<Variant> newVariants,
    Pagination newPagination,
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

    return VariantDataLoaded(
      uniqueVariants,
      newPagination,
      currentPage: newPagination.currentPage,
    );
  }
}

class VariantError extends VariantState {
  final String message;
  VariantError(this.message);
}

class VariantEmpty extends VariantState {}

// Новые состояния для работы с категориями
class CategoriesLoading extends VariantState {}

class CategoriesLoaded extends VariantState {
  final List<CategoryWithCount> categories;

  CategoriesLoaded(this.categories);
}

class CategoriesError extends VariantState {
  final String message;
  CategoriesError(this.message);
}

class CategoryVariantsLoading extends VariantState {
  final int categoryId;
  CategoryVariantsLoading(this.categoryId);
}

class CategoryVariantsLoaded extends VariantState {
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