import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';

abstract class GoodsState {}

class GoodsInitial extends GoodsState {}

class GoodsLoading extends GoodsState {}

class GoodsDataLoaded extends GoodsState {
  final List<Goods> goods;
  final Pagination pagination;
  final int currentPage;
  final List<SubCategoryAttributesData> subCategories;
  final List<SubCategoryAttributesData> selectedSubCategories; // Добавляем поле для выбранных подкатегорий

  GoodsDataLoaded(
    this.goods,
    this.pagination,
    this.subCategories, {
    this.currentPage = 1,
    this.selectedSubCategories = const [], // По умолчанию пустой список
  });

  GoodsDataLoaded merge(
    List<Goods> newGoods,
    Pagination newPagination,
    List<SubCategoryAttributesData> newSubCategories, [
    List<SubCategoryAttributesData>? newSelectedSubCategories, // Опционально для сохранения текущих
  ]) {
    return GoodsDataLoaded(
      [...goods, ...newGoods],
      newPagination,
      newSubCategories,
      selectedSubCategories: newSelectedSubCategories ?? selectedSubCategories,
      currentPage: currentPage + 1,
    );
  }
}

class GoodsError extends GoodsState {
  final String message;

  GoodsError(this.message);
}

class GoodsEmpty extends GoodsState {}

class GoodsSuccess extends GoodsState {
  final String message;

  GoodsSuccess(this.message);
}

// Модель Pagination (добавлена для полноты)
class Pagination {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  Pagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      count: json['count'] ?? 0,
      perPage: json['per_page'] ?? 20,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}