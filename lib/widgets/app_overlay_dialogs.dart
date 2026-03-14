import 'package:crm_task_manager/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  IconData icon = Icons.warning_amber_rounded,
  bool isDestructive = false,
}) {
  final colors = context.appColors;
  final textTheme = Theme.of(context).textTheme;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? colors.surfaceDangerSubtle
                    : colors.surfaceWarningSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? colors.error : colors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              cancelLabel,
              style: textTheme.labelLarge?.copyWith(
                color: colors.buttonTertiaryForeground,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? colors.buttonDangerBackground
                  : colors.buttonPrimaryBackground,
              foregroundColor: isDestructive
                  ? colors.buttonDangerForeground
                  : colors.buttonPrimaryForeground,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}

Future<void> showAppLoadingDialog(BuildContext context) {
  final colors = context.appColors;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: colors.scrim,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.dialogBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowColor.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
