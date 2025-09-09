import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart'; // Для Pagination

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