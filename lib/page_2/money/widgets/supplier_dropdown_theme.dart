import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

CustomDropdownDecoration themedSupplierDropdownDecoration(
  AppThemeColors colors, {
  bool isInvalid = false,
}) {
  return CustomDropdownDecoration(
    closedFillColor: colors.surfaceElevated,
    expandedFillColor: colors.surfacePrimary,
    closedBorder: Border.all(
      color: isInvalid ? colors.error : colors.borderSubtle,
      width: isInvalid ? 1.5 : 1,
    ),
    closedBorderRadius: BorderRadius.circular(12),
    expandedBorder: Border.all(color: colors.borderSubtle, width: 1),
    expandedBorderRadius: BorderRadius.circular(12),
    headerStyle: TextStyle(
      color: colors.textPrimary,
      fontFamily: 'Gilroy',
      fontSize: 14,
    ),
    hintStyle: TextStyle(
      color: colors.textSecondary,
      fontFamily: 'Gilroy',
      fontSize: 14,
    ),
    listItemStyle: TextStyle(
      color: colors.textPrimary,
      fontFamily: 'Gilroy',
      fontSize: 14,
    ),
    listItemDecoration: ListItemDecoration(
      selectedColor: colors.surfaceElevated,
      highlightColor: colors.surfaceElevated.withValues(alpha: 0.72),
      splashColor: colors.overlay.withValues(alpha: 0),
    ),
    searchFieldDecoration: SearchFieldDecoration(
      autoFocus: false,
      fillColor: colors.surfaceElevated,
      hintStyle: TextStyle(
        color: colors.textSecondary,
        fontFamily: 'Gilroy',
        fontSize: 14,
      ),
      textStyle: TextStyle(
        color: colors.textPrimary,
        fontFamily: 'Gilroy',
        fontSize: 14,
      ),
      prefixIcon: Icon(
        Icons.search,
        size: 20,
        color: colors.iconSecondary,
      ),
      suffixIcon: (onClear) => IconButton(
        onPressed: onClear,
        icon: Icon(Icons.close, size: 18, color: colors.iconSecondary),
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
