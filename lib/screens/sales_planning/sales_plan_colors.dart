import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:flutter/material.dart';

/// Fixed readable accents for Sales Planning (independent of brand cyan/purple).
class SalesPlanColors {
  /// App navy used on Event FAB / primary actions.
  static const Color actionNavy = Color(0xFF1E2E52);

  /// Orange — active / behind plan (readable on dark).
  static const Color orange = Color(0xFFF59E0B);

  /// Green — on track / done.
  static const Color green = Color(0xFF34D399);

  /// Red — overdue / critical.
  static const Color red = Color(0xFFFB7185);

  static Color status(BuildContext context, SalesPlanStatus status) {
    switch (status) {
      case SalesPlanStatus.active:
        return orange;
      case SalesPlanStatus.completed:
      case SalesPlanStatus.overachieved:
        return green;
      case SalesPlanStatus.overdue:
        return red;
    }
  }

  static Color progress(
    BuildContext context, {
    required double percent,
    required SalesPlanStatus status,
  }) {
    if (status == SalesPlanStatus.overdue) return red;
    if (status == SalesPlanStatus.overachieved || percent >= 100) return green;
    if (percent < 50) return orange;
    if (percent < 80) return orange;
    return green;
  }

  static Color forecast(BuildContext context, SalesPlan plan) {
    if (plan.status == SalesPlanStatus.overdue) return red;
    if (plan.status == SalesPlanStatus.overachieved) return green;
    final fp = plan.forecastPercent ?? plan.percent;
    if (fp >= 100) return green;
    if (fp < 50) return red;
    return orange;
  }

  static Color selection(BuildContext context) => green;

  static Color selectionBg(BuildContext context) =>
      green.withValues(alpha: 0.12);

  static Color mutedText(BuildContext context) =>
      context.appColors.textSecondary;

  static Color strongText(BuildContext context) =>
      context.appColors.textPrimary;
}
