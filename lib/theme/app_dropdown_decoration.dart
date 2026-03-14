import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

CustomDropdownDecoration buildAppDropdownDecoration(
  BuildContext context, {
  Widget? prefixIcon,
  Widget? closedSuffixIcon,
  Widget? expandedSuffixIcon,
}) {
  final colors = context.appColors;
  final textTheme = Theme.of(context).textTheme;

  final closedBorder = Border.all(color: colors.borderPrimary);
  final expandedBorder = Border.all(color: colors.borderFocused, width: 1.3);

  return CustomDropdownDecoration(
    prefixIcon: prefixIcon,
    closedFillColor: colors.inputBackground,
    expandedFillColor: colors.surfaceElevated,
    closedBorder: closedBorder,
    expandedBorder: expandedBorder,
    closedErrorBorder: Border.all(color: colors.inputErrorBorder, width: 1.3),
    closedBorderRadius: BorderRadius.circular(12),
    expandedBorderRadius: BorderRadius.circular(12),
    closedErrorBorderRadius: BorderRadius.circular(12),
    closedShadow: <BoxShadow>[
      BoxShadow(
        color: colors.shadowColor.withValues(alpha: 0.2),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
    expandedShadow: <BoxShadow>[
      BoxShadow(
        color: colors.shadowColor.withValues(alpha: 0.28),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
    closedSuffixIcon: closedSuffixIcon ??
        Icon(Icons.keyboard_arrow_down_rounded, color: colors.iconSecondary),
    expandedSuffixIcon: expandedSuffixIcon ??
        Icon(Icons.keyboard_arrow_up_rounded, color: colors.iconBrand),
    hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
    headerStyle: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
    listItemStyle: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
    noResultFoundStyle:
        textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
    errorStyle: textTheme.bodySmall?.copyWith(
      color: colors.error,
      fontWeight: FontWeight.w600,
    ),
    searchFieldDecoration: SearchFieldDecoration(
      fillColor: colors.surfaceSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      textStyle: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
      hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
      prefixIcon: Icon(Icons.search_rounded, color: colors.iconSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.borderPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.borderFocused),
      ),
    ),
    listItemDecoration: ListItemDecoration(
      splashColor: colors.selectionBackground.withValues(alpha: 0.08),
      highlightColor: colors.surfaceInteractive,
      selectedColor: colors.surfaceInteractive,
      selectedIconColor: colors.iconBrand,
      selectedIconBorder: BorderSide(color: colors.borderFocused),
      selectedIconShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );
}
