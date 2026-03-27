import 'package:crm_task_manager/models/page_2/good_variants_model.dart';
import 'package:flutter/material.dart';

@immutable
sealed class GetAllGoodsListState {}

final class GetAllGoodsListInitial extends GetAllGoodsListState {}

final class GetAllGoodsListLoading extends GetAllGoodsListState {}

final class GetAllGoodsListError extends GetAllGoodsListState {
  final String message;

  GetAllGoodsListError({required this.message});
}

final class GetAllGoodsListSuccess extends GetAllGoodsListState {
  final List<GoodVariantItem> goodsList;
  final int currentPage;
  final int totalPages;

  GetAllGoodsListSuccess({
    required this.goodsList,
    required this.currentPage,
    required this.totalPages,
  });
}

