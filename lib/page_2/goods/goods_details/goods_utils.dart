import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:flutter/material.dart';

void validateForm({
  required GlobalKey<FormState> formKey,
  required SubCategoryAttributesData? selectedCategory,
  required Branch? selectedBranch,
  required bool isImagesValid,
  required Function(bool) onCategoryValid,
  required Function(bool) onImagesValid,
  required Function(bool) onBranchValid,
}) {
  onCategoryValid(selectedCategory != null);
  onImagesValid(isImagesValid);
  onBranchValid(selectedBranch != null);
}