import 'package:crm_task_manager/models/income_categories_data_response.dart';
import 'package:flutter/material.dart';

import '../../models/outcome_categories_data_response.dart';

@immutable
sealed class GetAllOutcomeCategoryState {}

final class GetAllOutcomeCategoryInitial extends GetAllOutcomeCategoryState {}

final class GetAllOutcomeCategoryLoading extends GetAllOutcomeCategoryState {}

final class GetAllOutcomeCategoryError extends GetAllOutcomeCategoryState {
  final String message;

  GetAllOutcomeCategoryError({required this.message});
}

final class GetAllOutcomeCategorySuccess extends GetAllOutcomeCategoryState {
  final OutcomeCategoriesDataResponse dataOutcomeCategories;

  GetAllOutcomeCategorySuccess({required this.dataOutcomeCategories});
}
