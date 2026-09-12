import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Единый стиль полей создания/редактирования:
/// радиус 12, одна тонкая рамка, без двойных границ.
class AppFieldStyle {
  static const double radiusValue = 12;

  static BorderRadius get radius => BorderRadius.circular(radiusValue);

  static Color borderColor(BuildContext context, {bool hasError = false}) {
    final colors = context.appColors;
    return hasError ? colors.error : colors.borderSubtle;
  }

  static BorderSide side(
    BuildContext context, {
    bool hasError = false,
    bool focused = false,
  }) {
    final colors = context.appColors;
    if (hasError) {
      return BorderSide(color: colors.error, width: 1.5);
    }
    if (focused) {
      return BorderSide(
        color: colors.buttonPrimaryBg.withValues(alpha: 0.6),
        width: 1.2,
      );
    }
    return BorderSide(color: colors.borderSubtle, width: 1);
  }

  static OutlineInputBorder outline(
    BuildContext context, {
    bool hasError = false,
    bool focused = false,
  }) {
    return OutlineInputBorder(
      borderRadius: radius,
      borderSide: side(context, hasError: hasError, focused: focused),
    );
  }

  /// Одна рамка для закрытого дропдауна.
  static Border dropdownBorder(BuildContext context, {bool hasError = false}) {
    return Border.all(
      color: borderColor(context, hasError: hasError),
      width: hasError ? 1.5 : 1,
    );
  }

  /// Если снаружи уже есть Container с рамкой — внутреннюю не рисуем.
  static Border get dropdownClosedTransparent =>
      Border.all(color: Colors.transparent, width: 1);

  static TextStyle errorTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: 'Gilroy',
      color: context.appColors.error,
    );
  }

  /// Overlay, search field and list use theme colors (no white sheet in dark mode).
  static CustomDropdownDecoration dropdownDecoration(
    BuildContext context, {
    bool hasError = false,
  }) {
    final colors = context.appColors;
    return CustomDropdownDecoration(
      closedFillColor: colors.fieldBg,
      expandedFillColor: colors.surfacePrimary,
      closedBorder: dropdownBorder(context, hasError: hasError),
      closedErrorBorder: dropdownBorder(context, hasError: true),
      closedBorderRadius: radius,
      closedErrorBorderRadius: radius,
      expandedBorder: dropdownBorder(context),
      expandedBorderRadius: radius,
      errorStyle: errorTextStyle(context),
      headerStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
      ).copyWith(color: colors.textPrimary),
      hintStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
      ).copyWith(color: colors.textSecondary),
      listItemStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
      ).copyWith(color: colors.textPrimary),
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
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Gilroy',
          color: colors.textPrimary,
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Gilroy',
          color: colors.textSecondary,
        ),
        prefixIcon: Icon(Icons.search, color: colors.iconSecondary),
        suffixIcon: (onClear) => IconButton(
          onPressed: onClear,
          icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
        ),
        border: outline(context),
        focusedBorder: outline(context, focused: true),
      ),
    );
  }
}
