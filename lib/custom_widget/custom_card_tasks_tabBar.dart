import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

class TaskCardStyles {
  static BoxDecoration taskCardDecoration(BuildContext context) => BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.appColors.borderSubtle.withValues(alpha: 0.42),
        ),
        boxShadow: context.appShadows.card,
      );

  static TextStyle titleStyle(BuildContext context) =>
      context.appTextStyles.bodyLg.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: context.appColors.textPrimary,
        fontFamily: 'Gilroy',
      );

  static TextStyle priorityStyle(BuildContext context) =>
      context.appTextStyles.caption.copyWith(
        color: context.appColors.warning,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        fontFamily: 'Gilroy',
      );

  static BoxDecoration priorityContainerDecoration(BuildContext context) =>
      BoxDecoration(
        color: context.appColors.warning.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      );

  static BoxDecoration dropdownDecoration(BuildContext context) => BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.appColors.borderSubtle.withValues(alpha: 0.36),
        ),
      );

  // Стиль для ElevatedButton
  static ButtonStyle selectedButtonStyle(BuildContext context, bool isSelected) {
    return ElevatedButton.styleFrom(
      backgroundColor: isSelected
          ? context.appColors.buttonPrimaryBg
          : context.appColors.surfacePrimary.withValues(alpha: 0.72),
      foregroundColor: isSelected
          ? context.appColors.buttonPrimaryFg
          : context.appColors.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
