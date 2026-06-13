// lib/styles/task_styles.dart

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

class TaskStyles {
  static Color activeColor(BuildContext context) =>
      context.appColors.textPrimary;
  static Color inactiveColor(BuildContext context) =>
      context.appColors.textSecondary;
  static Color borderActiveColor(BuildContext context) =>
      context.appColors.buttonPrimaryBg.withValues(alpha: 0.55);
  static Color borderInactiveColor(BuildContext context) =>
      context.appColors.borderSubtle.withValues(alpha: 0.32);

  static TextStyle tabTextStyle(BuildContext context) =>
      context.appTextStyles.bodySm.copyWith(
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
        fontSize: 14,
      );

  static BoxDecoration tabButtonDecoration(BuildContext context, bool isActive) {
    return BoxDecoration(
      color: isActive
          ? context.appColors.surfaceAccent.withValues(alpha: 0.24)
          : context.appColors.surfacePrimary.withValues(alpha: 0.74),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isActive
            ? borderActiveColor(context)
            : borderInactiveColor(context),
        width: 1,
      ),
      boxShadow: isActive ? context.appShadows.card : const [],
    );
  }
}
