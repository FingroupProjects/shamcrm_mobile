import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

void showCustomSnackBar({
  required BuildContext context,
  required String message,
  bool isSuccess = true,
}) {
  if (message.isEmpty) return;
  if (!context.mounted) return;

  final colors = context.appColors;
  final textTheme = Theme.of(context).textTheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        AppLocalizations.of(context)?.translate(message) ?? message,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.textInverse,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: isSuccess
          ? colors.snackSuccessBackground
          : colors.snackErrorBackground,
      elevation: 3,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      duration: const Duration(seconds: 3),
    ),
  );
}
