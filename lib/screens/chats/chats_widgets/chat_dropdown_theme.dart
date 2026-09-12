import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

CustomDropdownDecoration chatUserDropdownDecoration(
  BuildContext context, {
  required bool hasError,
}) {
  final colors = context.appColors;
  final textStyles = context.appTextStyles;
  return CustomDropdownDecoration(
    closedFillColor: colors.fieldBg,
    expandedFillColor: colors.surfacePrimary,
    closedBorder: Border.all(
      color: hasError ? colors.error : colors.borderSubtle,
      width: hasError ? 1.5 : 1,
    ),
    closedBorderRadius: BorderRadius.circular(12),
    expandedBorder: Border.all(
      color: hasError ? colors.error : colors.borderSubtle,
      width: hasError ? 1.5 : 1,
    ),
    expandedBorderRadius: BorderRadius.circular(12),
    hintStyle: textStyles.bodyLg.copyWith(color: colors.textSecondary),
    headerStyle: textStyles.bodyLg.copyWith(color: colors.textPrimary),
    listItemStyle: textStyles.bodyLg.copyWith(color: colors.textPrimary),
    closedSuffixIcon: Icon(
      Icons.keyboard_arrow_down_rounded,
      color: colors.iconSecondary,
    ),
    expandedSuffixIcon: Icon(
      Icons.keyboard_arrow_up_rounded,
      color: colors.iconSecondary,
    ),
    listItemDecoration: ListItemDecoration(
      selectedColor: colors.buttonPrimaryBg.withValues(alpha: 0.14),
      highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
      splashColor: Colors.transparent,
    ),
    searchFieldDecoration: SearchFieldDecoration(
      fillColor: colors.surfaceElevated,
      textStyle: textStyles.bodyMd.copyWith(color: colors.textPrimary),
      hintStyle: textStyles.bodyMd.copyWith(color: colors.textSecondary),
      prefixIcon: Icon(Icons.search, color: colors.iconSecondary),
      suffixIcon: (onClear) => IconButton(
        onPressed: onClear,
        icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.buttonPrimaryBg),
      ),
    ),
  );
}
