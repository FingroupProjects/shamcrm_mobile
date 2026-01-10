import 'package:crm_task_manager/models/income_categories_data_response.dart';
import 'package:flutter/material.dart';

@immutable
sealed class GetAllIncomeCategoryState {}

final class GetAllIncomeCategoryInitial extends GetAllIncomeCategoryState {}

final class GetAllIncomeCategoryLoading extends GetAllIncomeCategoryState {}

final class GetAllIncomeCategoryError extends GetAllIncomeCategoryState {
  final String message;

  GetAllIncomeCategoryError({required this.message});
}

final class GetAllIncomeCategorySuccess extends GetAllIncomeCategoryState {
  final IncomeCategoriesDataResponse dataIncomeCategories;

  GetAllIncomeCategorySuccess({required this.dataIncomeCategories});
}
