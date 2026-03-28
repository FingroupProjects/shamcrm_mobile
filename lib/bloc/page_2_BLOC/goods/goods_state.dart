import 'package:crm_task_manager/models/batch_model.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';

abstract class GoodsState {}

class GoodsInitial extends GoodsState {}

class GoodsLoading extends GoodsState {}

class BatchLoaded extends GoodsState {
  final List<BatchData> batches;
  final Goods good;

  BatchLoaded(this.batches, this.good);
}

class GoodsDataLoaded extends GoodsState {
  final List<Goods> goods;
  final Pagination pagination;
  final List<SubCategoryAttributesData> subCategories;
  final List<SubCategoryAttributesData> selectedSubCategories;
  final List<String> selectedLabels;
  final int currentPage;

  GoodsDataLoaded(
    this.goods,
    this.pagination,
    this.subCategories, {
    this.selectedSubCategories = const [],
    this.selectedLabels = const [],
    this.currentPage = 1,
  });

  GoodsDataLoaded merge(
    List<Goods> newGoods,
    Pagination newPagination,
    List<SubCategoryAttributesData> newSubCategories,
    List<SubCategoryAttributesData> newSelectedSubCategories,
    List<String> newSelectedLabels,
  ) {
    // Фильтруем только уникальные товары по id
    final uniqueGoods = [...goods, ...newGoods].fold<List<Goods>>(
      [],
      (uniqueList, item) {
        if (!uniqueList.any((existing) => existing.id == item.id)) {
          uniqueList.add(item);
        }
        return uniqueList;
      },
    );

    return GoodsDataLoaded(
      uniqueGoods,
      newPagination,
      newSubCategories,
      selectedSubCategories: newSelectedSubCategories,
      selectedLabels: newSelectedLabels,
      currentPage: newPagination.currentPage,
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

// В goods_state.dart
class GoodsBarcodeSearchResult extends GoodsState {
  final List<Goods> goods;
  final String? error;

  GoodsBarcodeSearchResult({required this.goods, this.error});

  bool get isSingle => goods.length == 1;
  bool get isMultiple => goods.length > 1;
  bool get isEmpty => goods.isEmpty;
}